<div align="center">

# SimpleLogin AIO (All-in-One) for Unraid

[![Docker Image Size](https://img.shields.io/docker/image-size/jsonbored/simplelogin-aio/latest?color=blue&label=Image%20Size)](https://github.com/JSONbored/simplelogin-aio/pkgs/container/simplelogin-aio)
[![GitHub License](https://img.shields.io/github/license/JSONbored/simplelogin-aio?color=green)](https://github.com/JSONbored/simplelogin-aio/blob/main/LICENSE)
[![Unraid Community Applications](https://img.shields.io/badge/Unraid-CA%20Template-orange)](https://unraid.net/community/apps)

An ultra-simplified, 100% self-contained deployment of [SimpleLogin](https://simplelogin.io) designed explicitly for Unraid homelabs.

</div>

---

Instead of configuring 3 different templates, managing custom Docker networks, and bootstrapping external PostgreSQL/Redis databases, this image handles the entire stack internals for you. It's designed to provide a "Binhex-style" one-click installation experience for users who just want it to work.

## 📦 What's Inside the "Mega-Container"
This image uses `s6-overlay` to gracefully orchestrate the entire self-hosted alias ecosystem invisibly:
- 🌐 **The Web UI:** SimpleLogin's Python-based dashboard.
- ⚙️ **The Task Runner:** SimpleLogin Background Job Worker (Celery).
- 📧 **The MTA Router:** **Postfix** is built-in to route inbound/outbound mail instantly.
- 🗄️ **The Database:** **PostgreSQL 14** is auto-provisioned securely internally.
- ⚡ **The Cache:** **Redis** is auto-provisioned for rapid background queuing.

## 🚀 Installation (For Beginners)
1. Add this repository to your Unraid Community Applications: `https://github.com/JSONbored/simplelogin-aio`
2. Search and Install **SimpleLogin-AIO**.
3. Fill out your `App URL` and `Email Domain`.
4. Pick an **SMTP Relay Provider** from the dropdown (to bypass residential Port 25 outbound blocking) and enter your credentials.
5. Click **Apply**. 

**That's it.** The container will silently generate a secure internal database, apply migrations, build your DKIM cryptography keys, and map everything persistently to your array under a single `/mnt/user/appdata/simplelogin-aio` folder.

## 🛠️ Power Users (External Databases)
If you already run a shared `postgres` or `redis` container on your Unraid box and don't want the overhead of the internal versions running, you can easily disable them!

Inside the Unraid Template, toggle the **Advanced View**. 
- Fill out the `Advanced: External DB_URI` variable with your remote Postgres string.
- Fill out the `Advanced: External Redis URL` variable.

If the initialization script detects those variables on startup, it will **completely skip** booting the internal PostgreSQL/Redis daemons and route traffic externally. 

## 🛡️ Advanced Features (Self-Hosted Maximalists)
This template exposes advanced variables to integrate with your existing ecosystem. Toggle "Advanced View" in Unraid to configure:
- **SSO / Identity:** Integrate directly with [Tailscale IDP (`tsidp`)](https://tailscale.com), Authelia, or Authentik via the generic OIDC variables.
- **Anti-Spam:** Offload scanning to a separate `SpamAssassin` container by linking its IP.
- **Telemetry:** Point error tracking and analytics to your own self-hosted `Sentry` and `Plausible` instances.
- **PGP Encryption:** Mount your own keyring to encrypt emails locally before they leave the server.

For a full breakdown of these capabilities, read the [Advanced Features Documentation](docs/ADVANCED-FEATURES-RESEARCH.md).

## 📚 Documentation & Setup
- [Full Setup & DNS Configuration Guide](docs/simplelogin-setup.md)

---

<div align="center">

### Star History
[![Star History Chart](https://api.star-history.com/svg?repos=JSONbored/simplelogin-aio&type=Date)](https://star-history.com/#JSONbored/simplelogin-aio&Date)

</div>
