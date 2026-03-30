# Changelog

## Unreleased

- Replaced the legacy Docker build with a working SimpleLogin `v4.79.0` AIO image
- Embedded PostgreSQL, Redis, Postfix, the web process, the email handler, and the background job runner in one container
- Added first-boot database initialization, `.env` generation, and idempotent migration flow
- Added local smoke testing with restart and persistence coverage
- Hardened GitHub Actions with pinned SHAs, dependency review, and upstream release tracking
- Switched maintenance updates to PR-only Renovate
- Cleaned up the README, release notes, and Unraid XML metadata to match the actual container behavior
