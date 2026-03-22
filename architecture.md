# SimpleLogin Architecture
- App runs 3 processes:
  - web: `gunicorn --bind 0.0.0.0:7777 wsgi:app`
  - email: `python email_handler.py`
  - job: `rq worker -u $REDIS_URL`
- We use s6-overlay v3.1.6.2 to manage these.
- DKIM is auto-generated on first boot if missing.
- Migrations are run using `flask db upgrade`.
