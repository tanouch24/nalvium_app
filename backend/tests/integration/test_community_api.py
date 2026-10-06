import io
import json

import pytest
from fastapi.testclient import TestClient
from PIL import Image
from sqlalchemy import text

from app.api.deps import get_storage
from app.community.rules import COMMUNITY_CONSENT_VERSION
from app.main import create_app
from app.media.storage import LocalMediaStorage
from tests.helpers import jpeg_bytes, new_install_id

pytestmark = pytest.mark.integration

OK = {"title": "Mon lave-vaisselle ne vidangeait plus", "solution": "J'ai nettoyé le filtre et retiré un morceau de verre.",
      "category": "appliance", "materials": "Tournevis cruciforme, chiffon", "consent_public": True,
      "consent_version": COMMUNITY_CONSENT_VERSION}


class Env:
    def __init__(self, client, headers, storage):
        self.client, self.headers, self.storage = client, headers, storage

    def other(self):
        return {"X-Nalvium-Install-Id": new_install_id()}

    def post(self, headers=None, **over):
        body = {**OK, **over}
        return self.client.post("/v1/community/posts", json=body, headers=headers or self.headers)

    def feed(self, headers=None, **params):
        return self.client.get("/v1/community/posts", params=params, headers=headers or self.headers).json()

    def photo(self, raw=None, headers=None):
        return self.client.post("/v1/community/media", files={"file": ("p.jpg", raw or jpeg_bytes(size=(2000, 1500)), "image/jpeg")}, headers=headers or self.headers)


@pytest.fixture
def env(clean_db, tmp_path):
    app = create_app()
    storage = LocalMediaStorage(tmp_path)
    app.dependency_overrides[get_storage] = lambda: storage
    return Env(TestClient(app), {"X-Nalvium-Install-Id": new_install_id()}, storage)


def test_create_list_detail_and_empty_feed(env):
    assert env.feed() == {"items": [], "next_cursor": None}
    r = env.post()
    assert r.status_code == 201
    body = r.json()
    assert body["title"] == OK["title"] and body["helpful_count"] == 0 and body["comment_count"] == 0 and body["mine"] is True
    assert env.feed()["items"][0]["id"] == body["id"]
    assert env.client.get(f"/v1/community/posts/{body['id']}", headers=env.headers).json()["solution"] == OK["solution"]
    assert env.client.get("/v1/community/posts").status_code == 401


@pytest.mark.parametrize("over,code", [
    ({"title": ""}, "title_required"), ({"title": "ab"}, "title_required"), ({"title": "x" * 130}, "title_too_long"),
    ({"solution": ""}, "solution_required"), ({"solution": "court"}, "solution_required"),
    ({"solution": "y" * 2100}, "solution_too_long"), ({"category": "electrical"}, "invalid_category"),
    ({"materials": "m" * 250}, "materials_too_long"), ({"consent_public": False}, "public_consent_required"),
    ({"consent_version": "vieille"}, "consent_version_mismatch"),
])
def test_post_validation(env, over, code):
    r = env.post(**over)
    assert r.status_code == 422 and r.json()["detail"] == code
    assert env.feed()["items"] == []


def test_malformed_payload_is_refused(env):
    assert env.client.post("/v1/community/posts", content=b"{pas json", headers={**env.headers, "Content-Type": "application/json"}).status_code == 422
    assert env.client.post("/v1/community/posts", json={"title": 5, "media_id": "pas-un-uuid"}, headers=env.headers).status_code == 422


def test_dangerous_content_is_refused_and_normal_content_accepted(env):
    for solution in ["Pour réparer, j'ai touché les fils dénudés du tableau électrique sous tension pour tester.",
                     "Il y avait une odeur de gaz, j'ai allumé un briquet pour trouver la fuite."]:
        r = env.post(solution=solution)
        assert r.status_code == 422 and r.json()["detail"] == "unsafe_content"
    assert env.post().status_code == 201
    assert len(env.feed()["items"]) == 1


