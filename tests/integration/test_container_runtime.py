from __future__ import annotations

import time

import pytest

from tests.helpers import DockerRuntime, docker_available, run_command

IMAGE_TAG = "simplelogin-aio:pytest"
pytestmark = pytest.mark.integration


@pytest.fixture(scope="session")
def runtime() -> DockerRuntime:
    if not docker_available():
        pytest.skip("Docker is unavailable; integration tests require Docker/OrbStack.")

    runtime = DockerRuntime(IMAGE_TAG)
    runtime.build()
    return runtime


def test_happy_path_boot_and_restart(runtime: DockerRuntime) -> None:
    with runtime.container(env_overrides={"DISABLE_REGISTRATION": "1"}) as container:
        container.wait_for_http()
        container.wait_for_smtp()
        assert (container.appdata_dir / "postgres/PG_VERSION").is_file()  # nosec B101
        assert (container.appdata_dir / "sl/.initialized").is_file()  # nosec B101

        container.restart()
        container.wait_for_http()
        container.wait_for_smtp()
        assert (container.appdata_dir / "postgres/PG_VERSION").is_file()  # nosec B101
        assert (container.appdata_dir / "sl/.initialized").is_file()  # nosec B101


@pytest.mark.parametrize(
    ("case_name", "env_overrides"),
    [
        ("legacy-admin-fido-default", {"ADMIN_FIDO_REQUIRED": "|none|any|hardware"}),
        (
            "legacy-admin-fido-no-leading-pipe",
            {"ADMIN_FIDO_REQUIRED": "none|any|hardware"},
        ),
        ("blank-admin-fido", {"ADMIN_FIDO_REQUIRED": ""}),
        ("admin-fido-any", {"ADMIN_FIDO_REQUIRED": "any"}),
        ("admin-fido-hardware", {"ADMIN_FIDO_REQUIRED": "hardware"}),
    ],
)
def test_admin_fido_runtime_compatibility(
    runtime: DockerRuntime, case_name: str, env_overrides: dict[str, str]
) -> None:
    with runtime.container(env_overrides=env_overrides) as container:
        container.wait_for_http()
        container.wait_for_smtp()


def test_oidc_key_generation(runtime: DockerRuntime) -> None:
    with runtime.container(env_overrides={"ENABLE_OIDC_SERVER": "1"}) as container:
        container.wait_for_http()
        container.wait_for_smtp()
        container.exec(
            'python -c "from pathlib import Path; '
            "paths={'/appdata/sl/jwtRS256.key':'0o600','/appdata/sl/jwtRS256.key.pub':'0o644'}; "
            "[((lambda p,e: (p.is_file() and oct(p.stat().st_mode & 0o777)==e) or "
            "(_ for _ in ()).throw(SystemExit(f'{p}:{oct(p.stat().st_mode & 0o777) if p.exists() else \\\"missing\\\"}!={e}')))"
            '(Path(path), expected)) for path, expected in paths.items()]"'
        )


def test_pgp_key_generation(runtime: DockerRuntime) -> None:
    with runtime.container(env_overrides={"AUTO_GENERATE_PGP": "1"}) as container:
        container.wait_for_http()
        container.wait_for_smtp()
        container.exec(
            'python -c "from pathlib import Path; '
            "paths={'/pgp/server_private_key.asc':'0o600','/pgp/server_public_key.asc':'0o644'}; "
            "[((lambda p,e: (p.is_file() and oct(p.stat().st_mode & 0o777)==e) or "
            "(_ for _ in ()).throw(SystemExit(f'{p}:{oct(p.stat().st_mode & 0o777) if p.exists() else \\\"missing\\\"}!={e}')))"
            '(Path(path), expected)) for path, expected in paths.items()]"'
        )


@pytest.mark.parametrize(
    ("case_name", "env_overrides", "expected_line"),
    [
        (
            "relay-brevo",
            {
                "RELAY_MODE": "brevo",
                "BREVO_USERNAME": "brevo-user",
                "BREVO_PASSWORD": "brevo-pass",  # nosec B105
            },
            "[smtp-relay.brevo.com]:587 brevo-user:brevo-pass",
        ),
        (
            "relay-protonmail",
            {
                "RELAY_MODE": "protonmail",
                "PROTONMAIL_TOKEN": "proton-token",
            },  # nosec B105
            "[smtp.protonmail.ch]:587 support@example.com:proton-token",
        ),
        (
            "relay-gmail",
            {
                "RELAY_MODE": "gmail",
                "GMAIL_USERNAME": "user@gmail.com",
                "GMAIL_APP_PASSWORD": "abcdefghijklmnop",  # nosec B105
            },
            "[smtp.gmail.com]:587 user@gmail.com:abcdefghijklmnop",
        ),
        (
            "relay-mailgun",
            {
                "RELAY_MODE": "mailgun",
                "MAILGUN_USERNAME": "postmaster@example.com",
                "MAILGUN_PASSWORD": "mailgun-pass",  # nosec B105
            },
            "[smtp.mailgun.org]:587 postmaster@example.com:mailgun-pass",
        ),
        (
            "relay-custom",
            {
                "RELAY_MODE": "custom",
                "CUSTOM_RELAYHOST": "[smtp.example.net]:587",
                "CUSTOM_USERNAME": "smtp-user",
                "CUSTOM_PASSWORD": "smtp-pass",  # nosec B105
            },
            "[smtp.example.net]:587 smtp-user:smtp-pass",
        ),
    ],
)
def test_relay_modes(
    runtime: DockerRuntime,
    case_name: str,
    env_overrides: dict[str, str],
    expected_line: str,
) -> None:
    with runtime.container(env_overrides=env_overrides) as container:
        container.wait_for_http()
        container.wait_for_smtp()
        result = container.exec("cat /etc/postfix/sasl_passwd")
        assert expected_line in result.stdout  # nosec B101


