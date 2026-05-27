# SEADS — Smart Emergency Ambulance Dispatch System

A Flutter + Node.js platform that connects **patients**, **paramedics**, and **dispatchers** in real-time emergency situations.

---

## Architecture

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart), Riverpod, GoRouter |
| Auth | Firebase Authentication (email/password) |
| Backend | Node.js 20 + Express 5 — `seads-backend/` |
| Database | Supabase (PostgreSQL + PostGIS) |
| Real-time | Supabase Realtime + adaptive polling |
| Push | Firebase Cloud Messaging (FCM) |
| Hosting | Render (backend web service) |

The backend lives **inside this repo** at `seads-backend/` and is deployed to Render via `render.yaml`.

---

## User Roles

- **Patient** — Requests emergency ambulance services
- **Paramedic** — Responds to emergency calls and tracks location
- **Dispatcher** — Manages and coordinates ambulance dispatch

---

## Project Structure

```
seads/
├── render.yaml                    # Render deployment config (points to seads-backend/)
├── supabase-migration.sql         # Full DB schema — run once in Supabase SQL Editor
├── scripts/
│   └── dev.sh                     # Local dev launcher
├── lib/
│   ├── main.dart                  # App entry point (Firebase init + Riverpod)
│   ├── router.dart                # GoRouter with auth guard + role-based routing
│   ├── config.dart                # Backend URL config (BACKEND_URL dart-define)
│   ├── providers/
│   │   └── auth_provider.dart     # Riverpod auth state + user role providers
│   ├── services/
│   │   ├── auth_service.dart      # Email/password login + profile API calls
│   │   └── api_service.dart       # Full API client (all endpoints)
│   └── screens/
│       ├── auth/                  # Welcome, Login, Signup, Role selection, Onboarding
│       ├── patient/               # Home (SOS), History, Contacts, Medical profile
│       ├── paramedic/             # Home, Assignments, Equipment, Shifts, Stats
│       ├── dispatcher/            # Home, Fleet, Incidents, Staff, Analytics
│       └── shared/                # Settings, Help
└── seads-backend/
    ├── index.js                   # Express 5 server entry point
    ├── package.json
    ├── .env.example               # Environment variable template
    └── src/
        ├── config/
        │   ├── db.js              # pg.Pool → Supabase PostgreSQL
        │   └── firebase.js        # Firebase Admin SDK init
        ├── middleware/
        │   ├── auth.js            # Firebase ID token verification → req.uid
        │   └── validate.js        # Zod schema validation middleware
        ├── routes/
        │   ├── auth.js            # POST /api/auth/register|login  GET /api/auth/me
        │   ├── users.js           # GET|PUT /api/users/:id  POST /api/users/role|fcm-token
        │   ├── patients.js        # POST /api/dispatch  /api/patients/*
        │   ├── paramedics.js      # /api/incidents  /api/paramedics/*  /api/ambulances/location
        │   └── dispatchers.js     # /api/ambulances  /api/dispatchers/*
        └── utils/
            ├── fcm.js             # FCM push helper (firebase-admin messaging)
            └── seed.js            # Demo data seed (ambulances + equipment + shifts)
```

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.6.2
- Node.js ≥ 20
- A Firebase project with Email/Password Auth enabled + a service account key
- A Supabase project with PostGIS enabled

### 1 — Database Setup (Supabase)

Run the migration **once** in your Supabase project:

> Supabase Dashboard → SQL Editor → paste `supabase-migration.sql` → Run

This creates all tables (`users`, `ambulances`, `incidents`, `emergency_contacts`, `medical_profiles`, `equipment_items`, `shifts`, `shift_swap_requests`) with PostGIS geography columns and indexes.

### 2 — Backend Setup (local dev)

```bash
cp seads-backend/.env.example seads-backend/.env
# Fill in DATABASE_URL and FIREBASE_SERVICE_ACCOUNT_BASE64
bash scripts/dev.sh
```

Get your Supabase `DATABASE_URL` from:
> Supabase Dashboard → Settings → Database → Connection string → URI (Session mode, port 5432)

Generate `FIREBASE_SERVICE_ACCOUNT_BASE64`:
```bash
base64 -i serviceAccountKey.json | tr -d '\n'
```

Seed demo ambulances + equipment:
```bash
cd seads-backend && npm run seed
```

### 3 — Flutter Setup

```bash
flutter pub get

# Android emulator (default — no dart-define needed)
flutter run

# Physical device (replace with your machine's LAN IP)
flutter run --dart-define=BACKEND_URL=http://192.168.1.x:3000

# Against deployed Render backend
flutter run --dart-define=BACKEND_URL=https://seads-backend.onrender.com
```

---

## Deploying to Render

