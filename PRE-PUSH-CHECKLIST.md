# SimpleLogin AIO Pre-Push Checklist

Before pushing this template to the `unraid-templates` repository, ensure all items below are completed and verified.

## 1. File Completeness
- [x] `Dockerfile` (Builds from `simplelogin/app-ci`, adds s6, sets volumes/ports, includes HEALTHCHECK)
- [x] `.github/workflows/build.yml` (Handles automated tagging based on upstream releases)
- [x] `rootfs/etc/cont-init.d/01-validate-env.sh` (Strict required variable checks)
- [x] `rootfs/etc/cont-init.d/02-dkim-setup.sh` (Auto-generates DKIM keys cleanly)
- [x] `rootfs/etc/cont-init.d/03-write-env.sh` (Isolates and translates XML vars to `/code/.env`)
- [x] `rootfs/etc/cont-init.d/04-db-migrate.sh` (Idempotent DB migrations and `/sl/.initialized` lock)
- [x] `rootfs/etc/services.d/simplelogin-web/run` (Gunicorn 0.0.0.0:7777)
- [x] `rootfs/etc/services.d/simplelogin-email/run` (`email_handler.py`)
- [x] `rootfs/etc/services.d/simplelogin-job/run` (`job_runner.py`)
- [x] `SimpleLogin-AIO.xml` (The core Unraid CA Template)
- [x] `SimpleLogin-Postfix.xml` (The MTA Companion Template with Relay configs)
- [x] `docs/simplelogin-setup.md` (Setup instructions including DNS records)
- [x] `README.md` (If applicable for repo root)

## 2. Configuration Quality
- [x] ALL required variables from upstream `example.env` are present in the XML.
- [x] ALL sensitive variables (passwords, secrets, tokens, API keys) have `Mask="true"` set.
- [x] Init scripts are fully idempotent (safe to run on every container restart without data loss).
- [x] Ports correctly exposed (7777 TCP for Web, 20381 TCP for internal email routing).
- [x] Volumes correctly mapped (`/sl`, `/dkim`).

## 3. Manual Actions Required by User (ghost)
- [ ] **Push:** Run `git push` (Explicit permission required via GITHUB_TOKEN).
- [ ] **Icon:** Manually upload `simplelogin.png` and `postfix.png` to `JSONbored/unraid-templates/icons/`.
- [ ] **Support Forum:** Create the official support thread on `forums.unraid.net`, then update the `<Support>` URL in both XML templates to point to the newly created thread.