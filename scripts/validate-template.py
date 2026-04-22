#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from defusedxml import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE_PATH = ROOT / "simplelogin-aio.xml"
ENUM_CONTRACTS_PATH = ROOT / "rootfs/etc/simplelogin-aio/env-enum-contracts.json"
WRITE_ENV_PATH = ROOT / "rootfs/etc/cont-init.d/03-write-env.sh"
ENV_HELPERS_PATH = ROOT / "rootfs/etc/simplelogin-aio/env-helpers.sh"

REQUIRED_TARGETS = {
    "/appdata",
    "/custom-assets",
    "/pgp",
    "25",
    "7777",
    "ADMIN_EMAIL",
    "ALIAS_AUTOMATIC_DISABLE",
    "ALIAS_DOMAINS",
    "ALIAS_LIMIT",
    "ALLOWED_REDIRECT_DOMAINS",
    "APPLE_API_SECRET",
    "AUTO_GENERATE_PGP",
    "AWS_ACCESS_KEY_ID",
    "AWS_REGION",
    "AWS_SECRET_ACCESS_KEY",
    "BOUNCE_PREFIX",
    "BOUNCE_PREFIX_FOR_REPLY_PHASE",
    "BOUNCE_SUFFIX",
    "BREVO_PASSWORD",
    "BREVO_USERNAME",
    "BUCKET",
    "COINBASE_API_KEY",
    "COINBASE_CHECKOUT_ID",
    "COINBASE_WEBHOOK_SECRET",
    "COINBASE_YEARLY_PRICE",
    "COLOR_LOG",
    "CONNECT_WITH_OIDC_ICON",
    "CONNECT_WITH_PROTON",
    "CONNECT_WITH_PROTON_COOKIE_NAME",
    "CUSTOM_PASSWORD",
    "CUSTOM_RELAYHOST",
    "CUSTOM_USERNAME",
    "DB_URI",
    "DISABLE_ALIAS_SUFFIX",
    "DISABLE_ONBOARDING",
    "DISABLE_REGISTRATION",
    "DKIM_PRIVATE_KEY_PATH",
    "EMAIL_DOMAIN",
    "EMAIL_SERVERS_WITH_PRIORITY",
    "ENABLE_OIDC_SERVER",
    "ENABLE_SPAM_ASSASSIN",
    "ENFORCE_SPF",
    "FACEBOOK_CLIENT_ID",
    "FACEBOOK_CLIENT_SECRET",
    "FIRST_ALIAS_DOMAIN",
    "FLASK_PROFILER_PASSWORD",
    "FLASK_PROFILER_PATH",
    "FLASK_SECRET",
    "GITHUB_CLIENT_ID",
    "GITHUB_CLIENT_SECRET",
    "GMAIL_APP_PASSWORD",
    "GMAIL_USERNAME",
    "GOOGLE_CLIENT_ID",
    "GOOGLE_CLIENT_SECRET",
    "GNUPGHOME",
    "HCAPTCHA_SECRET",
    "HCAPTCHA_SITEKEY",
    "HIBP_API_KEYS",
    "HIBP_SCAN_INTERVAL_DAYS",
    "LANDING_PAGE_URL",
    "LOCAL_FILE_UPLOAD",
    "MACAPP_APPLE_API_SECRET",
    "MAILGUN_PASSWORD",
    "MAILGUN_USERNAME",
    "MAX_NB_EMAIL_FREE_PLAN",
    "NAMESERVERS",
    "NOT_SEND_EMAIL",
    "OIDC_CLIENT_ID",
    "OIDC_CLIENT_SECRET",
    "OIDC_NAME_FIELD",
    "OIDC_SCOPES",
    "OIDC_WELL_KNOWN_URL",
    "OPENID_PRIVATE_KEY_PATH",
    "OPENID_PUBLIC_KEY_PATH",
    "OTHER_ALIAS_DOMAINS",
    "PADDLE_AUTH_CODE",
    "PADDLE_MONTHLY_PRODUCT_ID",
    "PADDLE_PUBLIC_KEY_PATH",
    "PADDLE_VENDOR_ID",
    "PADDLE_YEARLY_PRODUCT_ID",
    "PARTNER_API_TOKEN_SECRET",
    "PGP_SENDER_PRIVATE_KEY_PATH",
    "PLAUSIBLE_DOMAIN",
    "PLAUSIBLE_HOST",
    "POSTFIX_PORT",
    "POSTFIX_SERVER",
    "POSTMASTER",
    "PREMIUM_ALIAS_DOMAINS",
    "PROTONMAIL_TOKEN",
    "PROTON_BASE_URL",
    "PROTON_CLIENT_ID",
    "PROTON_CLIENT_SECRET",
    "PROTON_VALIDATE_CERTS",
    "REDIS_URL",
    "RELAY_MODE",
    "SENTRY_DSN",
    "SENTRY_FRONT_END_DSN",
    "SPAMASSASSIN_HOST",
    "STATUS_PAGE_URL",
    "SUPPORT_EMAIL",
    "SUPPORT_NAME",
    "TEMP_DIR",
    "URL",
    "WORDS_FILE_PATH",
}

GENERATED_CHANGELOG_NOTE = (
    "Generated from CHANGELOG.md during release preparation. Do not edit manually."
)
GENERATED_CHANGELOG_BULLET = f"- {GENERATED_CHANGELOG_NOTE}"
CHANGELOG_HEADER_PATTERN = re.compile(r"^### \d{4}-\d{2}-\d{2}$")
LEGACY_CHANGELOG_MARKERS = (
    "[b]Latest release[/b]",
    "GitHub Releases",
    "Full changelog and release notes:",
)


