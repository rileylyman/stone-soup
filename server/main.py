import time
import uuid

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response

app = FastAPI()

IMAGE_TTL_SECONDS = 300  # 5 minutes


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
        {"id": s.id, "time_remaining_pct": round(max(0.0, (s.expires_at - now) / IMAGE_TTL_SECONDS * 100), 2)}
        for s in _images.values()
    ]


@app.get("/images/{image_id}")
def get_image(image_id: str) -> Response:
    _purge_expired()
    stored = _images.get(image_id)
    if stored is None:
        raise HTTPException(status_code=404, detail="Image not found or expired")
    return Response(content=stored.png_bytes, media_type="image/png")