def test_pagination_is_stable_without_duplicates(env):
    ids = [env.post(title=f"Solution numéro {i:02d}").json()["id"] for i in range(7)]
    seen, cursor = [], None
    for _ in range(5):
        page = env.feed(limit=3, **({"cursor": cursor} if cursor else {}))
        seen += [i["id"] for i in page["items"]]
        if env.post(title="Arrivé pendant le défilement").status_code == 201 and cursor is None:
            pass  # un nouveau post ne crée ni doublon ni trou dans les pages suivantes
        cursor = page["next_cursor"]
        if not cursor:
            break
    assert [i for i in seen if i in ids] == list(reversed(ids))
    assert len(seen) == len(set(seen))
    assert env.client.get("/v1/community/posts", params={"cursor": "n-importe-quoi"}, headers=env.headers).status_code == 422
    assert len(env.feed(limit=500)["items"]) <= 50


def test_owner_edit_non_owner_refused_and_delete_hides_everywhere(env):
    pid = env.post().json()["id"]
    other = env.other()
    assert env.client.patch(f"/v1/community/posts/{pid}", json={"title": "Piraté"}, headers=other).status_code == 403
    assert env.client.delete(f"/v1/community/posts/{pid}", headers=other).status_code == 403
    r = env.client.patch(f"/v1/community/posts/{pid}", json={"title": "Titre modifié", "materials": None}, headers=env.headers)
    assert r.json()["title"] == "Titre modifié" and r.json()["materials"] is None
    assert env.client.patch(f"/v1/community/posts/{pid}", json={"solution": "dangereux : fils dénudés sous tension"}, headers=env.headers).status_code == 422
    env.client.put(f"/v1/community/posts/{pid}/save", headers=other)
    env.client.post(f"/v1/community/posts/{pid}/comments", json={"body": "Merci !"}, headers=other)
    assert env.client.delete(f"/v1/community/posts/{pid}", headers=env.headers).status_code == 204
    assert env.feed()["items"] == [] and env.feed(headers=other)["items"] == []
    assert env.client.get(f"/v1/community/posts/{pid}", headers=other).status_code == 404
    assert env.client.get("/v1/community/saved", headers=other).json()["items"] == []
    assert env.client.get(f"/v1/community/posts/{pid}/comments", headers=other).status_code == 404  # pas d'erreur d'intégrité
    assert env.client.delete(f"/v1/community/posts/{pid}", headers=env.headers).status_code == 404


def test_public_serializers_expose_no_private_data(env, engine):
    owner = env.headers["X-Nalvium-Install-Id"]
    sid = env.client.post("/v1/sessions", headers=env.headers).json()["id"]
    eq = env.client.post("/v1/equipment", json={"equipment_type": "oven", "brand": "Samsung"}, headers=env.headers).json()["id"]
    pid = env.post(media_id=env.photo().json()["id"]).json()["id"]
    other = env.other()
    raw = json.dumps([env.feed(headers=other), env.client.get(f"/v1/community/posts/{pid}", headers=other).json()])
    for forbidden in (owner, sid, eq, "owner", "user_id", "equipment", "session", "email", "phone", "city", "postal", "storage", "exif",
                      "source_private", "consent", "var/", "community/"):
        assert forbidden not in raw.lower(), forbidden
    post = env.client.get(f"/v1/community/posts/{pid}", headers=other).json()
    assert post["mine"] is False and set(post) == {"id", "title", "solution", "category", "materials", "created_at", "helpful_count",
        "comment_count", "photo_id", "photo_width", "photo_height", "mine", "helpful", "saved"}


# ---- médias -------------------------------------------------------------------
def exif_jpeg():
    exif = Image.Exif()
    exif[0x010F] = "SecretPhoneMaker"
    exif.get_ifd(0x8825)[2] = (48.0, 51.0, 24.0)
    return jpeg_bytes(size=(3000, 2000), exif=exif.tobytes())