def load_enum_contracts() -> dict[str, dict[str, object]]:
    return json.loads(ENUM_CONTRACTS_PATH.read_text())


def validate_changes(changes: str) -> str | None:
    for marker in LEGACY_CHANGELOG_MARKERS:
        if marker in changes:
            return (
                "simplelogin-aio.xml <Changes> still uses the legacy release-link "
                f"format: {marker}"
            )

    lines = [line.strip() for line in changes.splitlines() if line.strip()]
    if len(lines) < 3:
        return (
            "simplelogin-aio.xml <Changes> must include a date heading, the "
            "generated note, and at least one bullet"
        )
    if not CHANGELOG_HEADER_PATTERN.fullmatch(lines[0]):
        return "simplelogin-aio.xml <Changes> must start with '### YYYY-MM-DD'"
    if lines[1] != GENERATED_CHANGELOG_BULLET:
        return (
            "simplelogin-aio.xml <Changes> second line should be "
            f"'{GENERATED_CHANGELOG_BULLET}'"
        )
    invalid_lines = [line for line in lines[1:] if not line.startswith("- ")]
    if invalid_lines:
        return (
            "simplelogin-aio.xml <Changes> must use bullet lines after the "
            f"heading; found {invalid_lines[0]!r}"
        )
    return None


def main() -> int:
    tree = ET.parse(TEMPLATE_PATH)
    root = tree.getroot()

    targets = {
        elem.attrib["Target"]
        for elem in root.findall(".//Config")
        if "Target" in elem.attrib and elem.attrib["Target"]
    }

    missing = sorted(REQUIRED_TARGETS - targets)
    if missing:
        print(
            "simplelogin-aio.xml is missing required upstream/runtime targets:",
            file=sys.stderr,
        )
        for target in missing:
            print(f"  - {target}", file=sys.stderr)
        return 1

    overview = (root.findtext("Overview") or "").strip()
    if not overview:
        print("simplelogin-aio.xml is missing a non-empty <Overview>", file=sys.stderr)
        return 1

    changes = (root.findtext("Changes") or "").strip()
    if not changes:
        print(
            "simplelogin-aio.xml is missing a non-empty <Changes> section",
            file=sys.stderr,
        )
        return 1
    error = validate_changes(changes)
    if error:
        print(error, file=sys.stderr)
        return 1

    invalid_option_configs: list[str] = []
    invalid_pipe_configs: list[str] = []
    for config in root.findall(".//Config"):
        name = config.attrib.get("Name", config.attrib.get("Target", "<unnamed>"))
        if config.findall("Option"):
            invalid_option_configs.append(name)

        default = config.attrib.get("Default", "")
        if "|" not in default:
            continue

        allowed_values = default.split("|")
        if any(value == "" for value in allowed_values):
            invalid_pipe_configs.append(
                f"{name} (allowed={allowed_values!r}, empty pipe options are not allowed)"
            )
            continue

        selected_value = (config.text or "").strip()
        if selected_value not in allowed_values:
            invalid_pipe_configs.append(
                f"{name} (selected={selected_value!r}, allowed={allowed_values!r})"
            )

    if invalid_option_configs:
        print(
            "simplelogin-aio.xml uses nested <Option> tags, which are not allowed by the catalog-safe template format:",
            file=sys.stderr,
        )
        for name in invalid_option_configs:
            print(f"  - {name}", file=sys.stderr)
        return 1

    if invalid_pipe_configs:
        print(
            "simplelogin-aio.xml has pipe-delimited defaults whose selected value is not one of the allowed options:",
            file=sys.stderr,
        )
        for detail in invalid_pipe_configs:
            print(f"  - {detail}", file=sys.stderr)
        return 1

    enum_contracts = load_enum_contracts()
    configs_by_target = {
        config.attrib["Target"]: config
        for config in root.findall(".//Config")
        if "Target" in config.attrib
    }
    write_env_text = WRITE_ENV_PATH.read_text()
    env_helpers_text = ENV_HELPERS_PATH.read_text()

    enum_contract_errors: list[str] = []
    for target, contract in enum_contracts.items():
        config = configs_by_target.get(target)
        if config is None:
            enum_contract_errors.append(f"{target} is missing from simplelogin-aio.xml")
            continue

        expected_values = contract["template_values"]
        actual_default = config.attrib.get("Default", "").split("|")
        if actual_default != expected_values:
            enum_contract_errors.append(
                f"{target} default choices drifted: xml={actual_default!r}, contract={expected_values!r}"
            )

        selected_value = (config.text or "").strip()
        expected_selected = contract["template_default"]
        if selected_value != expected_selected:
            enum_contract_errors.append(
                f"{target} selected value drifted: xml={selected_value!r}, contract={expected_selected!r}"
            )

        if contract.get("write_env", False) and target not in write_env_text:
            enum_contract_errors.append(
                f"{target} is in the enum contract but is not emitted by 03-write-env.sh"
            )

        helper_kind = contract.get("env_helper")
        if helper_kind and target not in env_helpers_text:
            enum_contract_errors.append(
                f"{target} expects env-helper normalization ({helper_kind}) but is missing from env-helpers.sh"
            )

    if enum_contract_errors:
        print(
            "simplelogin-aio enum contracts drifted between the XML and startup scripts:",
            file=sys.stderr,
        )
        for detail in enum_contract_errors:
            print(f"  - {detail}", file=sys.stderr)
        return 1

    print(
        f"simplelogin-aio.xml parsed successfully and includes {len(REQUIRED_TARGETS)} required targets"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
