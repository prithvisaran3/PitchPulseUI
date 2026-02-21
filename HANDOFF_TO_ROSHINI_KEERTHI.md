# PitchPulse — Handoff: Progress Summary & What’s Left (Roshini & Keerthi)

**From:** Prithvi  
**To:** Roshini (Backend), Keerthi (AI layer)  
**Date:** Feb 2026  
**Purpose:** Share what’s done on the Flutter app, what’s missing, and what each of you needs to implement or improve so we can integrate and demo.

---

## 1. What’s Done (Flutter App — Prithvi)

### 1.1 Project & Setup
- **Flutter app** lives in `app_flutter/`.
- **Firebase:** Connected to **PitchPulse** project (`pitchpulse-hack2026`) via FlutterFire CLI. Email/password auth works; app runs on a real device.
- **iOS:** Builds and runs on iPhone; signing uses team `3WZUXTYNHQ`.
- **No backend dependency to run:** App uses demo/mock data when API calls fail, so you can use it end-to-end without your services.

### 1.2 Auth Flow
- **Login screen** with email/password, sign up toggle, error handling.
- **Firebase Auth:** Every API request sends `Authorization: Bearer <Firebase ID token>` (see `lib/services/api_client.dart`).
- **Role routing:** After login, app calls `GET /me`. If that fails, it infers role from email: `*admin*` → Admin shell, else → Manager shell. So you can test Admin with e.g. `admin@pitchpulse.io` before backend exists.

### 1.3 Screens Implemented (All With Placeholders Where Backend/AI Not Ready)

| Screen | Description | Backend / AI Used |
|--------|-------------|-------------------|
| **Login** | Email/password, sign up, error banner | Firebase Auth only |
| **Club Select & Request Access** | Search clubs → select → “Request Access” | `GET /clubs/search?q=`, `POST /workspaces/request_access` (fallback: demo club list + mock workspace) |
| **Admin Requests** | List pending workspace requests, “Approve” button | `GET /admin/workspaces/pending`, `POST /admin/workspaces/{id}/approve` (fallback: demo pending list) |
| **Admin Workspaces** | List of approved workspaces (static demo list in UI) | Could add `GET /admin/workspaces` when you have it |
| **Home (Manager)** | Next match card (countdown, live/FT status), squad grid with risk/readiness badges, sparklines, sort/filter | `GET /workspaces/{id}/home` (fallback: demo fixture + demo squad) |
| **Simulate FT (Demo)** | Button visible when “Demo Mode” is ON in Settings; triggers mock “match finished” update | `POST /sync/fixtures/poll_once` (fallback: local state update + demo report) |
| **Player Detail** | Header, risk gauge, risk trend chart, acute vs chronic load chart, “Why Flagged”, “Similar Cases”, “Generate Coach Action Plan” | `GET /players/{id}/detail?weeks=6`, `GET /players/{id}/similar_cases?k=5`, `POST /players/{id}/action_plan` (all have demo fallbacks) |
| **Reports** | List of match reports; tap → match detail | `GET /workspaces/{id}/reports` (fallback: demo report list) |
| **Match Detail** | Scoreline, load summary, player minutes + risk impact | Data from report object (no extra endpoint) |
| **Settings** | Profile, active workspace, **Demo Mode** toggle, backend URL note, sign out | No backend; Demo Mode controls visibility of “Simulate FT” on Home |

### 1.4 Design & UX
- Dark theme (e.g. `#080C18` background), glass-style cards, gradient risk/readiness badges (LOW/MED/HIGH).
- Typography: Sora (primary), JetBrains Mono (numeric).
- Animations: `flutter_animate`, bouncy cards, countdown ring on next match, sparklines on player tiles, shimmer loading.
- Navigation: Manager = 4 tabs (Home, Club, Reports, Settings); Admin = 3 tabs (Requests, Workspaces, Settings).

### 1.5 Data Models (What the App Expects From API)

These are the **exact** JSON shapes the app parses. Your backend/AI should align with these.

- **`/me`**  
  `{ "uid": string, "email": string, "role": "admin"|"manager", "workspace_ids": string[], "display_name"?: string }`

- **`/me/workspaces`** (or workspace list in `/me`)  
  Array of:  
  `{ "id", "club_id", "club_name", "club_crest_url?", "status": "pending"|"approved"|"rejected", "manager_id", "created_at"?: ISO string }`

- **`/clubs/search?q=`**  
  Array of:  
  `{ "id", "name", "country?", "crest_url?", "founded"?: number }`

