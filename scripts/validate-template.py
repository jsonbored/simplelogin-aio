#!/usr/bin/env python3
from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TEMPLATE_PATH = ROOT / "simplelogin-aio.xml"

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
        print("simplelogin-aio.xml is missing required upstream/runtime targets:", file=sys.stderr)
        for target in missing:
            print(f"  - {target}", file=sys.stderr)
        return 1

    overview = (root.findtext("Overview") or "").strip()
    if not overview:
        print("simplelogin-aio.xml is missing a non-empty <Overview>", file=sys.stderr)
        return 1

    changes = (root.findtext("Changes") or "").strip()
    if not changes:
        print("simplelogin-aio.xml is missing a non-empty <Changes> section", file=sys.stderr)
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

    print(
        f"simplelogin-aio.xml parsed successfully and includes {len(REQUIRED_TARGETS)} required targets"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
