# SimpleLogin Research (v2)

## 1. Upstream Documentation Status
- **example.env**: Successfully fetched from `https://raw.githubusercontent.com/simple-login/app/master/example.env`. Contains ~75 variables.
- **Self-Hosting Guide**: `docs/onboarding.md` returned a 404 Not Found. The primary self-hosting guide is actually in the main `README.md`.
- **Postfix Image**: Investigated `simplelogin/postfix` via its GitHub repo.

---

## 2. Exhaustive Environment Variable Documentation (from example.env)

### Core System
- `URL` (Required): The server URL. Example: `http://localhost:7777`.
- `FLASK_SECRET` (Required): Secret key used for signing cookies. Sensitive. Example: `secret`.
- `DB_URI` (Required): Postgres connection string. Sensitive. Example: `postgresql://myuser:mypassword@localhost:5432/simplelogin`.
- `WORDS_FILE_PATH` (Required/Defaulted): Path to the words file to generate random email aliases. Example: `local_data/test_words.txt`.
- `TEMP_DIR` (Optional): Directory for temp files. Default: `/tmp`.
- `NAMESERVERS` (Optional): DNS nameservers to be used by the app. Example: `1.1.1.1`.
- `PARTNER_API_TOKEN_SECRET` (Optional): Used for partner API tokens. Sensitive.

### Email Routing & Domains
- `EMAIL_DOMAIN` (Required): The primary domain used to create aliases. Example: `sl.lan`.
- `OTHER_ALIAS_DOMAINS` (Optional): Additional domains that can be used to create aliases. Example: `["domain1.com", "domain2.com"]`.
- `ALIAS_DOMAINS` (Optional): Domains that can be used to create aliases (overrides OTHER_ALIAS_DOMAINS). Example: `["domain1.com", "domain2.com"]`.
- `PREMIUM_ALIAS_DOMAINS` (Optional): Domains available only to premium accounts. Example: `["premium.com"]`.
- `FIRST_ALIAS_DOMAIN` (Optional): Domain used for the first alias created for a user. Defaults to `EMAIL_DOMAIN`.
- `SUPPORT_EMAIL` (Optional): Transactional emails are sent from this address. Example: `support@sl.lan`.
- `SUPPORT_NAME` (Optional): Name used for support emails. Example: `Son from SimpleLogin`.
- `ADMIN_EMAIL` (Optional): Receives general stats. Example: `admin@sl.lan`.
- `EMAIL_SERVERS_WITH_PRIORITY` (Optional): Custom domains need to point to these MX servers. Example: `[(10, "email.hostname.")]`.
- `POSTMASTER` (Optional): Postmaster email address. Example: `postmaster@example.com`.
- `ALLOWED_REDIRECT_DOMAINS` (Optional): Domains allowed in the `&next=` section for absolute URLs. Example: `[]`.

### Postfix & MTA Integration
- `POSTFIX_SERVER` (Optional): Address of another MTA to send email. By default uses the receiving Postfix server. Example: `my-postfix.com`.
- `POSTFIX_PORT` (Optional): Used to override the Postfix port (default 25) when developing locally. Example: `1025`.

### Security, Cryptography & Auth
- `DKIM_PRIVATE_KEY_PATH` (Optional/Required for Prod): Path to the DKIM private key for signing. Example: `local_data/dkim.key`.
- `GNUPGHOME` (Optional): Where to store the GPG Keyring. Example: `/tmp/gnupg`.
- `PGP_SENDER_PRIVATE_KEY_PATH` (Optional): Key used to sign forwarded emails. Example: `local_data/private-pgp.asc`.
- `OPENID_PRIVATE_KEY_PATH` (Optional): OpenID private key path. Example: `local_data/jwtRS256.key`.
- `OPENID_PUBLIC_KEY_PATH` (Optional): OpenID public key path. Example: `local_data/jwtRS256.key.pub`.
- `ENFORCE_SPF` (Optional): Enforces SPF using extra headers from Postfix. Example: `true`.
- `DISABLE_REGISTRATION` (Optional): Closes registration on self-hosted instances. Example: `1`.
- `HCAPTCHA_SECRET` (Optional): hCaptcha secret key. Sensitive.
- `HCAPTCHA_SITEKEY` (Optional): hCaptcha sitekey.

