# VIVRΛNT Mobile

### Long live life

> **Every Choice Shapes Your Health.**

**VIVRΛNT** (stylized from *vibrant*) is the official Flutter companion to [VIVRΛNT Web](https://github.com/Neverbeast24/vivrant-server). It brings the full member workspace to **iOS** and **Android**: daily check-ins, nutrition, training, wellness, journal, habits, kitchen, spending, reports, archive, and Ask VIVRΛNT AI coaching.

Former working name: VIVA (Virtual Intelligent Vitality Assistant).

---

## Repositories

| Repo | Role |
|------|------|
| [vivrant-server](https://github.com/Neverbeast24/vivrant-server) | Next.js web app, admin console, Supabase + Gemini, mobile REST API |
| [vivrant-mobile](https://github.com/Neverbeast24/vivrant-mobile) (this) | Flutter iOS / Android client |

---

## About

This app mirrors the member experience from the Next.js web platform ([vivrant-server](https://github.com/Neverbeast24/vivrant-server)):

- Botanical teal theme (jade / forest / sea-glass) aligned with web design tokens
- Bottom navigation for Today · Nutrition · Move · Ask · More
- Full module list under **More** (Training, Wellness, Journal, Habits, Kitchen, Spending, Reports, Search, Profile, Archive, Help, Notifications)
- Talks to the web host over REST (`/api/auth/*`, `/api/mobile/*`, `/api/device-tokens`)

Domain CRUD and Gemini coaching stay on the server. Flutter never embeds `GEMINI_API_KEY`.

---

## Features (parity with web member dashboard)

| Module | Capabilities |
|--------|----------------|
| **Today** | Daily check-in, live stats, quick actions |
| **Nutrition** | Meal log, macros, water, AI meal estimate, easy-entry / sheet-style logging |
| **Training** | Workout log, gym demos, machines, sessions, saved AI programs |
| **Sleep / Hydration / Mindfulness** | Logging + AI coaches (Wellness hub) |
| **Journal** | Entries + AI reflection |
| **Habits** | Daily habits + weekly challenges |
| **Kitchen** | Grocery lists, pantry stock, AI grocery plan, low-stock restock, easy-entry paste |
| **Spending** | Expenses, monthly wellness budget, sheet view, AI coach |
| **Reports** | Weekly patterns + AI weekly story |
| **Ask VIVRΛNT** | Chat, insights, reminders |
| **Profile** | Health profile, goals, history, preferences |
| **Archive** | Restore or permanently delete soft-deleted records |
| **Support** | Member tickets |
| **Notifications** | Inbox + FCM device registration |

Staff/admin tools are available in-app for elevated roles (overview, users, tickets, audit). The full admin console remains richest on web.

---

## Tech stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter 3.35+ / Dart 3.9+ |
| State | Riverpod |
| Navigation | GoRouter |
| HTTP | Dio + Flutter Secure Storage (JWT) |
| Fonts | Space Grotesk, Bricolage Grotesque, Instrument Serif (`google_fonts`) |
| Charts | fl_chart |
| Push | Firebase Messaging → `POST /api/device-tokens` |

---

## Project structure

Full conventions (where new files go, barrels, API parts) are in [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md). Short map:

```text
lib/
├── main.dart                      # entry (Supabase + ProviderScope)
├── app/
│   ├── app.dart                   # VivrantApp (theme, router, idle warning)
│   ├── router.dart                # GoRouter — feature barrels only
│   └── shell/                     # AppShell + MoreMenuScreen
├── config/                        # Env / dart-defines, optional Supabase
├── core/
│   ├── network/                   # Dio ApiClient (secure token storage)
│   ├── services/                  # FCM push registration
│   ├── theme/                     # colors, layout, ThemeData (theme.dart)
│   ├── utils/                     # formatters, validators, paste, export
│   └── widgets/                   # one shared widget per file (widgets.dart)
├── data/
│   ├── vivrant_api.dart           # VivrantApi shell + vivrantApiProvider
│   └── api/                       # part files (domain REST methods)
│       ├── auth_api.dart
│       ├── today_api.dart
│       ├── nutrition_api.dart
│       ├── movement_api.dart
│       ├── gym_api.dart
│       ├── wellness_api.dart      # sleep, hydration, mindfulness, journal, habits
│       ├── household_api.dart     # groceries, pantry, spending
│       ├── ai_api.dart            # chat, insights, reminders, reports
│       ├── profile_api.dart       # profile, goals, archive, support, search
│       └── admin_api.dart
├── shared/
│   ├── constants/                 # app_modules.dart, enums.dart
│   ├── models/                    # one model per file (models.dart)
│   └── providers/                 # auth, theme, shell tab, module cache
└── features/
    └── <feature>/                 # see catalog below
        ├── <feature>.dart         # barrel with library docs
        ├── data/                  # optional (gym labels, rest timer)
        └── presentation/
            ├── screens/
            └── widgets/

assets/brand/                      # vivrant-mark.png, logo
docs/ARCHITECTURE.md               # folder rules for contributors
docs/MOBILE_API_SPEC.md            # REST contract for viva-server
docs/VIVRANT_Mobile_Documentation.md
```

**Features:** `admin`, `ai`, `archive`, `auth`, `groceries`, `gym`, `habits`, `hydration`, `journal`, `kitchen`, `mindfulness`, `movement`, `notifications`, `nutrition`, `onboarding`, `pantry`, `profile`, `reports`, `search`, `sleep`, `spending`, `support`, `today`, `training`, `wellness`.

Hubs: **Training** (`/move`) → activity + gym; **Wellness** (`/wellness`) → sleep / water / mood; **Kitchen** (`/kitchen`) → groceries + pantry.

---

## Setup

### Prerequisites

- Flutter SDK (stable) — `flutter doctor` should be clean for Android and/or iOS
- Android Studio / Xcode as needed
- Running or deployed **[vivrant-server](https://github.com/Neverbeast24/vivrant-server)** with the mobile REST routes from [`docs/MOBILE_API_SPEC.md`](./docs/MOBILE_API_SPEC.md)

### Install & run

```bash
flutter pub get

# Android emulator → host machine Next.js on :3000 (default in Env)
flutter run

# Physical Android/iOS device on the same Wi‑Fi as your PC
flutter run --dart-define=API_BASE_URL=http://192.168.254.107:3000

# Deployed vivrant-server
flutter run --dart-define=API_BASE_URL=https://your-app.vercel.app
```

Optional Supabase defines (only needed if the app talks to Supabase directly):

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=SUPABASE_URL=https://gcqbuccazplfpmuhperg.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_publishable_key
```

### Backend ([vivrant-server](https://github.com/Neverbeast24/vivrant-server))

1. Clone and set up the web repo: [github.com/Neverbeast24/vivrant-server](https://github.com/Neverbeast24/vivrant-server).
2. Copy `.env.example` → `.env.local` if needed.
3. Fill **real** Supabase keys from [Supabase Dashboard → Project Settings → API Keys](https://supabase.com/dashboard/project/gcqbuccazplfpmuhperg/settings/api-keys):
   - `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` / `SUPABASE_PUBLISHABLE_KEY`
   - `SUPABASE_SECRET_KEY`
4. Keep `NEXT_PUBLIC_APP_URL=http://localhost:3000` for local mobile testing.
5. Start the API: `npm run dev` (must listen on `:3000`).

Auth and `/api/mobile/**` go through this host. Flutter never embeds `GEMINI_API_KEY` or `SUPABASE_SECRET_KEY`.

Existing endpoints already usable today:

- `POST /api/auth/login|signup|forgot-password|reset-password` (login returns JWTs for mobile)
- `GET /api/search`
- `POST|DELETE /api/device-tokens`
- Full `/api/mobile/**` catalog in [`docs/MOBILE_API_SPEC.md`](./docs/MOBILE_API_SPEC.md)

---

## Theme (from web)

| Token | Light hex |
|-------|-----------|
| Accent | `#0E7C66` |
| Accent deep | `#0A5C4C` |
| Cyan | `#2A9D8F` |
| Ink | `#14221B` |
| Paper / body | `#E7EEE9` / `#EEF4F0` |
| Card | `#F6FAF7` |

Brand wordmark: **VIVRΛNT** · tagline **Long live life**.

---

## Application flow

```text
Splash → Onboarding (first launch) → Login / Signup
   → Today shell
        ├── Nutrition / Move / Ask (tabs)
        └── More → Training, Wellness, Journal, Habits, Kitchen,
                   Spending, Reports, Search, Profile, Archive,
                   Support, Notifications
```

---

## Docs

| Doc | Purpose |
|-----|---------|
| [docs/VIVRANT_Mobile_Documentation.md](./docs/VIVRANT_Mobile_Documentation.md) | **Canonical** Flutter docs (nav, features, auth, widgets, API map) |
| [docs/MOBILE_API_SPEC.md](./docs/MOBILE_API_SPEC.md) | REST contract for vivrant-server |
| [Web complete docs](https://github.com/Neverbeast24/vivrant-server/blob/main/docs/VIVRANT_Complete_Documentation.md) | Shared product, schema, AI, cron |

---

## License

Academic and research purposes.
