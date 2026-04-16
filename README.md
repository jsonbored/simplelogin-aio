<div align="center">

<img src="https://socialify.git.ci/JSONbored/simplelogin-aio/image?custom_description=SimpleLogin+All-in-One+Docker+image+for+Unraid+%E2%80%94+self-host+your+own+email+alias+service+easily.+Highly+configurable+for+power+users.&custom_language=Dockerfile&description=1&font=Raleway&forks=1&language=1&logo=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F51910064%3Fs%3D200%26v%3D4&name=1&owner=1&pattern=Brick+Wall&stargazers=1&theme=Dark" alt="simplelogin-aio" width="640" height="320" />

</div>

---

An Unraid-first, single-container deployment of [SimpleLogin](https://github.com/simple-login/app) for people who want the self-hosted alias stack without manually wiring separate Postgres, Redis, and Postfix containers.

`simplelogin-aio` packages the web UI, background jobs, inbound email handler, Postfix, PostgreSQL, and Redis into one image with persistent Unraid appdata paths. The wrapper is opinionated for a reliable first boot, but it does not hide the real complexity of self-hosted mail: DNS, inbound port 25, SPF/DKIM/DMARC, and sender reputation still matter.

## What This Image Includes

- SimpleLogin web UI on port `7777`
- Background job runner
- Inbound email handler
- Embedded PostgreSQL
- Embedded Redis
- Embedded Postfix for inbound and outbound mail routing
- Unraid CA template at [simplelogin-aio.xml](simplelogin-aio.xml)

## Beginner Install

If you want the simplest supported path:

1. Install the Unraid template.
2. Set `URL`, `EMAIL_DOMAIN`, `SUPPORT_EMAIL`, and `FLASK_SECRET`.
3. Pick a relay mode if your ISP blocks outbound TCP 25.
4. Forward inbound TCP 25 from your router/firewall to the Unraid host.
5. Start the container and wait for first-boot initialization to complete.
6. Add the DNS records from [docs/simplelogin-setup.md](docs/simplelogin-setup.md).

For most users, that is enough to get a working instance online.

## Power User Surface

This repo is deliberately not a stripped-down "toy" wrapper. The template now tracks the full upstream self-hosting environment surface from SimpleLogin's official `example.env`, plus AIO-specific relay controls. In Advanced View you can:

- move PostgreSQL or Redis out of the container with `DB_URI` or `REDIS_URL`
- override alias domain behavior and onboarding rules
- configure GitHub, Google, Facebook, Proton, and generic OIDC auth
- enable hCaptcha, HIBP, SpamAssassin, Plausible, and Sentry
- provide AWS, Paddle, and Coinbase settings
- mount `/custom-assets` for custom words files, OpenID keys, Paddle public keys, or other file-based upstream settings

The wrapper still defaults to the internal bundled services so beginners are not forced into a multi-container setup on day one.

## What You Get In-App

The official SimpleLogin docs describe several major capabilities that are configured inside the running app after deployment, not through extra container env vars. Once this container is up, those app features are still available without adding more containers for core infrastructure:

- custom domains and alias domains
- catch-all behavior and mailbox routing
- reverse aliases / reply flow
- multiple mailboxes
- alias directories and organization features exposed by the app UI
- login methods such as social auth, Proton auth, and generic OIDC when their related env vars are set

In other words, the template is responsible for exposing deployment-time and integration-time configuration, while the SimpleLogin web UI still handles normal application-level features after first boot.

## Runtime Notes

- Upstream SimpleLogin container support is currently `linux/amd64` only, so this wrapper publishes amd64-only images.
- First boot initializes PostgreSQL when `DB_URI` is unset, starts Redis when `REDIS_URL` is unset, writes the runtime `.env`, applies `alembic upgrade head`, then runs `init_app.py`.
- `/appdata` is the main persistent volume. It stores PostgreSQL, Redis, uploads, DKIM keys, generated OpenID keys, and other runtime state.
- `/pgp` is the optional persistent GnuPG home.
- `/custom-assets` is an optional advanced mount for file-based upstream settings.
- DKIM keys are persisted under `/appdata/dkim` and symlinked into the in-container paths the app expects.

## Publishing and Releases

- Wrapper releases use the upstream version plus an AIO revision, such as `v4.80.1-aio.1`.
- The repo monitors upstream releases and image digest changes through [upstream.toml](upstream.toml) and [scripts/check-upstream.py](scripts/check-upstream.py).
- Release notes are generated with `git-cliff`.
- The Unraid template `<Changes>` block is synced from `CHANGELOG.md` during release preparation.
- `main` publishes `latest`, the pinned upstream version tag, an explicit AIO packaging line tag, and `sha-<commit>`.
- When Docker Hub credentials are configured, the same publish flow can push Docker Hub tags in parallel with GHCR.

See [docs/releases.md](docs/releases.md) for the release workflow details.

## Validation

Local validation is built around:

- XML validation for the audited template surface
- shell and Python syntax checks
- local Docker build on `linux/amd64`
- end-to-end smoke test coverage for first boot, health, SMTP readiness, restart, and persistence

## Support

- Repo issues: [JSONbored/simplelogin-aio issues](https://github.com/JSONbored/simplelogin-aio/issues)
- Upstream app: [simple-login/app](https://github.com/simple-login/app)

## Funding

If this work saves you time, support it here:

- [GitHub Sponsors](https://github.com/sponsors/JSONbored)
- [Ko-fi](https://ko-fi.com/jsonbored)
- [Buy Me a Coffee](https://buymeacoffee.com/jsonbored)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=JSONbored/simplelogin-aio&theme=dark)](https://star-history.com/#JSONbored/simplelogin-aio&Date)
