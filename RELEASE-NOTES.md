# Release Notes

## 2026-03-29

- Rebuilt `simplelogin-aio` around the official `simplelogin/app-ci` upstream release `v4.79.0`
- Embedded PostgreSQL, Redis, Postfix, SimpleLogin web, email handler, and background jobs into one supervised AIO container
- Added a real local smoke test with restart and persistence coverage
- Added upstream release tracking, pinned GitHub Actions SHAs, and dependency-review security checks
- Kept the Unraid install model focused on a single `/appdata` path plus optional `/pgp`