- **`/workspaces/request_access`**  
  Body: `{ "club_id", "club_name" }`  
  Response: same as one workspace object (e.g. `id`, `status: "pending"`, …).

- **`/workspaces/{id}/home`**  
  `{ "next_fixture": Fixture, "squad": Player[] }`  
  - **Fixture:** `{ "id", "home_team", "away_team", "home_logo_url?", "away_logo_url?", "kickoff": ISO datetime, "status": "NS"|"LIVE"|"FT", "home_score"?, "away_score"?, "venue", "competition" }`  
  - **Player:** `{ "id", "name", "position", "nationality?", "jersey_number?", "photo_url?", "age?", "risk_score": number 0–100, "risk_band": "LOW"|"MED"|"HIGH", "readiness_score", "readiness_band", "top_drivers"?: string[], "risk_sparkline"?: number[] }`

- **`/workspaces/{id}/reports`**  
  Array of:  
  `{ "fixture_id", "opponent", "match_date": ISO, "result": "W"|"D"|"L", "goals_for", "goals_against", "competition", "avg_player_load"?, "headline"?, "minutes_played"? }`

- **`/admin/workspaces/pending`**  
  Array of workspace objects (same as above).

- **`/admin/workspaces/{id}/approve`**  
  POST; no specific response shape required (app just refreshes list).

- **`/players/{id}/detail?weeks=6`**  
  `{ "player": Player (same as above), "weekly_load": WeeklyLoadPoint[], "risk_drivers": RiskDriver[] }`  
  - **WeeklyLoadPoint:** `{ "week_label", "week_start": ISO, "acute_load", "chronic_load", "risk_score" }`  
  - **RiskDriver:** `{ "label", "value", "threshold", "trend": "UP"|"DOWN"|"STABLE", "severity": "LOW"|"MED"|"HIGH" }`

- **`/players/{id}/similar_cases?k=5`**  
  Array of:  
  `{ "player_id", "player_name", "week_label", "similarity_score": number 0–1, "summary", "outcome" }`

- **`/players/{id}/action_plan`**  
  POST; response:  
  `{ "summary", "why": string[], "recommendations": string[], "caution", "generated_at"?: ISO }`

- **`/sync/fixtures/poll_once`**  
  POST; no response shape required (app may reload home/reports after).

---

## 2. What’s Missing / To Improve (General)

- **Backend not deployed yet** — App points to `localhost:8000` by default; needs a stable base URL (e.g. Vultr) and CORS configured for the app.
- **Single shared API contract file** — There is no `contracts/api_contract.md` in the repo yet. Roshini: creating one (with the shapes above) would help Keerthi and the app stay in sync.
- **Real club search** — Currently demo list; should be driven by your football data provider (e.g. API-FOOTBALL) and stored provider IDs.
- **Real sync worker** — “Simulate FT” is either calling `poll_once` or doing local mock; the real flow (poll fixtures → on FT fetch player stats → update load/risk → generate report → vector upsert) is backend work.
- **Optional features not in app yet:** Presage readiness check-in, movement screen (video upload + Gemini). Backend/AI contracts can be agreed when you’re ready.

---

## 3. For Roshini (Backend)

### 3.1 Must Have for Demo
1. **FastAPI app** with the endpoints listed in Section 1.5, plus:
   - **Auth:** Verify Firebase ID token on each request (e.g. decode JWT, check `iss`/`aud`), and return 401 when invalid.
   - **`GET /me`:** From token `uid` (and optionally Firestore/DB), return `uid`, `email`, `role` (admin vs manager), `workspace_ids`. This drives Admin vs Manager routing in the app.
2. **DB (Postgres or SQLite for demo):** workspaces, clubs, players, fixtures, match stats, computed metrics (risk/readiness, baseline). Store provider IDs for clubs/players/fixtures.
3. **Club search:** Endpoint that uses your football data provider (e.g. API-FOOTBALL) and returns list in the shape expected by `/clubs/search`.
4. **Workspace flow:** Request access → store pending; approve → create workspace and trigger initial sync (squad + fixtures + baseline). Expose `GET /workspaces/{id}/home` and `GET /workspaces/{id}/reports` from this data.
5. **Sync worker (or at least one-shot):** Either a cron/job that runs every 2–5 min or a manual “poll once” that:
   - Finds fixtures that just went FT,
   - Fetches player stats (minutes, etc.),
   - Updates load/risk/readiness,
   - Generates match report and player-week summaries,
   - Upserts embeddings into Actian Vector (for Keerthi’s similar-case retrieval).
