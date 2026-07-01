import jwt
import pytest

from app.core import security
from app.schemas.user import normalize_phone


def test_argon2id_hash_roundtrip():
    hashed = security.hash_password("s3cret-pass")
    assert hashed.startswith("$argon2id$")
    assert security.verify_password("s3cret-pass", hashed)
    assert not security.verify_password("wrong", hashed)


def test_access_token_encodes_role_and_type():
    token = security.create_access_token(42, "admin")
    payload = security.decode_token(token, security.ACCESS)
    assert payload["sub"] == "42"
    assert payload["role"] == "admin"
    assert payload["type"] == "access"


def test_wrong_token_type_rejected():
    refresh = security.create_refresh_token(7)
    with pytest.raises(jwt.InvalidTokenError):
        security.decode_token(refresh, security.ACCESS)


@pytest.mark.parametrize(
    "raw,expected",
    [
        ("07701234567", "07701234567"),
        ("+9647701234567", "07701234567"),
        ("0770 123 4567", "07701234567"),
    ],
)
def test_phone_normalization(raw, expected):
    assert normalize_phone(raw) == expected


@pytest.mark.parametrize("bad", ["12345", "0912345678", "abcdefg", ""])
def test_phone_rejects_invalid(bad):
    with pytest.raises(ValueError):
        normalize_phone(bad)
