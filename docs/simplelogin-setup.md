# SimpleLogin AIO Setup Guide

This guide covers the minimum pieces required to make `simplelogin-aio` work on Unraid.

## 1. Pick Your Hostnames

You normally want:

- `app.example.com` for the web UI
- `mail.example.com` for inbound SMTP delivery

Set the Unraid template like this:

- `URL=https://app.example.com`
- `EMAIL_DOMAIN=example.com`
- `SUPPORT_EMAIL=support@example.com`

## 2. Add DNS Records

At minimum, add:

- `A` or `AAAA` record for `app.example.com`
- `A` or `AAAA` record for `mail.example.com`
- `MX` record for `example.com` pointing to `mail.example.com`
- SPF TXT record on `example.com`
- DMARC TXT record on `_dmarc.example.com`

SimpleLogin will also need DKIM once the container has booted and generated its keys.

## 3. Forward Mail Traffic

Inbound internet mail must reach the Unraid host:

- forward TCP port `25` from your router/firewall to the Unraid server

If your ISP blocks outbound port `25`, choose a relay provider in the template:

- `brevo`
- `protonmail`
- `gmail`
- `mailgun`
- `custom`

If your ISP does not block outbound mail, `direct` can work.

## 4. Start the Container

On first boot the container will:

- initialize PostgreSQL if `DB_URI` is not set
- start Redis if `REDIS_URL` is not set
- write the runtime `.env`
- configure Postfix
- apply `alembic upgrade head`
- run `init_app.py` once

The first start can take longer than a normal restart because the internal database is being prepared.

## 5. Confirm It Is Healthy

After the container comes up:

- open the web UI on port `7777`
- confirm `/health` responds
- check the logs for any Postfix relay or DNS warnings
- check `/appdata/sl` and `/appdata/postgres` were populated

## 6. Advanced Overrides

You can point the container at external services:

- set `DB_URI` to skip the internal PostgreSQL daemon
- set `REDIS_URL` to skip the internal Redis daemon

This keeps the Unraid template flexible without forcing beginners into a multi-container setup.