### Application Logic & Limits
- `MAX_NB_EMAIL_FREE_PLAN` (Optional): Max emails for free plan users. Default: `5`.
- `DISABLE_ALIAS_SUFFIX` (Optional): Disables the ".{random_word}" forced suffix (useful for self-hosting). Example: `1`.
- `ALIAS_LIMIT` (Optional): Frequency limit on alias creation. Example: `"100/day;50/hour;5/minute"`.
- `DISABLE_ONBOARDING` (Optional): Disables onboarding emails. Example: `true`.
- `NOT_SEND_EMAIL` (Optional): Only prints email content without sending (for local dev). Example: `true`.
- `ALIAS_AUTOMATIC_DISABLE` (Optional): Automatically disables aliases when triggered. Example: `true`.

### Bounce Processing (VERP)
- `BOUNCE_PREFIX` (Optional): Prefix for bounce emails. Example: `"bounces+"`.
- `BOUNCE_SUFFIX` (Optional): Suffix for bounce emails. Example: `"+@sl.lan"`.
- `BOUNCE_PREFIX_FOR_REPLY_PHASE` (Optional): Reply phase prefix. Example: `"bounce_reply"`.

### Third-Party Logins & OAuth
- **GitHub**: `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`
- **Google**: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- **Facebook**: `FACEBOOK_CLIENT_ID`, `FACEBOOK_CLIENT_SECRET`
- **Proton**: `PROTON_CLIENT_ID`, `PROTON_CLIENT_SECRET`, `PROTON_BASE_URL`, `PROTON_VALIDATE_CERTS`, `CONNECT_WITH_PROTON`, `CONNECT_WITH_PROTON_COOKIE_NAME`
- **Apple**: `APPLE_API_SECRET`, `MACAPP_APPLE_API_SECRET`
- **Generic OIDC**: `CONNECT_WITH_OIDC_ICON`, `OIDC_WELL_KNOWN_URL`, `OIDC_SCOPES`, `OIDC_NAME_FIELD`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`

### Spam Scanning
- `ENABLE_SPAM_ASSASSIN` (Optional): Enable scanning via SpamAssassin. Example: `1`.
- `SPAMASSASSIN_HOST` (Optional): Host IP. Example: `127.0.0.1`.

### Payments & Analytics (Mostly SaaS)
- **Paddle**: `PADDLE_VENDOR_ID`, `PADDLE_MONTHLY_PRODUCT_ID`, `PADDLE_YEARLY_PRODUCT_ID`, `PADDLE_PUBLIC_KEY_PATH`, `PADDLE_AUTH_CODE`
- **Coinbase**: `COINBASE_WEBHOOK_SECRET`, `COINBASE_CHECKOUT_ID`, `COINBASE_API_KEY`, `COINBASE_YEARLY_PRICE`
- **Plausible**: `PLAUSIBLE_HOST`, `PLAUSIBLE_DOMAIN`
- **Sentry**: `SENTRY_DSN`, `SENTRY_FRONT_END_DSN`
- **HIBP**: `HIBP_SCAN_INTERVAL_DAYS`, `HIBP_API_KEYS`

### Storage & Dev
- `BUCKET`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` (Optional): AWS S3 storage variables.
- `LOCAL_FILE_UPLOAD` (Optional): Use local `static/upload/` instead of S3. Example: `true`.
- `COLOR_LOG` (Optional): Colored terminal output. Example: `true`.
- `FLASK_PROFILER_PATH`, `FLASK_PROFILER_PASSWORD` (Optional): Flask profiling.
- `LANDING_PAGE_URL`, `STATUS_PAGE_URL` (Optional): Custom landing and status URLs.

---

## 3. Postfix Notes
The SimpleLogin Postfix image handles port 25 routing directly to the SimpleLogin container. As noted from its setup guides and the core app's `POSTFIX_SERVER` / `POSTFIX_PORT`, it works as a bridged lookup table to the Postgres database if directly connected, or through internal networking to route to port 20381 for the python `email_handler.py`.