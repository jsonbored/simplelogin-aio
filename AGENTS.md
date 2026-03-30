# simplelogin-aio Agent Notes

`simplelogin-aio` packages the SimpleLogin stack into one Unraid-friendly container.

## Runtime Shape

- SimpleLogin web app
- Background jobs
- Inbound email handler
- Postfix
- Internal PostgreSQL
- Internal Redis

## Important Behavior

- This is still a mail product, so the XML and docs must stay clear about required DNS and domain setup.
- Default mode should remain self-contained for app/runtime services, but users may still override `DB_URI` and `REDIS_URL`.
- `/appdata` is the main persistence volume.
- `/pgp` is optional and should stay an advanced path.
- Current upstream image support is `linux/amd64` only.

## CI And Publish Policy

- Validation and smoke tests should run on PRs and branch pushes.
- Publish should happen only from the default branch.
- GHCR image naming must stay lowercase.

## What To Preserve

- Keep beginner docs explicit about mail-routing reality; this is not a "just click once and receive internet mail" product.
- Smoke tests should validate initialization, restart, and persistence without pretending to fully simulate real DNS/mail delivery.
