# SimpleLogin Variable Research (v3)

This document contains a comprehensive analysis of every single environment variable found in the upstream `example.env` file. These variables will be used to construct the Docker run scripts and Unraid XML template.

## Core Application Settings

### `URL`
- **Purpose**: The public-facing server URL for the SimpleLogin web interface.
- **Required/Optional**: Required
- **Default**: `http://localhost:7777`
- **Sensitive**: No
- **Display**: Always

### `FLASK_SECRET`
- **Purpose**: Cryptographic secret used by Flask to sign session cookies.
- **Required/Optional**: Required
- **Default**: `secret`
- **Sensitive**: Yes
- **Display**: Always

### `DB_URI`
- **Purpose**: Connection string for the PostgreSQL database.
- **Required/Optional**: Required
- **Default**: `postgresql://myuser:mypassword@localhost:5432/simplelogin`
- **Sensitive**: Yes
- **Display**: Always

### `WORDS_FILE_PATH`
- **Purpose**: Path to the text file containing words used to generate random email aliases.
- **Required/Optional**: Optional (Defaults if omitted, but explicit path often needed in Docker)
- **Default**: `local_data/test_words.txt`
- **Sensitive**: No
- **Display**: Advanced

### `TEMP_DIR`
- **Purpose**: Temporary directory used by the application for processing.
- **Required/Optional**: Optional
- **Default**: `/tmp`
- **Sensitive**: No
- **Display**: Advanced

## Email & Domain Configuration

### `EMAIL_DOMAIN`
- **Purpose**: The primary domain used to create aliases.
- **Required/Optional**: Required
- **Default**: `sl.lan`
- **Sensitive**: No
- **Display**: Always

### `OTHER_ALIAS_DOMAINS`
- **Purpose**: List of additional domains that can be used to create aliases, appending to `EMAIL_DOMAIN`.
- **Required/Optional**: Optional
- **Default**: `["domain1.com", "domain2.com"]`
- **Sensitive**: No
- **Display**: Advanced

### `ALIAS_DOMAINS`
- **Purpose**: Strict list of domains that can be used to create aliases (overrides `OTHER_ALIAS_DOMAINS`).
- **Required/Optional**: Optional
- **Default**: `["domain1.com", "domain2.com"]`
- **Sensitive**: No
- **Display**: Advanced

### `PREMIUM_ALIAS_DOMAINS`
- **Purpose**: List of domains reserved strictly for premium accounts.
- **Required/Optional**: Optional
- **Default**: `["premium.com"]`
- **Sensitive**: No
- **Display**: Advanced

### `FIRST_ALIAS_DOMAIN`
- **Purpose**: The specific alias domain used when automatically creating the first alias for a new user.
- **Required/Optional**: Optional
- **Default**: Fallbacks to `EMAIL_DOMAIN`
- **Sensitive**: No
- **Display**: Advanced

### `SUPPORT_EMAIL`
- **Purpose**: The address from which transactional system emails are sent.
- **Required/Optional**: Required
- **Default**: `support@sl.lan`
- **Sensitive**: No
- **Display**: Always

### `SUPPORT_NAME`
- **Purpose**: The display name used for transactional system emails.
- **Required/Optional**: Optional
- **Default**: `Son from SimpleLogin`
- **Sensitive**: No
- **Display**: Advanced

### `ADMIN_EMAIL`
- **Purpose**: The email address designated to receive general system statistics and alerts.
- **Required/Optional**: Optional
- **Default**: `admin@sl.lan`
- **Sensitive**: No
- **Display**: Always

### `POSTMASTER`
- **Purpose**: The official postmaster email address for the server.
- **Required/Optional**: Optional
- **Default**: `postmaster@example.com`
- **Sensitive**: No
- **Display**: Advanced

### `EMAIL_SERVERS_WITH_PRIORITY`
- **Purpose**: Defines the MX servers that custom domains must point to for validation.
- **Required/Optional**: Optional
- **Default**: `[(10, "email.hostname.")]`
- **Sensitive**: No
- **Display**: Advanced

## Postfix & MTA Settings

### `POSTFIX_SERVER`
- **Purpose**: The hostname or IP of the MTA (Postfix) server used to send outbound emails. By default, SimpleLogin assumes it's sending via the same server receiving emails.
- **Required/Optional**: Required (For split-container setups)
- **Default**: `my-postfix.com`
- **Sensitive**: No
- **Display**: Always

### `POSTFIX_PORT`
- **Purpose**: The port used to communicate with the outbound Postfix server.
- **Required/Optional**: Optional
- **Default**: `1025`
- **Sensitive**: No
- **Display**: Advanced

## Application Logic & Features

