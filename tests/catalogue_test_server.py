"""Ephemeral loopback API for the Godot integration test; never uses production accounts."""
import argparse
import asyncio
import json
import socket
import subprocess
import sys
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta
from io import BytesIO
from pathlib import Path
from uuid import uuid4
from zipfile import ZipFile

parser = argparse.ArgumentParser()
parser.add_argument("--api-project", required=True)
parser.add_argument("--workspace", required=True)
args = parser.parse_args()
sys.path.insert(0, args.api_project)

import uvicorn
from fastapi import FastAPI, UploadFile
from fastapi.responses import RedirectResponse, Response
from imageio_ffmpeg import get_ffmpeg_exe
from PIL import Image
from tortoise import Tortoise
from dansuapi.api import dependencies
from dansuapi.api.router import api_router
from dansuapi.api.routes.resources import router as resource_router
from dansuapi.core.config import Settings
from dansuapi.core.db import build_tortoise_config
from dansuapi.core.tokens import create_access_token
from dansuapi.models.chart import Chart, ChartSet
from dansuapi.models.user import User
from dansuapi.services.chart_packages import ChartPackageService, get_chart_package_service
from dansuapi.services.leaderboards import (
    get_chart_leaderboard_service,
    get_leaderboard_service,
)

workspace = Path(args.workspace)
storage = workspace / "test-server-storage"
settings = Settings(storage_root=str(storage), jwt_secret="isolated-catalogue-test-key-32-bytes-minimum")
dependencies.get_settings = lambda: settings
service = ChartPackageService(settings)
fixture = workspace / "test-fixture"
fixture.mkdir(exist_ok=True)
subprocess.run([get_ffmpeg_exe(), "-y", "-f", "lavfi", "-i", "sine=frequency=440:duration=2", "-q:a", "9", str(fixture / "audio.mp3")], check=True, capture_output=True)
Image.new("RGB", (256, 256), "#705bde").save(fixture / "cover.png")

def make_charts(set_uuid, title):
    for index, difficulty in enumerate(("Easy", "Hard")):
        text = f"""FILE_VERSION_1
@METADATA
uuid: {uuid4()}
chartset_uuid: {set_uuid}
title: {title}
artist: Test Artist
creator: Test Creator
difficulty: {difficulty}
file_audio: audio.mp3
file_cover_art: cover.png
preview_time: 0
version: 1
@TIMINGS
0,120
@ENDMETA
@OBJECT
rail:1
[0,0,0]
[1000,0,0]
0,1,0
1000,4,0
end
"""
        (fixture / f"{index}.dansu").write_text(text, encoding="utf-8")


async def create_dummy_chartset(user, title, published_at):
    set_uuid = uuid4()
    chartset = await ChartSet.create(
        owner=user,
        chartset_uuid=set_uuid,
        published_at=published_at,
    )
    await Chart.create(
        chartset=chartset,
        chart_uuid=uuid4(),
        title=title,
        artist="Test Artist",
        creator_display="Test Creator",
        difficulty_name="Normal",
        relative_chart_path="chart.dansu",
        relative_audio_path="audio.mp3",
        relative_cover_art_path="cover.png",
        checksum_sha256="0" * 64,
        min_bpm=120,
        max_bpm=120,
        rating=5,
        play_time_ms=60_000,
    )
    return chartset

sock = socket.socket()
sock.bind(("127.0.0.1", 0))
port = sock.getsockname()[1]

@asynccontextmanager
async def lifespan(app):
    context = await Tortoise.init(config=build_tortoise_config("sqlite://:memory:"), _enable_global_fallback=True)
    await Tortoise.generate_schemas()
    user = await User.create(steam_id="test", steam_persona_name="Integration test", username="test", username_slug="test")
    now = datetime.now(UTC)
    for index in range(24):
        await create_dummy_chartset(user, f"Pagination test song {index + 1}", now - timedelta(minutes=index + 1))
    online_uuid = uuid4()
    make_charts(online_uuid, "Online test song")
    archive = BytesIO()
    with ZipFile(archive, "w") as output:
        for path in fixture.iterdir():
            output.write(path, path.name)
    archive.seek(0)
    await service.publish(UploadFile(file=archive, filename="fixture.zip"), user)
    local_uuid = uuid4()
    make_charts(local_uuid, "Upload test song")
    (workspace / "test-server.json").write_text(json.dumps({"origin": f"http://127.0.0.1:{port}", "token": create_access_token(user.id, settings), "user_id": user.id, "online_uuid": str(online_uuid), "local_uuid": str(local_uuid)}))
    yield
    await context.close_connections()
    context.__exit__(None, None, None)

app = FastAPI(lifespan=lifespan)
app.include_router(api_router, prefix="/api/v1")
app.include_router(resource_router)
app.dependency_overrides[get_chart_package_service] = lambda: service
app.dependency_overrides[get_leaderboard_service] = lambda: object()
app.dependency_overrides[get_chart_leaderboard_service] = lambda: object()

@app.post("/__test/lock/{uuid}")
async def lock(uuid: str):
    await ChartSet.filter(chartset_uuid=uuid).update(status="approved")
    return {"ok": True}


@app.post("/__test/insert-chartset")
async def insert_chartset():
    user = await User.first()
    chartset = await create_dummy_chartset(user, "Inserted between pages", datetime.now(UTC) + timedelta(minutes=1))
    return {"id": chartset.id, "uuid": str(chartset.chartset_uuid)}

@app.get("/__test/redirect")
async def redirect():
    return RedirectResponse("https://storage.invalid/package?signature=test", status_code=302)


@app.get("/__test/avatar.jpg")
async def avatar():
    output = BytesIO()
    Image.new("RGB", (64, 64), "#705bde").save(output, format="JPEG")
    return Response(output.getvalue(), media_type="image/jpeg")

uvicorn.Server(uvicorn.Config(app, log_level="warning")).run(sockets=[sock])
