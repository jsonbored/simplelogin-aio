# SimpleLogin Research
## Variables
- URL: The public URL of the SL instance (Required)
- EMAIL_DOMAIN: The domain used for aliases (Required)
- DB_URI: Postgres connection string (Required)
- FLASK_SECRET: Secret for signing cookies (Required, sensitive)
- POSTFIX_SERVER: The IP/hostname of the Postfix container (Required)
- REDIS_URL: Redis cache URL (Optional)

## Companion Services
- DB: PostgreSQL (use `postgres-shared:5432`)
- Cache: Redis (use `redis-shared:6380`)
- MTA: Postfix (use `simplelogin/postfix`)

## Ports
- 7777: Web UI (gunicorn)
- 20381: Email Handler
- 25: Postfix SMTP

## Volumes
- `/mnt/user/appdata/simplelogin/dkim`: Stores the DKIM keys
- `/mnt/user/appdata/simplelogin/gnupg`: Stores GPG keys
