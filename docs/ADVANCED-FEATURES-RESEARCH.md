
# SimpleLogin Advanced Features Research

This document outlines advanced features, environment variables, and configurations for a self-hosted SimpleLogin instance.

## 1. Anti-Spam & Security

### SpamAssassin Integration
- **Description:** SimpleLogin can integrate with SpamAssassin to scan incoming emails for spam.
- **Environment Variables:**
    - `ENABLE_SPAM_ASSASSIN`: Set to `1` to enable this feature.
    - `SPAMASSASSIN_HOST`: The hostname or IP address of the SpamAssassin server (e.g., `127.0.0.1`).
- **Relevant Code:** `app/spamassassin_utils.py`

### PGP/GPG Email Encryption
- **Description:** SimpleLogin supports PGP/GPG to encrypt emails.
- **Environment Variables:**
    - `GNUPGHOME`: The directory where GPG keyrings are stored (e.g., `/tmp/gnupg`).
    - `PGP_SENDER_PRIVATE_KEY_PATH`: Path to the private key used for signing forwarding emails (e.g., `local_data/private-pgp.asc`).
- **Relevant Code:** `app/pgp_utils.py`

### Rate Limiting
- **Description:** Mitigate abuse by setting limits on alias creation.
- **Environment Variables:**
    - `ALIAS_LIMIT`: A string that defines the creation rate limits. Example: `"100/day;50/hour;5/minute"`.
- **Relevant Code:** `app/rate_limiter.py`

### hCaptcha
- **Description:** Protect registration and login forms with hCaptcha.
- **Environment Variables:**
    - `HCAPTCHA_SECRET`: Your hCaptcha secret key.
    - `HCAPTCHA_SITEKEY`: Your hCaptcha site key.

### Other Security Features
- **SPF Enforcement:**
    - `ENFORCE_SPF=true`: Enforces SPF checks using headers from Postfix.
- **Alias Suffix:**
    - `DISABLE_ALIAS_SUFFIX=1`: Disables the default requirement for a random word suffix on new aliases. Useful for self-hosted instances.
- **Allowed Redirects:**
    - `ALLOWED_REDIRECT_DOMAINS`: A list of domains that are allowed in the `&next=` parameter for redirects.

## 2. Integrations & SSO

### OpenID Connect (OIDC)
- **Description:** Allow users to log in using any OIDC-compliant provider.
- **Environment Variables:**
    - `CONNECT_WITH_OIDC_ICON`: The icon to display for the OIDC login button (e.g., `fa-github`).
    - `OIDC_WELL_KNOWN_URL`: The URL to the OIDC provider's well-known configuration endpoint.
    - `OIDC_SCOPES`: The OIDC scopes to request (e.g., `openid email profile`).
    - `OIDC_NAME_FIELD`: The field in the OIDC user info response to use for the user's name (e.g., `name`).
    - `OIDC_CLIENT_ID`: The OIDC client ID.
    - `OIDC_CLIENT_SECRET`: The OIDC client secret.
- **Relevant Code:** `app/auth/views/oidc.py`

### OAuth (GitHub, Google, Facebook, Proton)
- **Description:** Enable social logins with popular providers.
- **Environment Variables:**
    - `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET`
    - `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`
    - `FACEBOOK_CLIENT_ID` / `FACEBOOK_CLIENT_SECRET`
    - `PROTON_CLIENT_ID` / `PROTON_CLIENT_SECRET`
    - `PROTON_BASE_URL`
    - `PROTON_VALIDATE_CERTS`
    - `CONNECT_WITH_PROTON`
    - `CONNECT_WITH_PROTON_COOKIE_NAME`
- **Relevant Code:** `app/auth/views/`

### Plausible Analytics
- **Description:** Integrate with the privacy-friendly Plausible Analytics.
- **Environment Variables:**
    - `PLAUSIBLE_HOST`: The URL of your Plausible instance.
    - `PLAUSIBLE_DOMAIN`: The domain you want to track.

### Sentry
- **Description:** Track errors and monitor application health with Sentry.
- **Environment Variables:**
    - `SENTRY_DSN`: The DSN for your Sentry project.
    - `SENTRY_FRONT_END_DSN`: An optional, separate DSN for front-end error tracking.

## 3. Performance

### Gunicorn & Celery
- **Description:** While not directly in `example.env`, Gunicorn and Celery are used for running the web server and background tasks, respectively. Their configurations are typically found in the `Dockerfile` or startup scripts.
- **Tuning:** To tune performance, you would typically adjust the number of Gunicorn workers (`-w` flag) or Celery worker concurrency. These settings would need to be exposed in the Docker container's entrypoint or command.

### Flask Profiler
- **Description:** A built-in profiler to identify performance bottlenecks.
- **Environment Variables:**
    - `FLASK_PROFILER_PATH`: The path to store the profiler's output (e.g., `/tmp/flask-profiler.sql`).
    - `FLASK_PROFILER_PASSWORD`: A password to protect the profiler's output.

## 4. Storage

### AWS S3 vs. Local Storage
- **Description:** SimpleLogin can store file uploads (like attachments) on either AWS S3 or the local filesystem.
- **Environment Variables:**
    - `LOCAL_FILE_UPLOAD=true`: Set this to `true` to use local storage. By default, S3 is used.
    - For S3, the following variables are required:
        - `BUCKET`: The name of your S3 bucket.
        - `AWS_ACCESS_KEY_ID`: Your AWS access key ID.
        - `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key.
        - `AWS_REGION`: The AWS region of your bucket.
- **Relevant Code:** `app/s3.py`

## Recommendations for Unraid Template "Advanced View"

The following features would be beneficial to expose in an Unraid template's "Advanced View" to give users more control over their self-hosted SimpleLogin instance:

- **SpamAssassin Integration:**
    - `ENABLE_SPAM_ASSASSIN` (as a boolean toggle)
    - `SPAMASSASSIN_HOST` (as a text field)
- **PGP/GPG Encryption:**
    - `GNUPGHOME`
    - `PGP_SENDER_PRIVATE_KEY_PATH`
- **Rate Limiting:**
    - `ALIAS_LIMIT` (as a text field, with the default value pre-filled)
- **hCaptcha:**
    - `HCAPTCHA_SECRET`
    - `HCAPTCHA_SITEKEY`
- **Social Logins (OAuth/OIDC):**
    - Provide sections for each provider (GitHub, Google, OIDC, etc.) with the relevant client ID and secret fields.
- **Storage:**
    - A choice between "Local" and "S3".
    - If "S3" is chosen, show the fields for `BUCKET`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_REGION`.
- **Gunicorn/Celery Workers:**
    - Exposing `GUNICORN_WORKERS` and `CELERY_WORKERS` variables would allow users to tune performance based on their server's resources. These would need to be implemented in the Dockerfile/entrypoint script.