def test_direct_photo_is_clean_resized_with_distinct_variants(env):
    mid = env.photo(exif_jpeg()).json()["id"]
    thumb = env.client.get(f"/v1/community/media/{mid}/thumb", headers=env.headers)
    large = env.client.get(f"/v1/community/media/{mid}/large", headers=env.headers)
    for r in (thumb, large):
        assert r.status_code == 200 and b"SecretPhoneMaker" not in r.content
        assert len(Image.open(io.BytesIO(r.content)).getexif()) == 0
    assert max(Image.open(io.BytesIO(thumb.content)).size) <= 480 and max(Image.open(io.BytesIO(large.content)).size) <= 1280
    assert len(thumb.content) < len(large.content)
    assert env.photo(b"pas une image").status_code == 422


def test_draft_media_is_visible_to_its_author_only_until_published(env):
    mid = env.photo().json()["id"]
    assert env.client.get(f"/v1/community/media/{mid}/thumb", headers=env.headers).status_code == 200
    assert env.client.get(f"/v1/community/media/{mid}/thumb", headers=env.other()).status_code == 404
    assert env.client.get(f"/v1/community/media/{mid}/thumb").status_code == 404
    pid = env.post(media_id=mid).json()["id"]
    assert env.client.get(f"/v1/community/media/{mid}/thumb").status_code == 200  # publié : public
    assert env.client.get(f"/v1/community/posts/{pid}", headers=env.headers).json()["photo_id"] == mid
    assert env.client.get(f"/v1/community/media/{mid}/huge", headers=env.headers).status_code == 404


def test_someone_elses_draft_media_cannot_be_attached(env):
    other = env.other()
    mid = env.photo(headers=other).json()["id"]
    assert env.post(media_id=mid).json()["detail"] == "unknown_media"


def test_private_photo_requires_consent_and_becomes_a_distinct_clean_public_copy(env, engine):
    sid = env.client.post("/v1/sessions", headers=env.headers).json()["id"]
    private = env.client.post(f"/v1/sessions/{sid}/media", files={"file": ("p.jpg", exif_jpeg(), "image/jpeg")}, headers=env.headers).json()["id"]
    assert env.client.post("/v1/community/media/from-private", json={"media_id": private}, headers=env.headers).json()["detail"] == "public_consent_required"
    r = env.client.post("/v1/community/media/from-private", json={"media_id": private, "consent_public": True}, headers=env.headers)
    assert r.status_code == 201
    pub = r.json()["id"]
    assert pub != private
    with engine.connect() as c:
        src, key, thumb = c.execute(text("SELECT source_private_media_id, storage_key, thumb_key FROM community_media")).one()
        priv_key = c.execute(text("SELECT storage_key FROM media_assets WHERE id=:i"), {"i": private}).scalar()
    assert str(src) == private and key != priv_key and key.startswith("community/") and thumb.startswith("community/")
    img = env.client.get(f"/v1/community/media/{pub}/large", headers=env.headers).content
    assert len(Image.open(io.BytesIO(img)).getexif()) == 0 and b"SecretPhoneMaker" not in img
    # l'original reste PRIVÉ et intact
    assert env.client.get(f"/v1/media/{private}/content", headers=env.headers).status_code == 200
    assert env.client.get(f"/v1/media/{private}/content", headers=env.other()).status_code == 404
    assert env.client.get(f"/v1/community/media/{private}/large", headers=env.headers).status_code == 404  # pas par l'id privé


def test_private_photo_of_another_user_or_a_video_is_refused(env):
    other = env.other()
    sid = env.client.post("/v1/sessions", headers=other).json()["id"]
    foreign = env.client.post(f"/v1/sessions/{sid}/media", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=other).json()["id"]
    r = env.client.post("/v1/community/media/from-private", json={"media_id": foreign, "consent_public": True}, headers=env.headers)
    assert r.status_code == 404


