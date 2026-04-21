from __future__ import annotations

import os
import shutil
import socket
import subprocess  # nosec B404 - test helpers shell out only to trusted local tooling
import time
import uuid
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path
from tempfile import TemporaryDirectory

from tests.conftest import REPO_ROOT


def run_command(
    command: list[str],
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    check: bool = True,
    capture_output: bool = True,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(  # nosec B603 - tests execute trusted local commands only
        command,
        cwd=cwd or REPO_ROOT,
        env=env,
        check=check,
        text=True,
        capture_output=capture_output,
    )


def docker_available() -> bool:
    if shutil.which("docker") is None:
        return False

    result = run_command(["docker", "info"], check=False)
    return result.returncode == 0


def reserve_host_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        sock.listen(1)
        return sock.getsockname()[1]


class DockerRuntime:
    def __init__(self, image_tag: str) -> None:
        self.image_tag = image_tag

    def build(self) -> None:
        run_command(
            ["docker", "build", "--platform", "linux/amd64", "-t", self.image_tag, "."]
        )

    def inspect_state(self, name: str, field: str) -> str:
        result = run_command(
            ["docker", "inspect", "-f", f"{{{{.{field}}}}}", name],
            check=False,
        )
        return result.stdout.strip() if result.returncode == 0 else ""

    def logs(self, name: str) -> str:
        result = run_command(["docker", "logs", name], check=False)
        return result.stdout + result.stderr

    def remove(self, name: str) -> None:
        run_command(["docker", "rm", "-f", name], check=False)

    @contextmanager
    def container(
        self,
        *,
        env_overrides: dict[str, str] | None = None,
        network: str | None = None,
    ) -> Iterator["ContainerHandle"]:
        suffix = uuid.uuid4().hex[:10]
        name = f"simplelogin-aio-pytest-{suffix}"
        http_port = reserve_host_port()
        smtp_port = reserve_host_port()

        with TemporaryDirectory(
            prefix=f"{name}-appdata-"
        ) as appdata_dir, TemporaryDirectory(prefix=f"{name}-pgp-") as pgp_dir:
            command = [
                "docker",
                "run",
                "-d",
                "--platform",
                "linux/amd64",
                "--name",
                name,
            ]
            if network:
                command.extend(["--network", network])
            command.extend(
                [
                    "-p",
                    f"{http_port}:7777",
                    "-p",
                    f"{smtp_port}:25",
                    "-e",
                    f"URL=http://127.0.0.1:{http_port}",
                    "-e",
                    "EMAIL_DOMAIN=example.com",
                    "-e",
                    "SUPPORT_EMAIL=support@example.com",
                    "-e",
                    "FLASK_SECRET=0123456789abcdef0123456789abcdef",
                    "-e",
                    "RELAY_MODE=direct",
                    "-e",
                    "NOT_SEND_EMAIL=true",
                    "-e",
                    "POSTMASTER=postmaster@example.com",
                    "-v",
                    f"{appdata_dir}:/appdata",
                    "-v",
                    f"{pgp_dir}:/pgp",
                ]
            )

            if env_overrides:
                for key, value in env_overrides.items():
                    command.extend(["-e", f"{key}={value}"])

            command.append(self.image_tag)
            run_command(command)
            handle = ContainerHandle(
                runtime=self,
                name=name,
                http_port=http_port,
                smtp_port=smtp_port,
                appdata_dir=Path(appdata_dir),
                pgp_dir=Path(pgp_dir),
            )
            try:
                yield handle
            finally:
                self.remove(name)


class ContainerHandle:
    def __init__(
        self,
        *,
        runtime: DockerRuntime,
        name: str,
        http_port: int,
        smtp_port: int,
        appdata_dir: Path,
        pgp_dir: Path,
    ) -> None:
        self.runtime = runtime
        self.name = name
        self.http_port = http_port
        self.smtp_port = smtp_port
        self.appdata_dir = appdata_dir
        self.pgp_dir = pgp_dir

    def logs(self) -> str:
        return self.runtime.logs(self.name)

    def exec(self, command: str) -> subprocess.CompletedProcess[str]:
        return run_command(["docker", "exec", self.name, "sh", "-lc", command])

    def restart(self) -> None:
        run_command(["docker", "restart", self.name])

    def is_running(self) -> bool:
        return self.runtime.inspect_state(self.name, "State.Status") == "running"

    def wait_for_http(self, *, timeout: int = 420) -> None:
        deadline = time.time() + timeout
        url = f"http://127.0.0.1:{self.http_port}/health"

        while time.time() < deadline:
            if not self.is_running():
                raise AssertionError(
                    f"{self.name} stopped before HTTP became healthy.\nLogs:\n{self.logs()}"
                )

            result = run_command(
                ["curl", "-fsS", url],
                check=False,
            )
            if result.returncode == 0:
                return
            time.sleep(2)

        raise AssertionError(
            f"{self.name} did not become HTTP healthy.\nLogs:\n{self.logs()}"
        )

    def wait_for_smtp(self, *, timeout: int = 120) -> None:
        deadline = time.time() + timeout

        while time.time() < deadline:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.settimeout(1)
                if sock.connect_ex(("127.0.0.1", self.smtp_port)) == 0:
                    return
            time.sleep(2)

        raise AssertionError(f"{self.name} did not expose SMTP.\nLogs:\n{self.logs()}")

    def wait_for_log(self, needle: str, *, timeout: int = 90) -> None:
        deadline = time.time() + timeout
        while time.time() < deadline:
            if needle in self.logs():
                return
            time.sleep(2)

        raise AssertionError(
            f"{needle!r} not found in logs for {self.name}.\nLogs:\n{self.logs()}"
        )

    def wait_for_exit(self, *, timeout: int = 45) -> str:
        deadline = time.time() + timeout
        while time.time() < deadline:
            status = self.runtime.inspect_state(self.name, "State.Status")
            if status == "exited":
                return status
            time.sleep(1)

        raise AssertionError(f"{self.name} did not exit in time.\nLogs:\n{self.logs()}")


def pytest_env(base_env: dict[str, str] | None = None) -> dict[str, str]:
    env = dict(os.environ if base_env is None else base_env)
    env.setdefault("PYTHONUNBUFFERED", "1")
    return env
