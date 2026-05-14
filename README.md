# SEADS — Smart Emergency Ambulance Dispatch System

A Flutter + Node.js platform that connects **patients**, **paramedics**, and **dispatchers** in real-time emergency situations.

---

## Architecture

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart), Riverpod, GoRouter |
| Auth | Firebase Authentication (Phone OTP) |
| Backend | Node.js + Express 5, deployed on Render |
| Database | Supabase (PostgreSQL + PostGIS) |
| Real-time | Supabase Realtime + WebSocket |
| Push | Firebase Cloud Messaging (FCM) |

---

## User Roles

- **Patient** — Requests emergency ambulance services
- **Paramedic** — Responds to emergency calls and tracks location
- **Dispatcher** — Manages and coordinates ambulance dispatch

---

## Project Structure

```
seads/
├── lib/
│   ├── main.dart                  # App entry point (Firebase init + Riverpod)
│   ├── router.dart                # GoRouter with auth guard + role-based routing
│   ├── config.dart                # Backend URL config
│   ├── providers/
│   │   └── auth_provider.dart     # Riverpod auth state + user role providers
│   ├── services/
│   │   ├── auth_service.dart      # Phone OTP login + profile API calls
│   │   └── api_service.dart       # Ambulance dispatch API (sends Firebase token)
│   └── screens/
│       ├── auth/
│       │   ├── login_screen.dart          # Phone + OTP two-step login
│       │   └── role_selection_screen.dart # Role picker (first login)
│       ├── patient/home_screen.dart
│       ├── paramedic/home_screen.dart
│       └── dispatcher/home_screen.dart
└── seads-backend/
    ├── index.js                   # Express server + /api/dispatch endpoint
    └── src/
        ├── config/
        │   ├── firebase.js        # Firebase Admin SDK initialisation
        │   └── supabase.js        # Shared Supabase client
        ├── routes/
        │   ├── auth.js            # POST /login, /register · GET /me
        │   └── users.js           # GET /:userId, POST /role, profile, contacts
        └── middleware/
            └── auth.js            # Firebase ID token verification middleware
```

**Backend repository:** The Node server shown as `seads-backend/` above is **not included in this Flutter-only repository clone**. Use your team’s backend repo (or Git submodule) alongside this app, or point the Flutter client at the deployed API via `AppConfig.backendUrl` in [`lib/config.dart`](lib/config.dart) (default Render URL, overridable with `--dart-define=BACKEND_URL=...`). For a local server, clone the backend next to this project and run it from that directory so `cd seads-backend` matches your layout.

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.6.2
- Node.js ≥ 18
- A Firebase project with Phone Auth enabled
- A Supabase project with PostGIS enabled

### Flutter Setup

```bash
flutter pub get
flutter run
```

To use a different backend base URL (local or staging), pass a compile-time define (see [`lib/config.dart`](lib/config.dart)):

```bash
flutter run --dart-define=BACKEND_URL=http://127.0.0.1:3000
```

### Backend Setup

Requires a checkout of the backend project (see **Backend repository** above). From that directory:

```bash
cd seads-backend
cp .env.example .env   # fill in your env vars
npm install
npm run dev            # development (nodemon)
npm start              # production
```

### Required Environment Variables (Backend)

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_KEY` | Supabase service role key |
| `JWT_SECRET` | Legacy — kept for `/api/auth` custom JWT routes |
| `PORT` | Server port (defaults to 3000) |
| `ALLOWED_ORIGIN` | CORS allowed origin (defaults to `*`) |
| `FIREBASE_SERVICE_ACCOUNT_BASE64` | Base64-encoded Firebase service account JSON. Generate with: `base64 -i serviceAccountKey.json \| tr -d '\n'` |

### Supabase Migration

Run the migration in `supabase-migration.sql` against your Supabase project to add the `firebase_uid` and `fcm_token` columns to the `users` table.

---

## API Reference

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/login` | None | Login with phone + firebase_uid |
| POST | `/api/auth/register` | None | Register new user |
| GET | `/api/auth/me` | JWT | Get current user |
| GET | `/api/users/:userId` | None | Get user by Firebase UID |
| POST | `/api/users/role` | None | Save user role (first login) |
| PUT | `/api/users/profile` | JWT | Update profile fields |
| POST | `/api/users/fcm-token` | JWT | Save FCM push token |
| GET | `/api/users/contacts` | JWT | List emergency contacts |
| POST | `/api/users/contacts` | JWT | Add emergency contact |
| DELETE | `/api/users/contacts/:id` | JWT | Remove emergency contact |
| POST | `/api/dispatch` | JWT | Dispatch nearest ambulance |
| GET | `/` | None | Health check |

---

## Known Limitations / Roadmap

- [x] **Auth token mismatch:** Backend currently uses custom JWTs; Flutter sends Firebase ID tokens. Plan to wire up `firebase-admin` for Firebase ID token verification.
- [ ] **Patient screen:** Implement live ambulance request with GPS via `geolocator`
- [ ] **Paramedic screen:** Real-time assignment feed via Supabase Realtime
- [ ] **Dispatcher screen:** Live incident list + map (`flutter_map`)
- [ ] **Background tracking:** Wire up `flutter_background_service` for paramedic location
- [ ] **Offline cache:** Initialize `hive_flutter` for offline-first data
- [x] **Rate limiting:** Add `express-rate-limit` to auth routes
- [x] **Input validation:** Add `zod` schema validation to all backend routes
