param(
    [Parameter(Mandatory=$true)][string]$GodotPath,
    [Parameter(Mandatory=$true)][string]$PythonPath,
    [string]$ApiProjectPath = 'D:\Project\DansuAPI',
    [string]$ScreenshotPath = ''
)
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
$runId = [guid]::NewGuid().ToString('N')
$testRoot = Join-Path $env:TEMP ('dansu-catalogue-' + $runId)
New-Item -ItemType Directory -Path $testRoot | Out-Null
robocopy $sourceRoot $testRoot /E /XD .git .godot .vscode import addons /XF *.pdb /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw 'Could not copy the test project.' }
foreach ($addon in @('dansusql', 'rawinput')) {
    $target = Join-Path $testRoot ('addons\' + $addon)
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item (Join-Path $sourceRoot ('addons\' + $addon + '\*')) $target
}
$project = Get-Content (Join-Path $testRoot 'project.godot') -Raw
$project = $project.Replace('config/name="dansu"', ('config/name="dansu-test-' + $runId + '"'))
$project = $project.Replace('Auth="*res://global/steam_auth.gd"', 'Auth="*res://tests/offline_auth.gd"')
$project = $project.Replace('Scores="*res://global/score_manager.gd"', 'Scores="*res://tests/test_score_manager.gd"')
$project = $project.Replace('Transition="*uid://bw12vr28vpm78"', 'Transition="*res://tests/test_transition.gd"')
Set-Content (Join-Path $testRoot 'project.godot') $project
# Keep the test window small when rendering a screenshot; production config is unchanged.
$config = Get-Content (Join-Path $testRoot 'global/config.gd') -Raw
$config = $config.Replace('config.load(FILE_PATH)', 'config.load(FILE_PATH)' + "`n`tconfig.set_value(SECTION_GRAPHICS, `"window_mode`", DisplayServer.WINDOW_MODE_WINDOWED)`n`tconfig.set_value(SECTION_GRAPHICS, `"window_size`", Vector2i(1280, 720))")
Set-Content (Join-Path $testRoot 'global/config.gd') $config
$server = Start-Process -FilePath $PythonPath -ArgumentList @((Join-Path $PSScriptRoot 'catalogue_test_server.py'), '--api-project', $ApiProjectPath, '--workspace', $testRoot) -WindowStyle Hidden -PassThru -RedirectStandardError (Join-Path $testRoot 'server.log')
try {
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    while (-not (Test-Path (Join-Path $testRoot 'test-server.json'))) {
        if ($server.HasExited -or [DateTime]::UtcNow -gt $deadline) { throw "Test server did not start. See $testRoot/server.log" }
        Start-Sleep -Milliseconds 100
    }
    $importLog = Join-Path $testRoot 'import.log'
    $import = Start-Process -FilePath $GodotPath -ArgumentList @('--headless','--editor','--path',$testRoot,'--import','--quit','--log-file',$importLog) -WindowStyle Hidden -PassThru
    if (-not $import.WaitForExit(60000)) { $import.Kill(); throw 'Godot import timed out.' }
    $testLog = Join-Path $testRoot 'tests.log'
    $arguments = @('--path',$testRoot,'res://tests/catalogue_test.tscn','--log-file',$testLog)
    if ($ScreenshotPath -eq '') { $arguments += '--headless' }
    else { $arguments += @('--rendering-method','gl_compatibility'); $env:DANSU_TEST_SCREENSHOT = $ScreenshotPath }
    $test = Start-Process -FilePath $GodotPath -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $test.WaitForExit(60000)) { $test.Kill(); throw "Godot test timed out. See $testLog" }
    $output = Get-Content $testLog -Raw
    if ($test.ExitCode -ne 0 -or $output -match 'SCRIPT ERROR|ERROR:|Parse Error' -or $output -notmatch 'Catalogue integration: \d+ checks, 0 failures') {
        Get-Content $testLog -Tail 100
        throw "Catalogue checks failed. See $testLog"
    }
    $output | Select-String 'Catalogue integration:.*'
    Write-Output "Test log: $testLog"
} finally {
    if (-not $server.HasExited) { $server.Kill() }
    Remove-Item Env:DANSU_TEST_SCREENSHOT -ErrorAction SilentlyContinue
}
