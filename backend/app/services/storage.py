"""Pluggable media storage.

`local`  -> files on disk, served by the API at /media (simplest for Raspberry Pi).
`minio`  -> S3-compatible object storage (scales to VPS/cloud with no app changes).

Switching backends is a single env var (STORAGE_BACKEND) — the rest of the app
only ever calls `storage.save_image(...)`, `storage.delete(...)`, `storage.public_url(...)`.
"""
from __future__ import annotations

import io
import uuid
from abc import ABC, abstractmethod
from pathlib import Path

from PIL import Image, UnidentifiedImageError

from app.core.config import settings
from app.core.logging import logger

MAX_DIMENSION = 1600
JPEG_QUALITY = 85


class UploadError(Exception):
    pass


def process_image(raw: bytes) -> bytes:
    """Validate + normalise an uploaded image.

    Re-encoding through Pillow guarantees the bytes are a real image (not a
    disguised payload), strips EXIF/metadata, and caps the dimensions.
    """
    max_bytes = settings.max_upload_mb * 1024 * 1024
    if len(raw) > max_bytes:
        raise UploadError(f"الصورة أكبر من الحد المسموح ({settings.max_upload_mb}MB)")
    try:
        img = Image.open(io.BytesIO(raw))
        img.verify()  # detect truncated/corrupt files
        img = Image.open(io.BytesIO(raw))  # reopen after verify()
        img = img.convert("RGB")
    except (UnidentifiedImageError, OSError) as exc:
        raise UploadError("ملف الصورة غير صالح") from exc

    img.thumbnail((MAX_DIMENSION, MAX_DIMENSION))
    out = io.BytesIO()
    img.save(out, format="JPEG", quality=JPEG_QUALITY, optimize=True)
    return out.getvalue()


class Storage(ABC):
    @abstractmethod
    def save_image(self, raw: bytes, folder: str = "listings") -> str:
        """Store an image and return its storage key."""

    @abstractmethod
    def delete(self, key: str) -> None:
        ...

    def public_url(self, key: str) -> str:
        return f"{settings.public_base_url.rstrip('/')}/media/{key}"


class LocalStorage(Storage):
    def __init__(self) -> None:
        self.root = Path(settings.upload_dir)
        self.root.mkdir(parents=True, exist_ok=True)

    def save_image(self, raw: bytes, folder: str = "listings") -> str:
        data = process_image(raw)
        key = f"{folder}/{uuid.uuid4().hex}.jpg"
        path = self.root / key
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        return key

    def delete(self, key: str) -> None:
        try:
            (self.root / key).unlink(missing_ok=True)
        except OSError as exc:  # pragma: no cover
            logger.warning("failed to delete %s: %s", key, exc)


class MinioStorage(Storage):
    def __init__(self) -> None:
        import boto3

        scheme = "https" if settings.minio_secure else "http"
        self._client = boto3.client(
            "s3",
            endpoint_url=f"{scheme}://{settings.minio_endpoint}",
            aws_access_key_id=settings.minio_access_key,
            aws_secret_access_key=settings.minio_secret_key,
        )
        self._bucket = settings.minio_bucket
        self._ensure_bucket()

    def _ensure_bucket(self) -> None:
        from botocore.exceptions import ClientError

        try:
            self._client.head_bucket(Bucket=self._bucket)
        except ClientError:
            self._client.create_bucket(Bucket=self._bucket)
            logger.info("created MinIO bucket %s", self._bucket)

    def save_image(self, raw: bytes, folder: str = "listings") -> str:
        data = process_image(raw)
        key = f"{folder}/{uuid.uuid4().hex}.jpg"
        self._client.put_object(
            Bucket=self._bucket, Key=key, Body=data, ContentType="image/jpeg"
        )
        return key

    def delete(self, key: str) -> None:
        from botocore.exceptions import ClientError

        try:
            self._client.delete_object(Bucket=self._bucket, Key=key)
        except ClientError as exc:  # pragma: no cover
            logger.warning("failed to delete %s: %s", key, exc)

    def public_url(self, key: str) -> str:
        # Served through the reverse proxy under /media (see nginx.conf).
        return f"{settings.public_base_url.rstrip('/')}/media/{key}"


def _build_storage() -> Storage:
    if settings.storage_backend.lower() == "minio":
        return MinioStorage()
    return LocalStorage()


storage: Storage = _build_storage()
