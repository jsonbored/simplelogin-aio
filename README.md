# simplelogin-aio

SimpleLogin packaged as a true All-In-One Unraid container.

`simplelogin-aio` bundles the SimpleLogin web app, background jobs, inbound email handler, Postfix, PostgreSQL, and Redis into a single container with Unraid-friendly persistence. A normal install only needs one image, one `/appdata` mapping, and the usual domain + DNS setup required by any self-hosted mail stack.

## What This Repo Ships

- A single-container `ghcr.io/jsonbored/simplelogin-aio:latest` image
- Explicit image tags matching the pinned upstream release, plus `latest` and `sha-...`
- An Unraid CA template at [simplelogin-aio.xml](/tmp/simplelogin-aio/simplelogin-aio.xml)
- A local smoke test at [scripts/smoke-test.sh](/tmp/simplelogin-aio/scripts/smoke-test.sh)
- Upstream release monitoring via [upstream.toml](/tmp/simplelogin-aio/upstream.toml) and [scripts/check-upstream.py](/tmp/simplelogin-aio/scripts/check-upstream.py)
- Automated `awesome-unraid` sync for the XML

## Included Services

- SimpleLogin web UI on port `7777`
- Postfix for inbound SMTP on port `25`
- Embedded PostgreSQL inside the container
- Embedded Redis inside the container
- SimpleLogin email handler and background job runner

## Important Runtime Notes

- Current upstream SimpleLogin container support is `linux/amd64` only, so `simplelogin-aio` currently publishes amd64-only images.
- First boot initializes PostgreSQL, writes the runtime `.env`, applies `alembic upgrade head`, and then runs `init_app.py`.
- `/appdata` is the main persistent volume. `/pgp` is optional for advanced PGP usage.
- If you already run external PostgreSQL or Redis, set `DB_URI` and `REDIS_URL` in the Unraid template and the internal daemons will stay idle.

## Quick Start

1. Install the Unraid template.
2. Set `URL`, `EMAIL_DOMAIN`, `SUPPORT_EMAIL`, and `FLASK_SECRET`.
3. Pick a relay mode if your ISP blocks outbound port `25`.
4. Forward inbound TCP port `25` to the Unraid host if you want aliases to receive internet mail.
5. Review [docs/simplelogin-setup.md](/tmp/simplelogin-aio/docs/simplelogin-setup.md) for the required DNS records and mail-routing checklist.

## Validation

Local validation completed on March 29, 2026:

- explicit `linux/amd64` Docker build succeeded
- full local smoke test passed end-to-end
- restart and persistence coverage added to the smoke test
- internal PostgreSQL, Redis, web, background jobs, and Postfix all validated in the same container
- workflow hardening added with pinned action SHAs, dependency review, and upstream release tracking

## Support

- Issues: [JSONbored/simplelogin-aio issues](https://github.com/JSONbored/simplelogin-aio/issues)
- Upstream app: [simple-login/app](https://github.com/simple-login/app)

## Funding

If this work saves you time, support it here:

- [GitHub Sponsors](https://github.com/sponsors/JSONbored)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=JSONbored/simplelogin-aio&theme=dark)](https://star-history.com/#JSONbored/simplelogin-aio&Date)
