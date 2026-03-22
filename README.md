# SimpleLogin-AIO

![Build Status](https://img.shields.io/github/actions/workflow/status/JSONbored/simplelogin-aio/build.yml?branch=main)
![License](https://img.shields.io/github/license/JSONbored/simplelogin-aio)
![Stars](https://img.shields.io/github/stars/JSONbored/simplelogin-aio)

SimpleLogin-AIO is an all-in-one, privacy-focused Unraid CA template package that provides a complete self-hosted email alias service. It replaces expensive SaaS alternatives like Proton Unlimited ($156/yr) by bringing SimpleLogin's alias generation, email forwarding, and DKIM signing capabilities directly to your homelab.

## Features
- **All-in-One Container:** Includes SimpleLogin's web UI, email handler, and job runner.
- **DKIM Signing:** Auto-generates RSA key pairs for DKIM, preventing your forwarded emails from being marked as spam.
- **Environment Management:** Simplifies setup by writing the `.env` file dynamically on first container start based on Unraid template variables.
- **Postgres-Backed:** Built to work with shared or dedicated Postgres instances for reliability.

## Quick Start
1. Add this template repository to your Unraid CA: `https://github.com/JSONbored/awesome-unraid`
2. Install `SimpleLogin-Postfix` as a relay if necessary.
3. Install `SimpleLogin-AIO`.
4. Configure required variables (DB, Domain, Flask Secret) via the Unraid web interface.
5. Setup DKIM TXT records in your DNS provider (Cloudflare recommended).

## Documentation & Support
- [Setup Guide](/docs/simplelogin-setup.md)
- [JSONbored Templates](https://github.com/JSONbored/awesome-unraid)

## License
MIT
