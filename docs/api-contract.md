# SEADS API Contract (Flutter client ↔ seads-backend)

Base URL: `AppConfig.backendUrl`  
Default (Android emulator): `http://10.0.2.2:3000`  
Production: `https://<your-service>.onrender.com`

All protected routes require: `Authorization: Bearer <Firebase ID token>`

---

## Health Check

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | None | Returns `{ status: "ok", service: "SEADS API", version: "2.0.0" }` |

---

## Auth & Users

| Method | Path | Auth | Body / Params | Response |
|--------|------|------|---------------|----------|
| POST | `/api/auth/register` | None | `{ firebase_uid, email, name, phone, role }` | `{ user }` |
| POST | `/api/auth/login` | None | `{ firebase_uid, email }` | `{ user }` |
| GET | `/api/auth/me` | Firebase | — | `{ user }` |
| GET | `/api/users/:userId` | Firebase | — | `{ user }` |
| POST | `/api/users/role` | Firebase | `{ role }` | `{ user }` |
| PUT | `/api/users/profile` | Firebase | `{ name?, phone?, email? }` | `{ user }` |
| POST | `/api/users/fcm-token` | Firebase | `{ fcm_token }` | `{ message }` |

**User object:**
```json
{
  "id": "firebase_uid",
  "email": "user@example.com",
  "name": "John Doe",
  "phone": "+44700000000",
  "role": "patient | paramedic | dispatcher",
  "fcm_token": "...",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

---

## Patient

| Method | Path | Auth | Body / Params | Response |
|--------|------|------|---------------|----------|
| POST | `/api/dispatch` | Firebase | `{ lat, lng, patient_id, emergency_type, description? }` | `{ message, incident_id, ambulance_id, status }` |
| GET | `/api/patients/history` | Firebase | — | `{ history: [...] }` |
| GET | `/api/patients/contacts` | Firebase | — | `{ contacts: [...] }` |
| POST | `/api/patients/contacts` | Firebase | `{ name, phone, relationship, is_primary? }` | `{ contact }` |
| PUT | `/api/patients/contacts/:id` | Firebase | `{ name?, phone?, relationship?, is_primary? }` | `{ contact }` |
| DELETE | `/api/patients/contacts/:id` | Firebase | — | `{ message }` |
| GET | `/api/patients/medical-profile` | Firebase | — | medical profile object |
| PUT | `/api/patients/medical-profile` | Firebase | `{ blood_type?, allergies?, conditions?, medications?, notes? }` | medical profile object |

**Incident object (in history):**
```json
{
  "id": "uuid",
  "patient_id": "firebase_uid",
  "status": "pending | dispatched | en_route | on_scene | resolved | cancelled",
  "lat": 51.5074,
  "lng": -0.1278,
  "emergency_type": "Cardiac Arrest",
  "description": "...",
  "assigned_ambulance_id": "amb-001",
  "ambulance_name": "SEADS-01",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

**Medical profile object:**
```json
{
  "user_id": "firebase_uid",
  "blood_type": "O+",
  "allergies": ["Penicillin"],
  "conditions": ["Asthma"],
  "medications": ["Salbutamol"],
  "notes": "...",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

---

## Paramedic

| Method | Path | Auth | Body / Params | Response |
|--------|------|------|---------------|----------|
| GET | `/api/incidents` | Firebase | — | `{ incidents: [...] }` |
| PUT | `/api/incidents/:id/status` | Firebase | `{ status }` | `{ incident }` |
| PUT | `/api/paramedics/status` | Firebase | `{ status: available\|on_mission\|offline }` | `{ message, status }` |
| PUT | `/api/ambulances/location` | Firebase | `{ lat, lng }` | `{ message }` |
| GET | `/api/paramedics/history` | Firebase | — | `{ assignments: [...] }` |
| GET | `/api/paramedics/stats` | Firebase | `?period=week\|month\|year` | stats object |
| GET | `/api/paramedics/equipment` | Firebase | — | `{ equipment: [...] }` |
| POST | `/api/paramedics/equipment/checklist` | Firebase | `{ items: [{ id?, name, status, checked? }] }` | `{ message }` |
| GET | `/api/paramedics/shifts` | Firebase | `?from=ISO&to=ISO` | `{ shifts: [...] }` |
| POST | `/api/paramedics/shifts/swap-request` | Firebase | `{ shift_id, message? }` | `{ message, id }` |

**Shift object:**
```json
{
  "id": "uuid",
  "type": "Day Shift | Night Shift",
  "start": "2024-12-01T07:00:00Z",
  "end": "2024-12-01T19:00:00Z",
  "status": "scheduled | active | completed | cancelled",
  "partner": "Jane Smith",
  "ambulance_id": "amb-001"
}
```

**Equipment item object:**
```json
{
  "id": "uuid",
  "ambulance_id": "amb-001",
  "name": "Defibrillator (AED)",
  "category": "Critical",
  "status": "ok | warning | low",
  "last_checked": "2024-12-01T08:00:00Z"
}
```

**Stats object:**
```json
{
  "period": "week",
  "total": "12",
  "resolved": "10",
  "avg_response_minutes": "8.3"
}
```

---

## Dispatcher

| Method | Path | Auth | Body / Params | Response |
|--------|------|------|---------------|----------|
| GET | `/api/ambulances` | Firebase | — | `{ ambulances: [...] }` |
| PUT | `/api/ambulances/:id/status` | Firebase | `{ status: available\|on_mission\|maintenance\|offline }` | `{ ambulance }` |
| GET | `/api/dispatchers/fleet` | Firebase | — | `{ fleet: [...] }` |
| GET | `/api/dispatchers/staff` | Firebase | — | `{ staff: [...] }` |
| GET | `/api/dispatchers/incidents` | Firebase | `?status=&emergency_type=&from=&to=` | `{ incidents: [...] }` |
| GET | `/api/dispatchers/analytics` | Firebase | `?period=week\|month\|year` | analytics object |
| POST | `/api/dispatchers/assign` | Firebase | `{ incident_id, ambulance_id }` | `{ message, incident }` |

**Ambulance object:**
```json
{
  "id": "amb-001",
  "name": "SEADS-01",
  "status": "available | on_mission | maintenance | offline",
  "lat": 51.5074,
  "lng": -0.1278,
  "paramedic_id": "firebase_uid",
  "paramedic_name": "John Doe"
}
```

**Analytics object:**
```json
{
  "period": "week",
  "total_incidents": "47",
  "resolved": "42",
  "pending": "2",
  "dispatched": "3",
  "avg_response_minutes": "9.1",
  "by_status": [{ "status": "resolved", "count": "42" }],
  "by_emergency_type": [{ "emergency_type": "Cardiac Arrest", "count": "12" }],
  "fleet_summary": [{ "status": "available", "count": "3" }]
}
```

---

## Response Envelopes

The Flutter `ApiService` client accepts all of:

- Named list: `{ "incidents": [...] }`
- Bare array: `[...]`
- Nested: `{ "data": { "incidents": [...] } }`

**Errors** always return: `{ "error": "message" }` with a `4xx` or `5xx` status.

---

## Validation Errors

Invalid request bodies return `422 Unprocessable Entity`:
```json
{ "error": "field.path: error message" }
```

## Rate Limits

| Route group | Limit |
|---|---|
| `/api/auth/*` | 20 requests / 15 minutes per IP |
| All other `/api/*` | 120 requests / minute per IP |
