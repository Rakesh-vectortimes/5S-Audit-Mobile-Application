# 5S Audit (Flutter)

Mobile app for field 5S audits, schedules, and action plans.
Talks to the same REST API as the web app: `{{BASE_URL}}/api/v1`.

## Phase status

| Phase | Scope | Status |
|-------|--------|--------|
| 0 | Scaffold, env, theme, routed shell | Done |
| 1 | Auth + Dio refresh + session restore | Done |
| 2 | Org deps + 5S config loaders | Done |
| 3 | Audit list + create/edit | **Done** |
| 4 | Schedules | **Done** |
| 5 | Action Plans | **Done** |
| — | Polish (export, remove org-dev) | **Done** |
| 6 | Admin settings (grades/types/sections/questions) | **Done** |

## Run

```bash
flutter pub get
flutter run
```

Prod env (placeholder URL until a real host is configured):

```bash
flutter run --dart-define=APP_ENV=prod
```

Set URLs in `.env.dev` / `.env.prod` (`API_BASE_URL`, `API_V1_BASE_URL`).
Dev defaults: `http://localhost:8000/api/v1`.

**Android emulator:** `localhost` is the emulator itself. Point `.env.dev` at
`http://10.0.2.2:8000/api/v1` to reach the host machine's backend.

**iOS simulator:** `localhost` / `127.0.0.1` works.

## Auth (Phase 1)

- Tokens in `flutter_secure_storage`
- Dio Bearer interceptor + single-flight refresh on 401
- Splash restores via `GET /auth/me`
- Logout from More (best-effort API + always clear local session)
## Structure

```
lib/
  core/           # config, network, router, theme, storage
  features/       # auth, home, audits, schedules, action_plans, more, org
  shared/         # cross-feature widgets
  main.dart
```

## Conventions

- Response envelope: `{ success, message, data }`
- Auth: Bearer `access_token`; refresh on 401 once
- UI status `submitted` ↔ API `published`
- Org: Company → Branch → Floor → Location
