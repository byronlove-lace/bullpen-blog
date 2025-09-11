# Bullpen Blog — Minimal Flask Blog (API + Jinja frontend)

> Small, modular Flask blog application with a Jinja-rendered web UI and a companion REST API (blueprints under `app/api`).

This repository contains a teaching-style Flask project (inspired by *Flask Web Development*) that demonstrates: user accounts, roles & permissions, posts & comments, following, an API with token/basic auth, and migrations.

---

## Features

* Web UI using Flask + Jinja templates (routes under `app/main`).
* Styling with Bootstrap — templates include Bootstrap 3/4 classes and macros
  (via `bootstrap/wtf.html`) so forms and UI elements render with a clean,
  responsive design out of the box.
* REST API (blueprint `app/api`) for posts, users and comments with JSON responses.
* Authentication for API routes via HTTP Basic / token (Flask-HTTPAuth).
* Role-based permissions decorator (`permission_required`) for protected endpoints.
* Email support — `Flask-Mail` for sending messages and `email_validator` for form validation.
* Post/comment sanitization: Markdown -> safe HTML (Bleach + markdown).
* Pagination support for posts and timelines.
* Alembic migrations included for schema evolution.
* Tests folder with basic model tests.

---

## Quickstart — Development

These commands assume a POSIX shell (Linux/macOS). On Windows use PowerShell or WSL and adapt commands.

```bash
# create virtualenv
python3 -m venv venv
. venv/bin/activate

# install dependencies (dev includes testing)
pip install -r requirements/dev.txt

# set environment variables (example)
export FLASK_APP=flasky.py
export FLASK_ENV=development
export SECRET_KEY='change-this-to-a-secure-value'
export DATABASE_URL='sqlite:///data-dev.sqlite'

# initialize the database and run the dev server
flask db upgrade
flask run
```

The app should be available at `http://127.0.0.1:5000/`.

---

## Configuration

Configuration is read from `config.py` and environment variables. Common config options used in this project:

* `SECRET_KEY` — secret for signing tokens and forms.
* `DATABASE_URL` — SQLAlchemy database URI (defaults to SQLite during development).
* `FLASKY_POSTS_PER_PAGE` — pagination size for posts.
* `FLASKY_COMMENTS_PER_PAGE` — pagination size for comments.
* Mail settings (MAIL\_SERVER, MAIL\_PORT, MAIL\_USERNAME, MAIL\_PASSWORD) for email features.

You can use a `.env` file with a tool like `direnv` or `python-dotenv` in local dev, or export variables in your shell.

---

## Running tests

Tests live in the `tests/` directory and use `pytest`.

```bash
# run all tests
pytest -q
```

---

## API notes

The API blueprint is registered under `/api` (see `app/api/__init__.py`). API endpoints return JSON and API errors are converted to JSON responses (e.g. validation errors -> HTTP 400 with message).

**Auth model used by the API**

* Token and basic auth support are implemented; clients should send credentials or tokens with each request.

**Pagination**

* Many list endpoints accept a `page` query parameter and return `prev`/`next` links and a `count` field for client-side navigation.

---

## Project layout (important files)

```
app/                # application package
  api/              # API blueprint (authentication, posts, users, comments)
  auth/             # web authentication blueprint (forms, views)
  main/             # web blueprint (Jinja views)
  models.py         # SQLAlchemy models
  templates/        # Jinja templates for web UI
migrations/         # Alembic migrations
flasky.py           # app entry point (create_app() and run)
requirements/       # dependency lists (common, dev, prod)
```

---

## Dependencies & Installing Requirements

**Notes about integrated libraries**

* `Flask-HTTPAuth` is used for API Basic/Token auth.
* `Flask-Login` / session-based auth powers the site UI (if used).
* `Flask-Migrate` / Alembic handle DB migrations (see `migrations/`).
* `Flask-SQLAlchemy` + `SQLAlchemy` are the ORM layers. The pinned SQLAlchemy pair is compatible with Flask-SQLAlchemy v3.x.
* `Bleach` + `Markdown` sanitize/transform post content to safe HTML.
* `PyMySQL` is included for MySQL connectivity. If you prefer PostgreSQL, add `psycopg[binary]` to `requirements/prod.txt` and update `DATABASE_URL`.

**Python version**
Use a recent stable Python (3.10 or 3.11 recommended). The pinned packages target modern Python 3.10+ environments.

---

## License

This project is provided as-is for learning and demo purposes. Add your license file (e.g., MIT) if you want to publish.

---

## Contact / Credits

Inspired by Miguel Grinberg's Flask tutorial / Flask Web Development material. For questions, open an issue or reach out in PR comments.