1. Push this repo to GitHub.
2. In the [Render dashboard](https://dashboard.render.com), create a **New Web Service** → connect your repo.
3. Render will auto-detect `render.yaml` — confirm the service settings.
4. Set the following **Environment Variables** in the Render dashboard:
   - `DATABASE_URL` — Supabase PostgreSQL URI
   - `FIREBASE_SERVICE_ACCOUNT_BASE64` — base64 service account JSON
   - `ALLOWED_ORIGIN` — your app's origin or `*`
5. Deploy — Render will run `npm install && npm start` from `seads-backend/`.
6. Build your Flutter APK/IPA with:
   ```bash
   flutter build apk --dart-define=BACKEND_URL=https://<your-service>.onrender.com
   ```

---

## API Reference

All protected routes: `Authorization: Bearer <Firebase ID token>`

### Auth & Users

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register` | None | Register (upsert user by firebase_uid) |
| POST | `/api/auth/login` | None | Login (upsert + touch updated_at) |
| GET | `/api/auth/me` | Firebase | Current user profile |
| GET | `/api/users/:userId` | Firebase | Get user by Firebase UID |
| POST | `/api/users/role` | Firebase | Set user role |
| PUT | `/api/users/profile` | Firebase | Update name / phone / email |
| POST | `/api/users/fcm-token` | Firebase | Save FCM push token |

### Patient

| Method | Path | Description |
|---|---|---|
| POST | `/api/dispatch` | Dispatch nearest ambulance (PostGIS KNN) + FCM to paramedic |
| GET | `/api/patients/history` | Emergency history |
| GET | `/api/patients/contacts` | Emergency contacts |
| POST | `/api/patients/contacts` | Add contact |
| PUT | `/api/patients/contacts/:id` | Update contact |
| DELETE | `/api/patients/contacts/:id` | Remove contact |
| GET | `/api/patients/medical-profile` | Medical profile |
| PUT | `/api/patients/medical-profile` | Update medical profile |

### Paramedic

| Method | Path | Description |
|---|---|---|
| GET | `/api/incidents` | Active incidents for this paramedic's ambulance |
| PUT | `/api/incidents/:id/status` | Update incident status |
| PUT | `/api/paramedics/status` | Duty status |
| PUT | `/api/ambulances/location` | GPS ping (PostGIS `ST_MakePoint`) |
| GET | `/api/paramedics/history` | Resolved assignment history |
| GET | `/api/paramedics/stats` | Performance stats `?period=week\|month\|year` |
| GET | `/api/paramedics/equipment` | Equipment checklist |
| POST | `/api/paramedics/equipment/checklist` | Submit equipment check |
| GET | `/api/paramedics/shifts` | Shifts `?from=&to=` |
| POST | `/api/paramedics/shifts/swap-request` | Request shift swap |

### Dispatcher

| Method | Path | Description |
|---|---|---|
| GET | `/api/ambulances` | All ambulances with location |
| PUT | `/api/ambulances/:id/status` | Update fleet unit status |
| GET | `/api/dispatchers/fleet` | Fleet overview |
| GET | `/api/dispatchers/staff` | Staff list (paramedics + dispatchers) |
| GET | `/api/dispatchers/incidents` | Incident log (filterable) |
| GET | `/api/dispatchers/analytics` | Analytics `?period=week\|month\|year` |
| POST | `/api/dispatchers/assign` | Manually assign ambulance to incident |

---

## Build Configuration

| Define | Default | Purpose |
|---|---|---|
| `BACKEND_URL` | `http://10.0.2.2:3000` | API base URL |
| `ENV` | `prod` | `dev` / `staging` / `prod` |
| `DEMO_MODE` | `false` | Show sample data when APIs are empty |

---

## Design System

Shared widgets live under `lib/widgets/` (import via `design_system.dart`):

| Widget | Purpose |
|---|---|
| `SeadsScaffold` | Gradient page + glass app bar |
| `GlassCard` | Glassmorphic surface |
| `StatusBadge` | Icon + label + colour status |
| `EmergencySosButton` | Hold + tap SOS pattern |
| `PrimaryButton` | Full-width CTA |
| `SeadsEmptyState` / `SeadsErrorState` | Empty/error UI |

**Breakpoints:** `compact` < 600px · `medium` 600–1023px · `expanded` ≥ 1024px

---

## Realtime & Reliability

| Feature | Implementation |
|---|---|
| Live sync | `RealtimeSyncService` — adaptive polling (2s–30s backoff) |
| Offline queue | Hive `OfflineQueue` — dispatch, location, incident/paramedic status |
| Background GPS | `BackgroundLocationService` — Android foreground service |
| FCM deep links | `NotificationRoutes` + tap listener → GoRouter navigation |
| UI | `SyncStatusBanner` — pending queue count + poll interval |