6. **CORS:** Allow the Flutter app origin (and/or your deployed app URL) so the app can call the API from a real device/simulator.
7. **Deployment:** e.g. Vultr; app will use `BASE_URL` (env or `--dart-define=BASE_URL=...`).

### 3.2 Nice to Have
- **`GET /admin/workspaces`** — All approved workspaces (for Admin “Workspaces” tab).
- **Stable demo workspace/fixture IDs** — So we can document a single “demo script” with fixed IDs (app already has constants like `demoWorkspaceId`; backend can use same IDs for seed data).

### 3.3 Ownership (From Project Brief)
- You own backend repo structure, Pydantic models, and endpoint paths.  
- Contract changes: maintain a single shared file (e.g. `contracts/api_contract.md`) so Keerthi and the app can follow.

---

## 4. For Keerthi (AI Layer)

### 4.1 Must Have for Demo
1. **Actian Vector DB integration (backend side):**
   - **Similar cases:** Given a player-week context (or embedding), return top-k similar cases in the shape the app expects:  
     `{ "player_id", "player_name", "week_label", "similarity_score", "summary", "outcome" }`.  
   - Backend endpoint `GET /players/{id}/similar_cases?k=5` should call your retrieval and return this list.
2. **Action plan (Gemini + RAG):**
   - **Strict JSON output:** Backend endpoint `POST /players/{id}/action_plan` should call your module and return:  
     `{ "summary", "why": [3], "recommendations": [3], "caution" }` (and optionally `generated_at`).  
   - Use top-k similar docs + any playbook snippets; Gemini generates the plan; no medical claims (triage/workload only).
3. **Embedding generation:** When backend processes a finished match and computes player-week metrics, it should produce embeddings (your chosen model) and upsert into Actian Vector with metadata (player_id, week_label, outcome, summary, etc.) so “similar cases” retrieval works.
4. **Prompts:** You own `/backend/ai/*` and `/backend/prompts/*`; keep prompt templates and JSON schemas in sync with the response shapes in Section 1.5.

### 4.2 Optional (If Time)
- **Presage readiness check-in:** Backend receives vitals/readiness signals; you define payload contract and how they fuse with workload.
- **Movement screen:** Video upload (e.g. Vultr object storage); backend calls Gemini video understanding; you define mechanical risk + cues and how they feed into risk drivers.

### 4.3 Ownership (From Project Brief)
- You own only `/backend/ai/*` and `/backend/prompts/*`.  
- Do not change core API request/response schemas without coordinating with Roshini (use the shared contract file).

---

## 5. How to Run the App (For You Two)

```bash
cd app_flutter
flutter pub get
flutter run -d <device_id>   # e.g. iPhone or simulator
```

- **Backend URL:** Default is `http://localhost:8000`. For a device, use a reachable URL, e.g.:  
  `flutter run --dart-define=BASE_URL=https://your-api.vultr.com`
- **Firebase:** Already configured for project **PitchPulse** (`pitchpulse-hack2026`). Create test users in Firebase Console (Authentication → Add user) if you want to test login.
- **Demo without backend:** Leave default base URL; app will use demo data for all screens. Turn on **Demo Mode** in Settings to see “Simulate FT Update” on Home.

---

## 6. Quick Checklist for Integration

- [ ] **Roshini:** FastAPI up with auth (Firebase token verification) and `GET /me` returning `role` + `workspace_ids`.
- [ ] **Roshini:** Implement endpoints in Section 1.5 and wire club search to your data provider.
- [ ] **Roshini:** Sync worker (or poll_once) that on FT: fetches stats, updates metrics, writes report, calls Keerthi’s embedding + upsert.
- [ ] **Roshini:** Create `contracts/api_contract.md` (or similar) with the same request/response shapes as in Section 1.5.
- [ ] **Keerthi:** Similar-case retrieval (Actian Vector) returning the exact JSON shape for `similar_cases`.
- [ ] **Keerthi:** Action plan (Gemini + RAG) returning the exact JSON shape for `action_plan`.
- [ ] **Both:** Agree on who calls whom (e.g. FastAPI calls your AI/vector module; no direct app → Vector/Gemini).
- [ ] **Roshini:** Deploy backend (e.g. Vultr), set CORS, share `BASE_URL`; Prithvi will point the app at it and we do an end-to-end demo.

---

If anything is unclear or you want the app to expect a slightly different JSON shape for an endpoint, we can align on the contract first and then I’ll adjust the Flutter models. Good luck with the backend and AI layers.