### `DISABLE_REGISTRATION`
- **Purpose**: Prevents new users from creating accounts. Essential for private self-hosted instances.
- **Required/Optional**: Optional
- **Default**: `1`
- **Sensitive**: No
- **Display**: Always

### `DISABLE_ALIAS_SUFFIX`
- **Purpose**: Disables the forced `.{random_word}` suffix on new aliases. Highly recommended for self-hosting.
- **Required/Optional**: Optional
- **Default**: `1`
- **Sensitive**: No
- **Display**: Always

### `MAX_NB_EMAIL_FREE_PLAN`
- **Purpose**: The maximum number of aliases a free tier user can generate.
- **Required/Optional**: Optional
- **Default**: `5`
- **Sensitive**: No
- **Display**: Advanced

### `ALIAS_LIMIT`
- **Purpose**: Rate limiting for alias creation to prevent abuse.
- **Required/Optional**: Optional
- **Default**: `"100/day;50/hour;5/minute"`
- **Sensitive**: No
- **Display**: Advanced

### `ALIAS_AUTOMATIC_DISABLE`
- **Purpose**: Toggles whether aliases are automatically disabled under certain conditions (like excessive bounces).
- **Required/Optional**: Optional
- **Default**: `true`
- **Sensitive**: No
- **Display**: Advanced

### `DISABLE_ONBOARDING`
- **Purpose**: Disables the series of onboarding emails sent to new users.
- **Required/Optional**: Optional
- **Default**: `true`
- **Sensitive**: No
- **Display**: Advanced

## Cryptography & Security

