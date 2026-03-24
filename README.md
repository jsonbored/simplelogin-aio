# SimpleLogin AIO (All-in-One) for Unraid
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/jsonbored/simplelogin-aio/latest)

An ultra-simplified, 100% self-contained deployment of [SimpleLogin](https://simplelogin.io) designed explicitly for Unraid homelabs. 

Instead of configuring 3 different templates, managing custom Docker networks, and bootstrapping external PostgreSQL/Redis databases, this image handles the entire stack internals for you. It's designed to provide a "Binhex-style" one-click installation experience for users who just want it to work.

## What's Inside?
This "Mega-Container" uses `s6-overlay` to gracefully orchestrate:
1. The SimpleLogin Python Web App
2. The SimpleLogin Background Job Worker (Celery)
3. The SimpleLogin Email Parser
4. **Postfix** (Mail routing) - *Pulled internally*
5. **PostgreSQL 14** - *Auto-provisioned internally*
6. **Redis** - *Auto-provisioned internally*

## Installation (For Beginners)
1. Add this repository to your Unraid Community Applications: `https://github.com/JSONbored/simplelogin-aio`
2. Install `SimpleLogin-AIO`. 
3. Fill out your `App URL` and `Email Domain`.
4. Pick an **SMTP Relay Provider** from the dropdown (to bypass residential Port 25 outbound blocking) and enter your credentials.
5. Click Apply. 

**That's it.** The container will silently generate a secure internal database, apply migrations, build your DKIM cryptography keys, and map everything persistently to your Unraid array under a single `/mnt/user/appdata/simplelogin-aio` folder.

## Power Users (External Databases)
If you already run a shared `postgres` or `redis` container on your Unraid box and don't want the overhead of the internal versions running, you can easily disable them!

Inside the Unraid Template, toggle the **Advanced View**. 
- Fill out the `Advanced: External DB_URI` variable with your remote Postgres string.
- Fill out the `Advanced: External Redis URL` variable.

If the initialization script detects those variables on startup, it will **completely skip** booting the internal PostgreSQL/Redis daemons and route traffic externally. 

## Documentation
- [Full Setup & DNS Configuration Guide](docs/simplelogin-setup.md)
