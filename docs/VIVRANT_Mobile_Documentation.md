# VIVRΛNT Mobile — Complete Documentation

**Last updated:** 20 August 2026  
**Repo:** [vivrant-mobile](https://github.com/Neverbeast24/vivrant-mobile)  
**Backend:** [vivrant-server](https://github.com/Neverbeast24/vivrant-server)  
**Brand:** VIVRΛNT · *Long live life* · *Every Choice Shapes Your Health.*

This is the Flutter companion to VIVRΛNT Web. It mirrors the **member dashboard** on iOS and Android and exposes a lighter **admin** surface for staff. Ecosystem, data model, Gemini, and the full REST catalog are documented in the web repo: [`docs/VIVRANT_Complete_Documentation.md`](https://github.com/Neverbeast24/vivrant-server/blob/main/docs/VIVRANT_Complete_Documentation.md). The HTTP contract is [`docs/MOBILE_API_SPEC.md`](./MOBILE_API_SPEC.md).

Former working name: VIVA (Virtual Intelligent Vitality Assistant).

---

## 1. Purpose

VIVRΛNT Mobile lets members log and coach the same wellness loops as the website without opening a browser:

- Daily check-in, nutrition, training (activity + gym), wellness, journal, habits
- Kitchen (groceries + pantry), spending, reports, Ask VIVRΛNT
- Profile, archive/restore, support tickets, notifications, search

**Server owns domain logic.** Flutter is a Riverpod + GoRouter client. It never embeds `GEMINI_API_KEY` or `SUPABASE_SECRET_KEY`.

---

## 2. Architecture

```text
Splash → Onboarding (first launch) → Login / Signup
        │
        ▼
   AppShell (indexed stack)
     Today · Nutrition · Move · Ask · More
        │
        └── More → Training, Wellness, Journal, Habits, Kitchen,
                   Spending, Reports, Search, Profile, Archive,
                   Help, Notifications  (+ Admin if staff)
        │
        └── Dio ApiClient ── HTTPS ── vivrant-server
              Authorization: Bearer <supabase_access_token>
```

| Piece | Location |
|-------|----------|
| App + router | `lib/app/app.dart`, `lib/app/router.dart`, `lib/app/shell/` |
| Env | `lib/config/env.dart` (`API_BASE_URL`, optional Supabase defines) |
| HTTP | `lib/core/network/api_client.dart` (Dio, secure storage, idle logout) |
| Theme | `lib/core/theme/` |
| Shared widgets | `lib/core/widgets/` |
| API methods | `lib/data/vivrant_api.dart` + `lib/data/api/*.dart` |
| Features | `lib/features/<name>/presentation/screens/` |

---

## 3. Tech stack

| Layer | Choice |
|-------|--------|
| SDK | Flutter stable, Dart `^3.9.2` |
| State | `flutter_riverpod` |
| Routes | `go_router` (feature barrels only — never import `presentation/screens/` from `router.dart`) |
| HTTP | `dio` |
| Tokens | `flutter_secure_storage` (Android encrypted prefs; iOS Keychain) |
| Fonts | `google_fonts` — Space Grotesk, Bricolage Grotesque, Instrument Serif |
| Images | `cached_network_image`, `image_picker` (avatars, meal photos) |
| Push | `firebase_core` + `firebase_messaging` |
| OAuth (optional) | `supabase_flutter` · redirect `io.supabase.vivrant://login-callback/` |
| Share / files | `share_plus`, `path_provider` (backup JSON) |
| Icons / splash | `flutter_launcher_icons`, `flutter_native_splash` (color `#0C1210`) |

Package name: `vivrant_mobile` · version `1.0.0+1`.

---

## 4. Configuration

Pass overrides with `--dart-define` (or `--dart-define-from-file`).

| Define | Default | Notes |
|--------|---------|--------|
| `API_BASE_URL` | `http://10.0.2.2:3000` | Android emulator → host Next.js. **Release builds must be `https://`.** |
| `SUPABASE_URL` | project URL | Only needed for in-app OAuth |
| `SUPABASE_ANON_KEY` | publishable key | Browser-safe; never the secret key |

Examples:

```bash
flutter pub get

# Android emulator (default API_BASE_URL)
flutter run

# iOS simulator
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000

# Physical device on the same Wi-Fi
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000

# Production
flutter run --dart-define=API_BASE_URL=https://your-app.vercel.app
```

Allowlist `io.supabase.vivrant://login-callback/` in Supabase **Authentication → URL Configuration → Redirect URLs** if using Google/GitHub inside the app.

---

## 5. Auth and session

1. `VivrantApi.login` / `signup` → `POST /api/auth/login|signup`
2. Store `access_token` + `refresh_token` in secure storage
3. Dio interceptor attaches `Authorization: Bearer …`
4. `401` clears tokens and returns to login
5. `POST /api/mobile/auth/refresh` on expiry
6. `logout` calls `POST /api/mobile/auth/logout` then deletes local tokens
7. Forgot password uses `/api/auth/forgot-password`; change password uses `/api/auth/change-password`

**Idle timeout:** 10 minutes with no user interaction. Silent token refresh does **not** extend the window. A stay-signed-in warning appears 90 seconds before logout (`sessionIdleTimeout` / `sessionIdleWarnBefore` in `api_client.dart`).

Suspended profiles: server returns `403`; client treats the session as unusable.

GoRouter does **not** watch `authProvider` directly (that would rebuild the router and reset navigation). It uses `refreshListenable` + `ref.read`.

---

## 6. Navigation

### Unauthenticated

| Path | Screen |
|------|--------|
| `/splash` | Brand splash |
| `/onboarding` | First-launch intro |
| `/login` | Sign in |
| `/signup` | Create account |
| `/forgot-password` | Reset email |

Authenticated users hitting those routes redirect to `/today`. Unauthenticated users hitting app routes redirect to `/login` (or `/onboarding` if that flag is set).

### Shell tabs

| Tab | Path | Screen |
|-----|------|--------|
| Today | `/today` | Daily check-in + pulse + quick actions |
| Nutrition | `/nutrition` | Meals, water, AI estimate, easy entry |
| Move | `/move` | Training hub (activity + gym) |
| Ask | `/ai` | Ask VIVRΛNT chat |
| More | `/more` | Module directory |

Nutrition child: `/nutrition/log`. Move children: `/move/activity`, `/move/log`.

### Modules (More + deep links)

Grouped in `lib/shared/constants/app_modules.dart` (mirrors web `dashboardNav`).

**Training:** `/move`, `/gym`, `/gym/plans`, `/gym/demos`, `/gym/machines`, `/gym/sessions`  
**Wellness:** `/wellness`, `/sleep`, `/hydration`, `/mindfulness`, `/journal`, `/habits`, `/habits/challenges`  
**Household:** `/kitchen`, `/groceries`, `/pantry`, `/pantry/add`, `/spending`, `/spending/log`, `/spending/sheet`, `/spending/budget`  
**Insights:** `/reports`, `/search`, `/ai/insights`, `/ai/reminders`  
**Account:** `/profile`, `/profile/goals`, `/profile/history`, `/profile/archive`, `/profile/preferences`, `/profile/password`, `/support`, `/notifications`

**Admin** (filtered by role): `/admin`, `/admin/users`, `/admin/tickets`, `/admin/roles`, `/admin/audit`, `/admin/settings`. Super-admin only: `/admin/activity`, `/admin/inquiries`. Non-staff hitting `/admin/*` redirect to `/more`.

Legacy aliases: `/movement` → `/move/activity`, `/training` → `/move`.

---

## 7. Feature parity

| Module | What members can do |
|--------|---------------------|
| **Today** | Check-in (energy, mood, steps, water, sleep, note); live stats; quick actions |
| **Nutrition** | List/update/delete meals; bulk paste; water; AI estimate (text/photo); AI suggest |
| **Training** | Log activity; gym demos/machines; sessions with rest timer; AI programs + drafts; live session restore |
| **Wellness** | Sleep log + coach; hydration + reminders; mood + mindfulness coach |
| **Journal** | CRUD notes; AI reflection |
| **Habits** | Daily toggle, edit, AI suggest, weekly challenges |
| **Kitchen** | Grocery CRUD, bulk paste, clear completed, AI plan, cost estimate, restock pantry; pantry CRUD, bulk, low-stock → list |
| **Spending** | Expenses CRUD, bulk paste, sheet, monthly budget, coach |
| **Reports** | Weekly aggregates + AI weekly story |
| **Ask VIVRΛNT** | Chat history, insights, reminders (draft, gym-plan sync, today leftover sync) |
| **Profile** | Health fields, avatar, goals, health history + AI analyze, preferences, list order, password |
| **Archive** | List soft-deleted items, restore, download JSON backup |
| **Help** | Create / list support tickets |
| **Notifications** | Inbox, mark read / read-all, FCM register |
| **Search** | `GET /api/search?q=` |
| **Admin** | Overview, users, tickets, roles, audit, system broadcast; super_admin activity + inquiries |

Web remains richest for: gym demo library management, grocery price insights page, pantry category browser, marketing contact form, and the full admin console layout.

---

## 8. Shared widgets and entry modes

Reusable UI in `lib/core/widgets/` (barrel: `widgets.dart`):

| Widget | Use |
|--------|-----|
| `GradientScaffold`, `PageHeader`, `Panel` | Page chrome |
| `EmptyState`, `ErrorView`, `LoadingView`, `AsyncBody` | States |
| `ListRow`, `ModuleTile`, `IconWell`, `StatCard` | Lists and hubs |
| `PrimaryButton`, `ProgressBar`, `ScorePicker` | Actions / 1–5 scores |
| `EasyEntryToggle` | Switch form ↔ paste / sheet |
| `QuickListPaste` | Notepad / spreadsheet paste |
| `ExcelTable` | Grid editing (spending sheet and similar) |
| `ConfirmDialog` | Restore / destructive confirms |
| `FilterChips`, `SectionLabel` | Filters and labels |

Paste parsing (`lib/core/utils/parse_quick_list.dart`) matches web `src/lib/lists/parse-quick-list.ts`: tabs, CSV, or one name per line; optional quantity, category, price/amount. Bulk endpoints accept `{ "text": "…" }`.

Low-stock pantry threshold is **≤ 25%**, same as web.

---

## 9. API client map

`VivrantApi` is a shell; domain methods are `part` files:

| File | Covers |
|------|--------|
| `auth_api.dart` | login, signup, forgot/reset/change password, logout |
| `today_api.dart` | today aggregate, check-in |
| `nutrition_api.dart` | meals, bulk, water, estimate, suggest |
| `movement_api.dart` | workouts, AI suggest |
| `gym_api.dart` | overview, exercises, sessions, live session, plans, drafts, machines |
| `wellness_api.dart` | sleep, hydration, mindfulness, journal, habits, challenges |
| `household_api.dart` | groceries, pantry, spending |
| `ai_api.dart` | reports, chat, insights, reminders |
| `profile_api.dart` | profile, avatar, prefs, goals, history, support, notifications, search, FCM, archive, export |
| `admin_api.dart` | staff endpoints |

Conventions:

- Base URL: `Env.apiBaseUrl`
- JSON `{ "ok": true, … }` / `{ "error": "…" }`
- Connect timeout 12s, receive timeout 20s (AI calls may need the longer receive window)

Full path list: [`MOBILE_API_SPEC.md`](./MOBILE_API_SPEC.md) and web complete docs §13.

---

## 10. Theme

Botanical teal aligned with web tokens (`lib/core/theme/`).

| Token | Light |
|-------|--------|
| Accent | `#0E7C66` |
| Accent deep | `#0A5C4C` |
| Cyan | `#2A9D8F` |
| Ink | `#14221B` |
| Paper / body | `#E7EEE9` / `#EEF4F0` |
| Card | `#F6FAF7` |

Dark theme uses matching dark tokens. Member preference `theme: light | dark | system` is stored in `user_settings` and applied in-app.

Brand assets: `assets/brand/vivrant-mark.png` (launcher + mark). Native splash is color-only; Flutter `SplashScreen` draws the centered glow.

---

## 11. Push notifications

1. Initialize Firebase in the app
2. Request permission
3. `POST /api/device-tokens` with `{ "token", "platform": "android" | "ios" }`
4. Unregister with `DELETE /api/device-tokens` on logout

Server fan-out is documented in the web [`NOTIFICATIONS.md`](https://github.com/Neverbeast24/vivrant-server/blob/main/NOTIFICATIONS.md). Staff broadcasts and ticket events reach native devices the same way as web push.

---

## 12. Archive and backup

Deleting a meal, workout, expense, grocery, pantry item, goal, history row, gym session/plan, habit, challenge, journal note, or reminder **archives** it (soft delete on the server).

- List: `GET /api/mobile/archive`
- Restore: `POST /api/mobile/archive` `{ "id": <archive row id> }`
- Account dump: `GET /api/mobile/archive/export` → JSON file via `path_provider` / share

There is no member hard-delete. Nightly scheduled backups run on the server (`/api/cron/backup`).

---

## 13. Gym specifics

- Catalog demos/machines come from `GET /api/mobile/gym/exercises`
- AI plan: `POST /api/mobile/gym/plans/ai` (days/week, minutes, level, known machines, avoid targets)
- Draft builder: get/put/post/delete `/gym/plans/draft`, then `POST .../draft/commit`
- Live session: `GET/PUT/DELETE /gym/sessions/live` so rest timer and checkboxes survive app restarts and match web
- Reminders: `POST /api/mobile/ai/reminders/sync-gym-plan`

---

## 14. Roles on mobile

`modulesForRole(profile.role)`:

- `user` — `appModules` only
- `admin` — plus admin modules except activity/inquiries
- `super_admin` — all admin modules

The full admin console (service health layout, inquiry quoting UI) is still richest on web.

---

## 15. Project structure

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── shell/                 # AppShell, MoreMenuScreen
├── config/env.dart
├── core/
│   ├── network/api_client.dart
│   ├── theme/
│   ├── utils/                 # parse_quick_list, formatters, validators
│   └── widgets/
├── data/
│   ├── vivrant_api.dart
│   └── api/                   # domain part files
├── shared/
│   ├── constants/             # app_modules.dart, enums
│   ├── models/
│   └── providers/auth_provider.dart
└── features/<feature>/
    ├── <feature>.dart         # barrel
    └── presentation/screens/ (+ optional widgets/)
assets/brand/
docs/MOBILE_API_SPEC.md
docs/VIVRANT_Mobile_Documentation.md   # this file
```

Feature folders: auth, today, nutrition, movement, gym, training, ai, sleep, hydration, mindfulness, journal, habits, groceries, pantry, kitchen, spending, reports, profile, support, notifications, archive, onboarding, search, admin, wellness.

---

## 16. Backend checklist (for local pairing)

1. Clone and run [vivrant-server](https://github.com/Neverbeast24/vivrant-server) (`npm run dev` on `:3000`)
2. Real Supabase keys in `.env.local` (`SUPABASE_SECRET_KEY` required for login)
3. `NEXT_PUBLIC_APP_URL=http://localhost:3000`
4. Point Flutter `API_BASE_URL` at that host (emulator `10.0.2.2`, device LAN IP, or Vercel HTTPS)

Existing host routes the app uses today: `/api/auth/*`, `/api/mobile/**`, `/api/search`, `/api/device-tokens`.

---

## 17. Testing and quality

```bash
flutter analyze
flutter test
```

Keep feature screens behind barrels so `router.dart` stays a catalog. Prefer existing widgets over one-off chrome.

---

## 18. Related docs

| Doc | Purpose |
|-----|---------|
| [`README.md`](../README.md) | Short overview + quick start |
| [`docs/MOBILE_API_SPEC.md`](./MOBILE_API_SPEC.md) | REST contract |
| [Web complete docs](https://github.com/Neverbeast24/vivrant-server/blob/main/docs/VIVRANT_Complete_Documentation.md) | Product, schema, AI, cron, security |
| [Web SETUP](https://github.com/Neverbeast24/vivrant-server/blob/main/SETUP.md) | Env, OAuth, Vercel |
| [Notifications](https://github.com/Neverbeast24/vivrant-server/blob/main/NOTIFICATIONS.md) | FCM |

---

## License

Academic and research purposes.
