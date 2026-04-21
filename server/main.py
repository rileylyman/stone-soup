import time
import uuid

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

IMAGE_TTL_SECONDS = 300  # 5 minutes


class GodotImage(BaseModel):
    data: list[int]  # PackedByteArray serializes to array of ints in JSON
    format: str
    height: int
    mipmaps: bool
    width: int


class StoredImage:
    def __init__(self, image: GodotImage) -> None:
        self.id = str(uuid.uuid4())
        self.image = image
        self.created_at = time.monotonic()
        self.expires_at = self.created_at + IMAGE_TTL_SECONDS


_images: dict[str, StoredImage] = {}


def _purge_expired() -> None:
    now = time.monotonic()
    expired = [k for k, v in _images.items() if v.expires_at <= now]
    for k in expired:
        del _images[k]


@app.post("/images", status_code=201)
def post_image(image: GodotImage) -> dict[str, str]:
    print(image)
    _purge_expired()
    stored = StoredImage(image)
    _images[stored.id] = stored
    return {"id": stored.id}


@app.get("/images")
def get_images() -> list[dict[str, object]]:
    _purge_expired()
    now = time.monotonic()
    result: list[dict[str, object]] = []
    for stored in _images.values():
        remaining = stored.expires_at - now
        pct_remaining = round(max(0.0, remaining / IMAGE_TTL_SECONDS * 100), 2)
        result.append({
            "id": stored.id,
            "data": stored.image.data,
            "format": stored.image.format,
            "height": stored.image.height,
            "mipmaps": stored.image.mipmaps,
            "width": stored.image.width,
            "time_remaining_pct": pct_remaining,
        })
    return result


@app.get("/images/{image_id}")
def get_image(image_id: str) -> dict[str, object]:
    _purge_expired()
    stored = _images.get(image_id)
    if stored is None:
        raise HTTPException(status_code=404, detail="Image not found or expired")
    now = time.monotonic()
    remaining = stored.expires_at - now
    pct_remaining = round(max(0.0, remaining / IMAGE_TTL_SECONDS * 100), 2)
    return {
        "id": stored.id,
        "data": stored.image.data,
        "format": stored.image.format,
        "height": stored.image.height,
        "mipmaps": stored.image.mipmaps,
        "width": stored.image.width,
        "time_remaining_pct": pct_remaining,
    }