@pytest.mark.parametrize(
    ("case_name", "env_overrides", "expected_log", "expected_fatal_log"),
    [
        (
            "invalid-admin-fido",
            {"ADMIN_FIDO_REQUIRED": "definitely-not-valid"},
            "ADMIN_FIDO_REQUIRED='definitely-not-valid' is invalid",
            "Fatal raw-env validation failure. Stopping container before normalization or long-running services start.",
        ),
        (
            "invalid-relay-mode",
            {"RELAY_MODE": "bogus"},
            "RELAY_MODE='bogus' is invalid",
            "Fatal raw-env validation failure. Stopping container before normalization or long-running services start.",
        ),
        (
            "invalid-enable-oidc-server",
            {"ENABLE_OIDC_SERVER": "maybe"},
            "ENABLE_OIDC_SERVER='maybe' is invalid",
            "Fatal raw-env validation failure. Stopping container before normalization or long-running services start.",
        ),
        (
            "invalid-enable-spamassassin",
            {"ENABLE_SPAM_ASSASSIN": "maybe"},
            "ENABLE_SPAM_ASSASSIN='maybe' is invalid",
            "Fatal raw-env validation failure. Stopping container before normalization or long-running services start.",
        ),
        (
            "invalid-disable-registration",
            {"DISABLE_REGISTRATION": "maybe"},
            "DISABLE_REGISTRATION='maybe' is invalid",
            "Fatal raw-env validation failure. Stopping container before normalization or long-running services start.",
        ),
        (
            "missing-url",
            {"URL": ""},
            "[ERROR] URL is not set.",
            "Validation failed with 1 error(s). Container startup halted.",
        ),
    ],
)
def test_fatal_preflight_cases(
    runtime: DockerRuntime,
    case_name: str,
    env_overrides: dict[str, str],
    expected_log: str,
    expected_fatal_log: str,
) -> None:
    with runtime.container(env_overrides=env_overrides) as container:
        container.wait_for_log(expected_log)
        container.wait_for_log(expected_fatal_log)
        container.wait_for_exit()
        logs = container.logs()
        assert "Starting gunicorn" not in logs  # nosec B101
        assert "Running SimpleLogin database migrations..." not in logs  # nosec B101


def test_external_db_and_redis(runtime: DockerRuntime) -> None:
    network_name = f"simplelogin-aio-pytest-net-{int(time.time())}"
    postgres_name = f"simplelogin-aio-pytest-postgres-{int(time.time())}"
    redis_name = f"simplelogin-aio-pytest-redis-{int(time.time())}"

    run_command(["docker", "network", "create", network_name])
    try:
        run_command(
            [
                "docker",
                "run",
                "-d",
                "--platform",
                "linux/amd64",
                "--name",
                postgres_name,
                "--network",
                network_name,
                "-e",
                "POSTGRES_DB=simplelogin",
                "-e",
                "POSTGRES_USER=simplelogin",
                "-e",
                "POSTGRES_PASSWORD=simpleloginpass",
                "postgres:14",
            ]
        )
        run_command(
            [
                "docker",
                "run",
                "-d",
                "--platform",
                "linux/amd64",
                "--name",
                redis_name,
                "--network",
                network_name,
                "redis:6",
            ]
        )

        deadline = time.time() + 120
        while time.time() < deadline:
            postgres_ready = (
                run_command(
                    [
                        "docker",
                        "exec",
                        postgres_name,
                        "pg_isready",
                        "-U",
                        "simplelogin",
                        "-d",
                        "simplelogin",
                    ],
                    check=False,
                ).returncode
                == 0
            )
            redis_ready = (
                run_command(
                    ["docker", "exec", redis_name, "redis-cli", "ping"],
                    check=False,
                ).returncode
                == 0
            )
            if postgres_ready and redis_ready:
                break
            time.sleep(2)
        else:
            raise AssertionError(
                "External PostgreSQL/Redis test services did not become ready in time."
            )

        with runtime.container(
            env_overrides={
                "DB_URI": f"postgresql://simplelogin:simpleloginpass@{postgres_name}:5432/simplelogin",
                "REDIS_URL": f"redis://{redis_name}:6379/0",
            },
            network=network_name,
        ) as container:
            container.wait_for_http()
            container.wait_for_smtp()
            postgres_result = container.exec(
                "! ps -eo args | grep -E '(^| )/usr/lib/postgresql/.*/bin/postgres -D /appdata/postgres' >/dev/null"
            )
            redis_result = container.exec("! pgrep -x redis-server >/dev/null")
            assert postgres_result.returncode == 0  # nosec B101
            assert redis_result.returncode == 0  # nosec B101
    finally:
        run_command(["docker", "rm", "-f", postgres_name, redis_name], check=False)
        run_command(["docker", "network", "rm", network_name], check=False)
