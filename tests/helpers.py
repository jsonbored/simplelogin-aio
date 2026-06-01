from __future__ import annotations

from aio_fleet.app_testing import DockerRuntime as BaseDockerRuntime
from aio_fleet.app_testing import *  # noqa: F403
from aio_fleet.app_testing import PortMapping, VolumeMount, configure_repo_root

from tests.conftest import REPO_ROOT

configure_repo_root(REPO_ROOT)


class DockerRuntime(BaseDockerRuntime):
    def __init__(self, image_tag: str) -> None:
        super().__init__(
            image_tag,
            name_prefix="simplelogin-aio-pytest",
            port_mappings=(
                PortMapping("http_port", 7777),
                PortMapping("smtp_port", 25),
            ),
            volume_mounts=(
                VolumeMount("appdata_volume", "/appdata", "appdata"),
                VolumeMount("pgp_volume", "/pgp", "pgp"),
            ),
            default_env={
                "EMAIL_DOMAIN": "example.com",
                "FLASK_SECRET": "0123456789abcdef0123456789abcdef",  # nosec B105
                "NOT_SEND_EMAIL": "true",
                "POSTMASTER": "postmaster@example.com",
                "RELAY_MODE": "direct",
                "SUPPORT_EMAIL": "support@example.com",
                "URL": "http://127.0.0.1:{http_port}",
            },
            health_path="/health",
            health_timeout=420,
        )