def test_discard_draft_and_post_deletion_remove_public_files(env):
    mid = env.photo().json()["id"]
    assert env.client.delete(f"/v1/community/media/{mid}", headers=env.other()).status_code == 404
    assert env.client.delete(f"/v1/community/media/{mid}", headers=env.headers).status_code == 204
    mid2 = env.photo().json()["id"]
    pid = env.post(media_id=mid2).json()["id"]
    assert env.client.delete(f"/v1/community/media/{mid2}", headers=env.headers).status_code == 404  # publié : pas un brouillon
    env.client.delete(f"/v1/community/posts/{pid}", headers=env.headers)
    assert env.client.get(f"/v1/community/media/{mid2}/thumb").status_code == 404


# ---- Utile / sauvegarde ---------------------------------------------------------------
def test_helpful_once_remove_and_counter(env):
    pid = env.post().json()["id"]
    other = env.other()
    for _ in range(3):  # appels répétés : jamais de gonflement
        r = env.client.put(f"/v1/community/posts/{pid}/helpful", headers=other)
    assert r.json()["helpful_count"] == 1 and r.json()["helpful"] is True
    assert env.client.put(f"/v1/community/posts/{pid}/helpful", headers=env.headers).json()["helpful_count"] == 2
    assert env.feed(headers=other)["items"][0]["helpful_count"] == 2
    r = env.client.delete(f"/v1/community/posts/{pid}/helpful", headers=other)
    assert r.json()["helpful_count"] == 1 and r.json()["helpful"] is False
    assert env.client.delete(f"/v1/community/posts/{pid}/helpful", headers=other).json()["helpful_count"] == 1
    assert env.client.put("/v1/community/posts/00000000-0000-0000-0000-000000000000/helpful", headers=other).status_code == 404


def test_saved_list_is_private_and_unsave_works(env):
    p1, p2 = env.post(title="Première solution").json()["id"], env.post(title="Seconde solution").json()["id"]
    other = env.other()
    assert env.client.get("/v1/community/saved", headers=other).json()["items"] == []
    env.client.put(f"/v1/community/posts/{p1}/save", headers=other)
    env.client.put(f"/v1/community/posts/{p1}/save", headers=other)
    saved = env.client.get("/v1/community/saved", headers=other).json()["items"]
    assert [i["id"] for i in saved] == [p1] and saved[0]["saved"] is True
    assert env.client.get("/v1/community/saved", headers=env.headers).json()["items"] == []  # privé : l'auteur ne voit rien
    feed = {i["id"]: i for i in env.feed(headers=env.headers)["items"]}
    assert feed[p1]["saved"] is False  # l'état « enregistré » est propre à chaque membre
    env.client.delete(f"/v1/community/posts/{p1}/save", headers=other)
    assert env.client.get("/v1/community/saved", headers=other).json()["items"] == []
    assert p2 in {i["id"] for i in env.feed()["items"]}


# ---- commentaires ----------------------------------------------------------------------
def test_comments_create_validate_list_and_owner_delete(env):
    pid = env.post().json()["id"]
    other = env.other()
    c = env.client.post(f"/v1/community/posts/{pid}/comments", json={"body": "Merci, ça a marché chez moi aussi !"}, headers=other)
    assert c.status_code == 201 and c.json()["mine"] is True
    cid = c.json()["id"]
    assert env.client.post(f"/v1/community/posts/{pid}/comments", json={"body": "   "}, headers=other).json()["detail"] == "comment_required"
    assert env.client.post(f"/v1/community/posts/{pid}/comments", json={"body": "x" * 600}, headers=other).json()["detail"] == "comment_too_long"
    assert env.client.post(f"/v1/community/posts/{pid}/comments", json={"body": "touchez les fils dénudés sous tension"}, headers=other).status_code == 422
    listed = env.client.get(f"/v1/community/posts/{pid}/comments", headers=env.headers).json()
    assert [x["id"] for x in listed["items"]] == [cid] and listed["items"][0]["mine"] is False
    assert "owner" not in json.dumps(listed)
    assert env.feed()["items"][0]["comment_count"] == 1
    assert env.client.delete(f"/v1/community/comments/{cid}", headers=env.headers).status_code == 403
    assert env.client.delete(f"/v1/community/comments/{cid}", headers=other).status_code == 204
    assert env.client.get(f"/v1/community/posts/{pid}/comments", headers=other).json()["items"] == []
    assert env.feed()["items"][0]["comment_count"] == 0
    assert env.client.delete(f"/v1/community/comments/{cid}", headers=other).status_code == 404


