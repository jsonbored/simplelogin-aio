from __future__ import annotations

from defusedxml import ElementTree as ET

from tests.conftest import REPO_ROOT


def test_ca_metadata_uses_current_categories_and_discovery_fields() -> None:
    root = ET.parse(REPO_ROOT / "simplelogin-aio.xml").getroot()

    assert (  # nosec B101
        root.findtext("Category") == "Network:Privacy Network:Web Tools:Utilities"
    )
    assert (
        root.findtext("ReadMe") == "https://github.com/JSONbored/simplelogin-aio#readme"
    )  # nosec B101
    assert [s.text for s in root.findall("Screenshot")] == [  # nosec B101
        "https://raw.githubusercontent.com/JSONbored/awesome-unraid/main/screenshots/simplelogin-aio/01-login.png",
        "https://raw.githubusercontent.com/JSONbored/awesome-unraid/main/screenshots/simplelogin-aio/02-dashboard.png",
        "https://raw.githubusercontent.com/JSONbored/awesome-unraid/main/screenshots/simplelogin-aio/03-settings.png",
    ]
