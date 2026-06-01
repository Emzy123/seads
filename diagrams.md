# SEADS Thesis Diagrams Repository — Chapters 3 and 4

This document serves as the official diagrams repository for the **Smart Emergency Ambulance Dispatch System (SEADS)** academic thesis. It contains [Mermaid](https://mermaid.js.org/) diagram specifications for **Chapter 3 (Methodology & System Architecture)** and **Chapter 4 (System Implementation, State Flows, and Reliability)**.

These diagrams can be rendered in Markdown viewers, GitHub, or pasted into the [Mermaid Live Editor](https://mermaid.live/) to export in high-resolution vector (SVG) or image (PNG) formats for inclusion in your thesis document.

---

## 📘 Chapter 3: Methodology and System Architecture

This chapter focuses on the design methodology, high-level framework, database architecture, and spatial querying algorithms used by the SEADS ecosystem.

### 1. High-Level System Architecture
This flowchart represents the multi-tier architectural layout of the SEADS platform, showing how the client layers (Patient, Paramedic, and Dispatcher) interface with the security gateways, PostGIS-enabled database, and cloud services (Firebase Auth/FCM).

```mermaid
flowchart TD
    subgraph Clients ["Client Layer (Flutter Cross-Platform App)"]
        Patient["Patient Mobile App (SOS Engine, Live Tracking, Profile Management)"]
        Paramedic["Paramedic Mobile App (GPS tracking, Navigation, Shifts, Equipment)"]
        Dispatcher["Dispatcher Web Console (Fleet Control, Staff, Live Analytics)"]
    end

    subgraph API ["Application Routing & Middleware Gateway"]
        Gateway["Node.js Express 5 API Gateway"]
        AuthMiddleware["Firebase Auth Middleware (Token Validation)"]
        ValidateMiddleware["Zod Validation Middleware"]
    end

    subgraph Cloud ["Third-Party Cloud Infrastructure"]
        FCM["Firebase Cloud Messaging (FCM Push Service)"]
        FirebaseAuth["Firebase Authentication Service"]
    end

    subgraph DB ["Data Persistence & Spatial Layer"]
        Supabase["Supabase Cloud Instance"]
        PostGIS["PostGIS Spatial Database Engine"]
        Realtime["Supabase Realtime Engine (WebSockets)"]
    end

    Clients <-->|HTTPS Restful JSON Requests| Gateway
    Gateway --> AuthMiddleware
    Gateway --> ValidateMiddleware
    AuthMiddleware <-->|Firebase ID Token Validation| FirebaseAuth
    Gateway <-->|SQL Queries & Spatial Operations| Supabase
    Supabase --> PostGIS
    Gateway -->|Trigger Dispatch Alerts| FCM
    FCM -->|Push Alerts| Clients
    Clients <-->|Realtime Socket Sync| Realtime
```

* **Thesis Context**: Paste this diagram under the **System Architecture Overview** section. It illustrates the decoupling of client concerns and showcases the centralized Express gateway linking external devices securely to Supabase.

---

### 2. Database Entity Relationship Diagram (ERD)
The database structure details the PostgreSQL relational schema, including PostGIS `GEOGRAPHY(POINT, 4326)` columns, constraints, and field relationships.

```mermaid
erDiagram
    users {
        TEXT id PK "Firebase UID"
        TEXT email "Unique"
        TEXT name
        TEXT phone
        TEXT role "patient | paramedic | dispatcher"
        TEXT fcm_token
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    ambulances {
        TEXT id PK "UUID"
        TEXT name
        TEXT status "available | on_mission | maintenance | offline"
        GEOGRAPHY location "Point (4326)"
        TEXT paramedic_id FK "References users(id)"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    incidents {
        TEXT id PK "UUID"
        TEXT patient_id FK "References users(id)"
        TEXT status "pending | dispatched | en_route | on_scene | resolved | cancelled"
        GEOGRAPHY location "Point (4326)"
        TEXT emergency_type
        TEXT description
        TEXT assigned_ambulance_id FK "References ambulances(id)"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }
    emergency_contacts {
        TEXT id PK "UUID"
        TEXT user_id FK "References users(id)"
        TEXT name
        TEXT phone
        TEXT relationship
        BOOLEAN is_primary
        TIMESTAMPTZ created_at
    }
    medical_profiles {
        TEXT user_id PK "FK References users(id)"
        TEXT blood_type
        TEXT_ARRAY allergies
        TEXT_ARRAY conditions
        TEXT_ARRAY medications
        TEXT notes
        TIMESTAMPTZ updated_at
    }
    equipment_items {
        TEXT id PK "UUID"
        TEXT ambulance_id FK "References ambulances(id)"
        TEXT name
        TEXT category
        TEXT status "ok | warning | low"
        TIMESTAMPTZ last_checked
    }
    shifts {
        TEXT id PK "UUID"
        TEXT paramedic_id FK "References users(id)"
        TEXT ambulance_id FK "References ambulances(id)"
        TEXT type "Day Shift | Night Shift"
        TIMESTAMPTZ start_time
        TIMESTAMPTZ end_time
        TEXT status "scheduled | active | completed | cancelled"
        TEXT partner_name
        TIMESTAMPTZ created_at
    }
    shift_swap_requests {
        TEXT id PK "UUID"
        TEXT shift_id FK "References shifts(id)"
        TEXT requester_id FK "References users(id)"
        TEXT message
        TEXT status "pending | approved | rejected"
        TIMESTAMPTZ created_at
    }

    users ||--o{ ambulances : "operates"
    users ||--o{ incidents : "creates"
    users ||--o{ emergency_contacts : "has"
    users ||--|| medical_profiles : "owns"
    users ||--o{ shifts : "assigned_to"
    users ||--o{ shift_swap_requests : "requests"
    ambulances ||--o{ incidents : "assigned_to"
    ambulances ||--o{ equipment_items : "contains"
    ambulances ||--o{ shifts : "linked_to"
    shifts ||--o{ shift_swap_requests : "referenced_in"
```

* **Thesis Context**: Present this under the **Database Design Schema** section. It models how records cascade and reference other core tables to enforce integrity across emergency cycles.

---

### 3. Emergency Dispatch & PostGIS KNN Nearest Neighbor Routing
A sequence of the primary methodology flow, demonstrating the execution of PostGIS distance query operators (`<->`) to match a patient with the nearest available unit during an SOS event.

```mermaid
sequenceDiagram
    autonumber
    actor Patient as Patient App
    actor Dispatcher as Dispatcher Console
    participant Backend as Node.js Express Server
    participant DB as Supabase (PostgreSQL + PostGIS)
    participant FCM as Firebase Cloud Messaging
    actor Paramedic as Paramedic App

    Patient->>Backend: POST /api/dispatch (patient_id, location, emergency_type)
    activate Backend
    Backend->>DB: Check if patient already has active incidents
    DB-->>Backend: No active incidents found (Safe to proceed)
    
    Backend->>DB: Query nearest available ambulance using PostGIS KNN
    note over DB: SELECT id, location FROM ambulances <br/>WHERE status = 'available' <br/>ORDER BY location <-> ST_SetSRID(ST_MakePoint(lng, lat), 4326)<br/>LIMIT 1;
    DB-->>Backend: Returns nearest unit (id: amb-001, paramedic_id)
    
    Backend->>DB: INSERT INTO incidents (patient_id, status, location, assigned_ambulance_id)
    DB-->>Backend: Incident saved with status: 'dispatched'
    
    Backend->>DB: UPDATE ambulances SET status = 'on_mission' WHERE id = 'amb-001'
    DB-->>Backend: Unit status locked on mission
    
    Backend->>FCM: Trigger Notification Payload (incident_id, patient_coords)
    activate FCM
    FCM-->>Paramedic: Push Alert to Paramedic Device (fcm_token)
    deactivate FCM
    
    Backend-->>Patient: Return dispatch response (incident_id, ambulance_name, status: dispatched)
    deactivate Backend
    
    Paramedic->>Backend: PUT /api/incidents/:id/status (status: 'en_route')
    Backend->>DB: Update incident state
    Backend-->>Paramedic: Status updated successfully
    
    rect rgb(240, 248, 255)
        note over Patient, Paramedic: Real-time Coordinate Polling
        Paramedic->>Backend: PUT /api/ambulances/location (current_gps_coords)
        Backend->>DB: Update ambulance location in DB
        DB-->>Backend: Coords updated
        Patient->>Backend: GET /api/patients/active-incident (Poll every 10s)
        Backend-->>Patient: Returns live ambulance location, ETA, status: en_route
    end
```

* **Thesis Context**: Insert this under the **Ambulance Allocation and Dispatch Algorithm** section. It represents the temporal choreography and algorithmic step-by-step logic of the system.

---

## 📊 Chapter 4: System Implementation and Operation

This chapter documents physical implementations, real-time client-side polling behaviors, mobile state machines, and network reliability mechanisms.

### 4. Patient Real-Time Tracking Sync Loop
Flow diagram outlining the mobile implementation of `RealtimeSyncService` on the Patient's map interface. It maps how the app fetches data, handles network lag/timeouts, handles backoffs, and repaints markers.

```mermaid
flowchart TD
    Start([Start Real-Time Sync Loop]) --> CheckActive{Is Active Incident?}
    
    CheckActive -- No --> StopLoop([Stop Poll Loop & Clear Markers])
    CheckActive -- Yes --> FetchIncident[Call GET /api/patients/active-incident]
    
    FetchIncident --> APIStatus{API Call Successful?}
    
    APIStatus -- No (Network Error) --> Backoff["Double Poll Interval (Backoff to max 30s)"]
    Backoff --> ShowSyncStatus["Display 'Connecting...' Status Banner"]
    ShowSyncStatus --> WaitPoll[Wait for poll interval]
    WaitPoll --> FetchIncident
    
    APIStatus -- Yes --> ResetPoll["Reset Poll Interval to 2s-10s min"]
    ResetPoll --> ExtractCoords[Extract assigned ambulance location coordinates]
    
    ExtractCoords --> CheckLocation{Has Coordinates?}
    
    CheckLocation -- No (Ambulance not yet moving) --> DisplaySpinner[Show Ambulance Dispatching Spinner]
    DisplaySpinner --> UpdateDetails[Update incident status and ETA on UI]
    
    CheckLocation -- Yes --> UpdateMap[Repaint Live Paramedic Map Marker]
    UpdateMap --> CameraPan[Auto-pan Map Camera to center both Patient and Paramedic]
    CameraPan --> UpdateDetails
    
    UpdateDetails --> UpdateBanner["Display 'Synced' Status Banner"]
    UpdateBanner --> WaitPoll
```

* **Thesis Context**: Insert under **Real-time Map Integration and Synchronization** to explain the patient UI polling architecture and map centering calculations.

---

### 5. Paramedic Duty Shift & Incident Lifecycle State Machine
Statechart outlining the state transitions of the Paramedic's shift cycle (including swap requests) and individual incident response lifecycles.

```mermaid
stateDiagram-v2
    [*] --> Scheduled : Admin Assigns Paramedic to Shift

    state Scheduled {
        [*] --> Idle
        Idle --> SwapRequested : Create Swap Request
        SwapRequested --> Idle : Admin Rejects Request
        SwapRequested --> Swapped : Admin Approves Swap Request (Atomics)
        Swapped --> [*]
    }

    Scheduled --> Active : Paramedic Clicks 'Clock In' (Shift starts)
    
    state Active {
        [*] --> OnDuty
        OnDuty --> Dispatched : Receives Incident Push Notification
        Dispatched --> EnRoute : Clicks 'Accept' (Navigating to Patient)
        EnRoute --> OnScene : Clicks 'Arrive at Scene'
        OnScene --> Transporting : Loading Patient into Unit
        Transporting --> PatientHandover : Arrives at Hospital / Clinic
        PatientHandover --> OnDuty : Clicks 'Resolve Incident' (Ambulance available)
    }

    Active --> Completed : Paramedic Clicks 'Clock Out' (Shift ends)
    Completed --> [*]
```

* **Thesis Context**: Place this under the **Paramedic Flow and State Management** section to depict the shifts and operational states of paramedics on duty.

---

### 6. Offline Queue & Network Reliability Flow
Shows the fallback logic of the mobile application when handling internet dropouts during critical paramedic coordinate broadcasts or dispatcher commands.

```mermaid
flowchart TD
    Start([Client Triggers Action e.g., Update Status / GPS Ping]) --> NetCheck{Is Network Online?}
    
    NetCheck -- Yes --> SendAPI[Send REST Request to Deployed Backend]
    SendAPI --> APISuccess{API Responded 2xx?}
    
    APISuccess -- Yes --> Complete([Update Local UI state & complete])
    
    APISuccess -- No (Temporary Timeout) --> QueueAction[Save Action in Hive Offline Queue]
    NetCheck -- No (Offline) --> QueueAction
    
    QueueAction --> ShowBanner["Show Banner: 'Offline - Queueing X actions'"]
    ShowBanner --> StartSyncService["Launch Background Sync Polling Service"]
    
    StartSyncService --> MonitorNet{Network Restored?}
    
    MonitorNet -- No --> WaitRetry[Wait 30 seconds]
    WaitRetry --> MonitorNet
    
    MonitorNet -- Yes --> FlushQueue["Flush Hive Queue (FIFO Order)"]
    FlushQueue --> SendQueueItem["Send first queued action to Backend"]
    
    SendQueueItem --> QueueItemSuccess{Success?}
    QueueItemSuccess -- Yes --> RemoveItem["Delete item from Hive Queue"]
    RemoveItem --> CheckEmpty{Queue Empty?}
    
    CheckEmpty -- No --> SendQueueItem
    CheckEmpty -- Yes --> HideBanner["Hide Offline Status Banner"]
    HideBanner --> Complete
    
    QueueItemSuccess -- No --> StopFlush[Pause flushing & Wait 30s]
    StopFlush --> MonitorNet
```

* **Thesis Context**: Place this under **System Reliability, Offline Support, and Failure Modes** to document the local queue synchronization and retry mechanism.
