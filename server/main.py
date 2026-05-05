import time
import uuid
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import FileResponse, RedirectResponse, Response

app = FastAPI()

IMAGE_TTL_SECONDS = 60 * 60 * 8


class StoredImage:
    def __init__(self, png_bytes: bytes) -> None:
        self.id = str(uuid.uuid4())
        self.png_bytes = png_bytes
        self.created_at = time.monotonic()
        self.expires_at = self.created_at + IMAGE_TTL_SECONDS


_images: dict[str, StoredImage] = {}


def _purge_expired() -> None:
    now = time.monotonic()
    expired = [k for k, v in _images.items() if v.expires_at <= now]
    for k in expired:
        del _images[k]


@app.post("/images", status_code=201)
async def post_image(request: Request) -> dict[str, str]:
    _purge_expired()
    png_bytes = await request.body()
    stored = StoredImage(png_bytes)
    _images[stored.id] = stored
    return {"id": stored.id}


@app.get("/images")
def get_images() -> list[dict[str, object]]:
    _purge_expired()
    now = time.monotonic()
    return [
        {
            "id": s.id,
            "time_remaining_s": round(max(0.0, (s.expires_at - now)), 2),
        }
        for s in _images.values()
    ]


_GAME_BUILD_DIR = Path(__file__).parent / "game-build"
_GAME_HEADERS = {
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Embedder-Policy": "require-corp",
    "Cache-Control": "no-store",
}


@app.get("/game")
def get_game() -> RedirectResponse:
    return RedirectResponse(url="/game/", status_code=301)


@app.get("/game/")
def get_game_index() -> FileResponse:
    return FileResponse(_GAME_BUILD_DIR / "stone-soup.html", headers=_GAME_HEADERS)


@app.get("/game/{filename:path}")
def get_game_file(filename: str) -> FileResponse:
    target = (_GAME_BUILD_DIR / filename).resolve()
    if not str(target).startswith(str(_GAME_BUILD_DIR.resolve())):
        raise HTTPException(status_code=403, detail="Forbidden")
    if not target.is_file():
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(target, headers=_GAME_HEADERS)


@app.get("/images/{image_id}")
def get_image(image_id: str) -> Response:
    _purge_expired()
    stored = _images.get(image_id)
    if stored is None:
        raise HTTPException(status_code=404, detail="Image not found or expired")
    return Response(content=stored.png_bytes, media_type="image/png")
