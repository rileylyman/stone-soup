import time
import uuid
from pathlib import Path
import io

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import FileResponse, RedirectResponse, Response
from PIL import Image

app = FastAPI()

IMAGE_TTL_SECONDS = 60 * 60 * 8
MAX_BYTES = 10_000
MAX_IMAGES = 500

palette = [
    [0, 0, 0],
    [255, 255, 255],
    [190, 38, 51],
    [224, 111, 139],
    [73, 60, 43],
    [164, 100, 34],
    [235, 137, 49],
    [247, 226, 107],
    [68, 137, 26],
    [163, 206, 39],
    [49, 162, 242],
]

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

    if len(_images) > MAX_IMAGES:
        raise HTTPException(400)

    png_bytes = await request.body()
    if len(png_bytes) > MAX_BYTES:
        raise HTTPException(400)

    PNG_MAGIC = b"\x89PNG\r\n\x1a\n"
    if not png_bytes.startswith(PNG_MAGIC):
        raise HTTPException(400)

    try:
        img = Image.open(io.BytesIO(png_bytes))
    except Exception:
        raise HTTPException(400)

    if len(img.info) != 1 or "srgb" not in img.info:
        raise HTTPException(400)

    if img.size[0] != 64 or img.size[1] != 64:
        raise HTTPException(400)

    rgb = img.convert("RGB")
    for d in rgb.get_flattened_data():
        found = False
        for c in palette:
            if type(d) is float:
                break
            if d[0] == c[0] and d[1] == c[1] and d[2] == c[2]:  # type: ignore
                found = True
                break
        if not found:
            raise HTTPException(400)

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


_DOODLE_DIR = Path(__file__).parent / "game/doodle"
_SOUP_DIR = Path(__file__).parent / "game/soup"
_GAME_HEADERS = {
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Embedder-Policy": "require-corp",
    "Cache-Control": "no-store",
}


@app.get("/")
def get_root() -> RedirectResponse:
    return RedirectResponse(url="/soup/", status_code=301)


@app.get("/soup")
def get_soup() -> RedirectResponse:
    return RedirectResponse(url="/soup/", status_code=301)


@app.get("/doodle")
def get_doodle() -> RedirectResponse:
    return RedirectResponse(url="/doodle/", status_code=301)


@app.get("/soup/")
def get_soup_index() -> FileResponse:
    return FileResponse(_SOUP_DIR / "index.html", headers=_GAME_HEADERS)


@app.get("/doodle/")
def get_doodle_index() -> FileResponse:
    return FileResponse(_DOODLE_DIR / "index.html", headers=_GAME_HEADERS)


@app.get("/soup/{filename:path}")
def get_soup_file(filename: str) -> FileResponse:
    target = (_SOUP_DIR / filename).resolve()
    if not str(target).startswith(str(_SOUP_DIR.resolve())):
        raise HTTPException(status_code=403, detail="Forbidden")
    if not target.is_file():
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(target, headers=_GAME_HEADERS)


@app.get("/doodle/{filename:path}")
def get_doodle_file(filename: str) -> FileResponse:
    target = (_DOODLE_DIR / filename).resolve()
    if not str(target).startswith(str(_DOODLE_DIR.resolve())):
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
