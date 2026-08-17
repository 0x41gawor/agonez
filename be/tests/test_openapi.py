from pathlib import Path

from agonez_api.app import create_app
from agonez_api.core.config import Settings


def test_openapi_exposes_the_frontend_contract(tmp_path: Path) -> None:
    settings = Settings(
        NOME="atlas_user",
        AGANDSKODE="secret",
        MINA=33327,
        MEDIA_ROOT=tmp_path,
    )
    app = create_app(settings=settings)
    paths = app.openapi()["paths"]

    assert "/api/atlas/exercises" in paths
    assert "/api/atlas/exercises/{slug}" in paths
    assert "/api/atlas/exercises/{slug}/videos" in paths
    assert "post" in paths["/api/atlas/exercises/{slug}/videos"]
    assert "/api/atlas/muscles" in paths
    assert "/api/atlas/muscles/{slug}" in paths
    assert "/api/atlas/muscles/{slug}/exercises" in paths
    assert "/api/atlas/meta" in paths
    assert "/assets/anatomy.svg" in paths
    assert "post" in paths["/api/plans"]
    assert "get" in paths["/api/plans"]
    assert "get" in paths["/api/plans/{plan_id}"]
    assert "delete" in paths["/api/plans/{plan_id}"]
    assert "get" in paths["/api/plans/{plan_id}/draft"]
    assert "put" in paths["/api/plans/{plan_id}/draft"]

    list_parameters = {
        parameter["name"] for parameter in paths["/api/atlas/exercises"]["get"]["parameters"]
    }
    assert {
        "q",
        "body_part",
        "target_category",
        "mechanics_tier",
        "resistance_source",
        "sort",
        "order",
        "page",
        "per_page",
    } <= list_parameters
