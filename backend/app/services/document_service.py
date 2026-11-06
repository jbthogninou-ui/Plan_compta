import os
import uuid

from fastapi import UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core.exceptions import ValidationAppError
from app.models.document import Document
from app.models.user import User

settings = get_settings()


async def save_document(
    db: AsyncSession, file: UploadFile, user: User, transaction_id: uuid.UUID | None
) -> Document:
    content = await file.read()
    size_mb = len(content) / (1024 * 1024)
    if size_mb > settings.MAX_UPLOAD_SIZE_MB:
        raise ValidationAppError(
            f"Fichier trop volumineux ({size_mb:.1f} Mo, max {settings.MAX_UPLOAD_SIZE_MB} Mo)."
        )

    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    stored_name = f"{uuid.uuid4()}_{file.filename}"
    path = os.path.join(settings.UPLOAD_DIR, stored_name)
    with open(path, "wb") as f:
        f.write(content)

    document = Document(
        company_id=user.company_id,
        transaction_id=transaction_id,
        filename=file.filename,
        storage_path=path,
        mime_type=file.content_type or "application/octet-stream",
        size_bytes=len(content),
        uploaded_by=user.id,
    )
    db.add(document)
    await db.commit()
    await db.refresh(document)
    return document
