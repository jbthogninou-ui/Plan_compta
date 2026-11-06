"""NOTE: ce test nécessite un vrai backend PostgreSQL accessible (voir
DATABASE_URL) car il instancie l'application FastAPI complète. À exécuter
via `docker compose up -d` puis `pytest tests/test_health.py`."""
import pytest
from httpx import ASGITransport, AsyncClient


@pytest.mark.asyncio
async def test_health_check():
    from app.main import app
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
