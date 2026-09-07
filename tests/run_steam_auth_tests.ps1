param([Parameter(Mandatory=$true)][string]$GodotPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('dansu-auth-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
@'
config_version=5
[autoload]
Config="*res://config.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
'@ | Set-Content -LiteralPath (Join-Path $testRoot 'project.godot')
@'
extends Node
var server_api_url = "http://127.0.0.1:1/api/v1"
'@ | Set-Content -LiteralPath (Join-Path $testRoot 'config.gd')
New-Item -ItemType Directory -Path (Join-Path $testRoot 'global') | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'global/steam_auth.gd') -Destination (Join-Path $testRoot 'global')
New-Item -ItemType Directory -Path (Join-Path $testRoot 'network') | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'network/server_urls.gd') -Destination (Join-Path $testRoot 'network')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'test_steam_auth.gd') -Destination $testRoot
& $GodotPath --headless --path $testRoot --log-file (Join-Path $testRoot 'test.log') --script (Join-Path $testRoot 'test_steam_auth.gd')
if ($LASTEXITCODE -ne 0) { throw "Steam auth checks failed. See $testRoot/test.log" }
Write-Output "Test log: $testRoot/test.log"