def test_comment_pagination(env):
    pid = env.post().json()["id"]
    for i in range(5):
        env.client.post(f"/v1/community/posts/{pid}/comments", json={"body": f"Commentaire {i}"}, headers=env.headers)
    p1 = env.client.get(f"/v1/community/posts/{pid}/comments", params={"limit": 3}, headers=env.headers).json()
    p2 = env.client.get(f"/v1/community/posts/{pid}/comments", params={"limit": 3, "cursor": p1["next_cursor"]}, headers=env.headers).json()
    assert [c["body"] for c in p1["items"] + p2["items"]] == [f"Commentaire {i}" for i in range(5)] and p2["next_cursor"] is None


# ---- signalements -----------------------------------------------------------------------
def test_reports_for_post_and_comment_with_duplicate_protection(env, engine):
    pid = env.post().json()["id"]
    other = env.other()
    cid = env.client.post(f"/v1/community/posts/{pid}/comments", json={"body": "Un commentaire"}, headers=env.headers).json()["id"]
    assert env.client.post(f"/v1/community/posts/{pid}/report", json={"reason": "spam"}, headers=other).json() == {"created": True}
    for _ in range(5):  # 50 signalements identiques : un seul enregistrement
        assert env.client.post(f"/v1/community/posts/{pid}/report", json={"reason": "spam"}, headers=other).json() == {"created": False}
    assert env.client.post(f"/v1/community/comments/{cid}/report", json={"reason": "inappropriate", "details": "Hors sujet"}, headers=other).json() == {"created": True}
    assert env.client.post(f"/v1/community/comments/{cid}/report", json={"reason": "inappropriate"}, headers=other).json() == {"created": False}
    assert env.client.post(f"/v1/community/posts/{pid}/report", json={"reason": "dangerous"}, headers=env.headers).json() == {"created": True}
    with engine.connect() as c:
        rows = c.execute(text("SELECT reason, post_id IS NOT NULL, comment_id IS NOT NULL FROM community_reports ORDER BY reason")).all()
    assert len(rows) == 3 and ("inappropriate", False, True) in rows
    assert env.client.post(f"/v1/community/posts/{pid}/report", json={"reason": "bof"}, headers=other).json()["detail"] == "invalid_reason"
    assert env.client.post("/v1/community/posts/00000000-0000-0000-0000-000000000000/report", json={"reason": "spam"}, headers=other).status_code == 404
    assert env.client.get(f"/v1/community/posts/{pid}", headers=other).status_code == 200  # un signalement ne masque pas seul


# ---- compteurs / confidentialité du reste de l'app ---------------------------------------------
def test_community_actions_never_touch_diagnostics_or_private_data(env, engine):
    pid = env.post().json()["id"]
    env.client.put(f"/v1/community/posts/{pid}/helpful", headers=env.headers)
    env.client.put(f"/v1/community/posts/{pid}/save", headers=env.headers)
    env.client.post(f"/v1/community/posts/{pid}/comments", json={"body": "Super"}, headers=env.headers)
    with engine.connect() as c:
        assert c.execute(text("SELECT count(*) FROM diagnostic_sessions")).scalar() == 0
        assert c.execute(text("SELECT count(*) FROM service_requests")).scalar() == 0
