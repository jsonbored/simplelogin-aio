from __future__ import annotations

import sys
from pathlib import Path

from tests.conftest import REPO_ROOT
from tests.helpers import pytest_env, run_command

VALIDATE_CONFIG = REPO_ROOT / "rootfs/etc/simplelogin-aio/validate-config.py"
CONTRACTS_PATH = REPO_ROOT / "rootfs/etc/simplelogin-aio/env-enum-contracts.json"


def test_validate_config_rejects_invalid_env_file(tmp_path: Path) -> None:
    env_file = tmp_path / ".env"
    env_file.write_text("ADMIN_FIDO_REQUIRED=definitely-not-valid\n")

    env = pytest_env()
    env["SIMPLELOGIN_ENUM_CONTRACTS_PATH"] = str(CONTRACTS_PATH)

    result = run_command(
        [sys.executable, str(VALIDATE_CONFIG), "--env-file", str(env_file)],
        env=env,
        check=False,
    )

    assert result.returncode == 1  # nosec B101
    assert (
        "ADMIN_FIDO_REQUIRED='definitely-not-valid' is invalid" in result.stderr
    )  # nosec B101


def test_validate_config_rejects_invalid_process_env() -> None:
    env = pytest_env()
    env["SIMPLELOGIN_ENUM_CONTRACTS_PATH"] = str(CONTRACTS_PATH)
    env["ENABLE_OIDC_SERVER"] = "maybe"

    result = run_command(
        [sys.executable, str(VALIDATE_CONFIG), "--validate-current-env"],
        env=env,
        check=False,
    )

    assert result.returncode == 1  # nosec B101
    assert "ENABLE_OIDC_SERVER='maybe' is invalid" in result.stderr  # nosec B101


def test_validate_config_rejects_invalid_presence_process_env() -> None:
    env = pytest_env()
    env["SIMPLELOGIN_ENUM_CONTRACTS_PATH"] = str(CONTRACTS_PATH)
    env["DISABLE_REGISTRATION"] = "maybe"

    result = run_command(
        [sys.executable, str(VALIDATE_CONFIG), "--validate-current-env"],
        env=env,
        check=False,
    )

    assert result.returncode == 1  # nosec B101
    assert "DISABLE_REGISTRATION='maybe' is invalid" in result.stderr  # nosec B101
