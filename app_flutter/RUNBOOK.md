# PitchPulse Flutter App — Runbook

## Phase 1: UI-First Demo (Firebase Auth + Stunning UI, Backend Placeholder)

---

## Prerequisites

```bash
flutter --version   # should show 3.x
pod --version       # CocoaPods for iOS
```

---

## Step 1: Firebase Setup (Required for Auth to work)

### Option A — Connect to existing Firebase project (recommended)

1. Create a Firebase project at https://console.firebase.google.com
2. Enable **Email/Password** authentication
3. Run:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=YOUR_PROJECT_ID
   ```
   This overwrites `lib/core/firebase_options.dart` and `ios/Runner/GoogleService-Info.plist` automatically.

4. Create two test users in Firebase Auth console:
   | Email | Password | Role |
   |---|---|---|
   | admin@pitchpulse.io | demo1234 | admin |
   | coach@realmadrid.com | demo1234 | manager |

> **Note:** The app currently uses `role` from the backend `/me` endpoint. Until Roshini's backend is live, the app falls back to `manager` for all users. To test admin UI, set the email to contain "admin" and update `_fetchMe` in `auth_provider.dart`.

---

## Step 2: Run the App

```bash
cd /Users/prithvisaran/development/PitchPulse/app_flutter

# Get dependencies (already done)
flutter pub get

# Run on iOS simulator
flutter run -d iPhone

# Run with backend URL set (when Roshini deploys)
flutter run --dart-define=BASE_URL=https://your-backend.vultr.com
```

---

## Step 3: Demo Click Path (Judge Demo Script)

### As Admin:
1. Login with `admin@pitchpulse.io`
2. See **Admin Requests** tab → pending workspace requests
3. Tap **Approve Workspace** → club gets approved

### As Manager (Coach):
1. Login with `coach@realmadrid.com`
2. **Club tab** → search "Real Madrid" → tap → **Request Access**
3. Status shows "Pending" → after admin approves, shows "Approved"
4. **Home tab** → Real Madrid squad loads with:
   - Next Match card with animated countdown ring
   - Player tiles with risk/readiness badges + sparklines
   - Tiles sorted by risk (HIGH first)
5. **Settings tab** → turn on **Demo Mode** toggle
6. **Home tab** → "⚡ Simulate FT Update" button appears
7. Tap it → shows loading → squad updates (some LOW → MED risk)
8. Tap **Jude Bellingham** (HIGH risk) → Player Detail screen
9. Scroll through: Risk chart → Load chart → Why Flagged section
10. Tap **"Find Similar Cases"** → loads vector search results from VectorAI DB
11. Tap **"Generate Coach Action Plan"** → Gemini + RAG plan appears
12. **Back** → **Reports tab** → match reports list
13. Tap a report → Match Detail with player minutes & risk impact

---

## Architecture Notes

```
app_flutter/
  lib/
    core/
      firebase_options.dart   ← replace with flutterfire output
      theme.dart              ← dark theme, colors, typography
      constants.dart          ← base URLs, spacing, animation durations
      auth_gate.dart          ← routes to admin or manager shell
    models/
      user_model.dart
      workspace_model.dart    ← ClubSearchResult included
      player_model.dart       ← PlayerDetailModel, RiskDriver, SimilarCase, ActionPlan
      fixture_model.dart      ← FixtureModel, MatchReportModel
    providers/
      auth_provider.dart      ← Firebase Auth + role
      workspace_provider.dart ← clubs, squad, fixtures, reports, admin
      player_provider.dart    ← detail, similar cases, action plan
    services/
      api_client.dart         ← HTTP client with Firebase token injection
    views/
      auth/login_screen.dart
      onboarding/club_select_screen.dart
      admin/{admin_shell, admin_requests_screen}.dart
      home/{manager_shell, home_screen}.dart
      player/player_detail_screen.dart
      reports/{reports_screen, match_detail_screen}.dart
      settings/settings_screen.dart
    widgets/
      common/{glass_card, gradient_badge, shimmer_loader}.dart
      home/{next_match_card, player_risk_tile}.dart
    main.dart
```

---

## Backend Integration (when Roshini's API is ready)

Set `BASE_URL` via `--dart-define` or update `AppConstants.baseUrl` in `constants.dart`.

All API calls are in `WorkspaceProvider` and `PlayerProvider`. Every call:
- First tries real backend
- Falls back to demo data if backend unavailable

Endpoints expected:
```
GET  /me
GET  /me/workspaces
POST /workspaces/request_access
GET  /workspaces/{id}/home
GET  /workspaces/{id}/reports
GET  /clubs/search?q=
POST /admin/workspaces/{id}/approve
GET  /admin/workspaces/pending
GET  /players/{id}/detail?weeks=6
GET  /players/{id}/similar_cases?k=5
POST /players/{id}/action_plan
POST /sync/fixtures/poll_once
```

---

## Design System Quick Reference

| Token | Value |
|---|---|
| Background | `#080C18` |
| Surface | `#111827` |
| Surface Elevated | `#1A2236` |
| Accent | `#4FACFE` → `#00F2FE` |
| Risk LOW | `#00E5A0` → `#00BCD4` |
| Risk MED | `#FFC107` → `#FF5F7E` |
| Risk HIGH | `#FF4040` → `#FF8C00` |
| Primary Font | Sora (Google Fonts) |
| Mono Font | JetBrains Mono |

---

## Quick Firebase Admin Tip

To test admin role without backend: in `auth_provider.dart`, `_fetchMe()` method,
change the fallback role check:
```dart
role: firebaseUser.email?.contains('admin') == true ? 'admin' : 'manager',
```
This routes `admin@pitchpulse.io` to the Admin shell automatically.