### `DKIM_PRIVATE_KEY_PATH`
- **Purpose**: The file path to the DKIM private key used to compute DKIM-Signatures for outbound emails.
- **Required/Optional**: Required (For production mail delivery)
- **Default**: `local_data/dkim.key`
- **Sensitive**: No (It's a path, not the key itself)
- **Display**: Advanced

### `GNUPGHOME`
- **Purpose**: Directory path where the GPG Keyring is stored.
- **Required/Optional**: Optional
- **Default**: `/tmp/gnupg`
- **Sensitive**: No
- **Display**: Advanced

### `PGP_SENDER_PRIVATE_KEY_PATH`
- **Purpose**: Path to the private key used to sign forwarded emails.
- **Required/Optional**: Optional
- **Default**: `local_data/private-pgp.asc`
- **Sensitive**: No
- **Display**: Advanced

### `ENFORCE_SPF`
- **Purpose**: Allows SimpleLogin to enforce SPF checks using extra headers appended by Postfix.
- **Required/Optional**: Optional
- **Default**: `true`
- **Sensitive**: No
- **Display**: Advanced

## Spam & Reputation

### `ENABLE_SPAM_ASSASSIN`
- **Purpose**: Toggles inbound spam scanning using SpamAssassin.
- **Required/Optional**: Optional
- **Default**: `1`
- **Sensitive**: No
- **Display**: Advanced

### `SPAMASSASSIN_HOST`
- **Purpose**: The IP address or hostname of the SpamAssassin server.
- **Required/Optional**: Optional
- **Default**: `127.0.0.1`
- **Sensitive**: No
- **Display**: Advanced

## Bounce Processing (VERP)

### `BOUNCE_PREFIX`
- **Purpose**: The prefix added to the return-path for handling bounces. Must end with `+`.
- **Required/Optional**: Optional
- **Default**: `"bounces+"`
- **Sensitive**: No
- **Display**: Advanced

### `BOUNCE_SUFFIX`
- **Purpose**: The suffix added to the return-path for handling bounces. Must start with `+`.
- **Required/Optional**: Optional
- **Default**: `"+@sl.lan"`
- **Sensitive**: No
- **Display**: Advanced

### `BOUNCE_PREFIX_FOR_REPLY_PHASE`
- **Purpose**: Prefix used specifically during the reply phase. Does not include a trailing `+`.
- **Required/Optional**: Optional
- **Default**: `"bounce_reply"`
- **Sensitive**: No
- **Display**: Advanced

## System, DNS, & Network

### `NAMESERVERS`
- **Purpose**: Comma-separated list of DNS nameservers for the app to use directly.
- **Required/Optional**: Optional
- **Default**: `"1.1.1.1"`
- **Sensitive**: No
- **Display**: Advanced

### `ALLOWED_REDIRECT_DOMAINS`
- **Purpose**: List of domains permitted in the `&next=` parameter for absolute URL redirects, preventing open redirect vulnerabilities.
- **Required/Optional**: Optional
- **Default**: `[]`
- **Sensitive**: No
- **Display**: Advanced

### `LOCAL_FILE_UPLOAD`
- **Purpose**: Instructs the app to upload files to the local `static/upload/` directory instead of an S3 bucket.
- **Required/Optional**: Optional
- **Default**: `true`
- **Sensitive**: No
- **Display**: Advanced

## Third-Party Authentication & Integrations

### GitHub
- `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET`: Credentials for GitHub OAuth login. (Optional, Sensitive, Advanced)

### Google
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`: Credentials for Google OAuth login. (Optional, Sensitive, Advanced)

### Facebook
- `FACEBOOK_CLIENT_ID` / `FACEBOOK_CLIENT_SECRET`: Credentials for Facebook OAuth login. (Optional, Sensitive, Advanced)

### Proton
- `PROTON_CLIENT_ID` / `PROTON_CLIENT_SECRET`: Credentials for Proton login. (Optional, Sensitive, Advanced)
- `PROTON_BASE_URL` / `PROTON_VALIDATE_CERTS` / `CONNECT_WITH_PROTON` / `CONNECT_WITH_PROTON_COOKIE_NAME`: Configuration flags for Proton integration. (Optional, Advanced)

### Generic OIDC
- `OIDC_CLIENT_ID` / `OIDC_CLIENT_SECRET` / `OIDC_WELL_KNOWN_URL` / `OIDC_SCOPES` / `OIDC_NAME_FIELD` / `CONNECT_WITH_OIDC_ICON`: Full OpenID Connect integration settings. (Optional, Sensitive, Advanced)

### Apple
- `APPLE_API_SECRET` / `MACAPP_APPLE_API_SECRET`: Secrets for querying the Apple API. (Optional, Sensitive, Advanced)

## SaaS / Commercial Features (Mostly ignored for self-hosted)

### AWS S3
- `BUCKET`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`: Overrides `LOCAL_FILE_UPLOAD` to push assets to S3. (Optional, Sensitive, Advanced)

### Paddle (Billing)
- `PADDLE_VENDOR_ID`, `PADDLE_MONTHLY_PRODUCT_ID`, `PADDLE_YEARLY_PRODUCT_ID`, `PADDLE_PUBLIC_KEY_PATH`, `PADDLE_AUTH_CODE`: Settings for subscription management. (Optional, Sensitive, Advanced)

### Coinbase (Crypto Payments)
- `COINBASE_WEBHOOK_SECRET`, `COINBASE_CHECKOUT_ID`, `COINBASE_API_KEY`, `COINBASE_YEARLY_PRICE`: Crypto payment integration. (Optional, Sensitive, Advanced)

### Plausible Analytics
- `PLAUSIBLE_HOST`, `PLAUSIBLE_DOMAIN`: Settings for privacy-friendly analytics. (Optional, Advanced)

### Have I Been Pwned
- `HIBP_SCAN_INTERVAL_DAYS`, `HIBP_API_KEYS`: Interval and keys for scanning aliases against data breaches. (Optional, Sensitive, Advanced)

### Sentry
- `SENTRY_DSN`, `SENTRY_FRONT_END_DSN`: Error tracking endpoint URLs. (Optional, Sensitive, Advanced)

### Flask Profiler
- `FLASK_PROFILER_PATH`, `FLASK_PROFILER_PASSWORD`: Performance profiling settings. (Optional, Sensitive, Advanced)

## Miscellaneous

### `COLOR_LOG`
- **Purpose**: Applies colored logging formatting, useful for local development and Docker log tailing.
- **Required/Optional**: Optional
- **Default**: `true`
- **Sensitive**: No
- **Display**: Advanced

### `NOT_SEND_EMAIL`
- **Purpose**: Prevents email sending, instead printing the content to standard output. Used for debugging.
- **Required/Optional**: Optional
- **Default**: `true`
- **Sensitive**: No
- **Display**: Advanced

### `LANDING_PAGE_URL` / `STATUS_PAGE_URL`
- **Purpose**: Custom URLs for the landing and status pages.
- **Required/Optional**: Optional
- **Default**: `https://simplelogin.io` / `https://status.simplelogin.io`
- **Sensitive**: No
- **Display**: Advanced

### `PARTNER_API_TOKEN_SECRET`
- **Purpose**: Secret token for partner API integrations.
- **Required/Optional**: Optional
- **Default**: `changeme`
- **Sensitive**: Yes
- **Display**: Advanced

### `OPENID_PRIVATE_KEY_PATH` / `OPENID_PUBLIC_KEY_PATH`
- **Purpose**: Paths to OpenID keys used when SimpleLogin acts as an identity provider.
- **Required/Optional**: Optional
- **Default**: `local_data/jwtRS256.key`
- **Sensitive**: No (path)
- **Display**: Advanced