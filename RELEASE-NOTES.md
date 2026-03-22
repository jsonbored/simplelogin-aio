# SimpleLogin-AIO Release Notes

**Repository:** `JSONbored/simplelogin-aio` & `JSONbored/unraid-templates`

## Overview
SimpleLogin is an open-source email alias service to protect your real email address. This release packages the official `simplelogin/app-ci` image with s6-overlay v3.1.6.2 to run the Web UI (Gunicorn), internal Email Handler (`email_handler.py`), and Background Jobs (`job_runner.py`) as a single, easily deployable All-in-One Unraid container. 

## Requirements
- `postgres-shared:5432` (or any PostgreSQL instance)
- `redis-shared:6380` (or any Redis instance)
- `SimpleLogin-Postfix` (MTA companion container to route inbound/outbound mail)

## Installation Order
1. Deploy PostgreSQL and Redis containers if not already running.
2. Deploy the `SimpleLogin-Postfix` container (ensure port 25 is mapped or a Relay Mode is configured).
3. Deploy the `SimpleLogin-AIO` container, linking it to the Database, Redis, and Postfix server.
4. Review the container logs for your auto-generated DKIM DNS TXT record and setup your domain's A, MX, SPF, DMARC, and DKIM records.

## Initial Release (2026-03-21)
- **Initial Release:** Created the complete Unraid Community Application XML template with 70+ natively exposed environment variables.
- **DKIM Generation:** Implemented automatic 1024-bit RSA DKIM key generation on first boot.
- **Relay Support:** `SimpleLogin-Postfix` fully configured to bypass ISP Port 25 blocking with ProtonMail, Brevo, Gmail, and Mailgun relay modes.
- **Idempotency:** Robust startup scripts ensuring safe database migrations and configuration bridging on every restart.