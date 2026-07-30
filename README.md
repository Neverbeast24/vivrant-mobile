# VIVRΛNT Mobile

### Long live life

> **Every Choice Shapes Your Health.**

**VIVRΛNT** (stylized from *vibrant*) is the official Flutter companion to [VIVRΛNT Web](https://github.com/). It brings the full member workspace to **iOS** and **Android**: daily check-ins, nutrition, movement, gym, sleep, hydration, mindfulness, journal, habits, groceries, pantry, spending, reports, and Ask VIVRΛNT AI coaching.

Former working name: VIVA (Virtual Intelligent Vitality Assistant).

---

## About

This app mirrors the member experience from the Next.js web platform (`viva-server` / `vivrant-server`):

- Botanical teal theme (jade / forest / sea-glass) aligned with web design tokens
- Bottom navigation for Today · Nutrition · Move · Ask · More
- Full module list under **More** (Gym, Sleep, Hydration, Mindfulness, Journal, Habits, Groceries, Pantry, Spending, Reports, Profile, Help, Notifications)
- Talks to the web host over REST (`/api/auth/*`, `/api/mobile/*`, `/api/device-tokens`)

Domain CRUD and Gemini coaching stay on the server. Flutter never embeds `GEMINI_API_KEY`.

---

## Features (parity with web member dashboard)

| Module | Capabilities |
|--------|----------------|
| **Today** | Daily check-in, live stats, quick actions |
| **Nutrition** | Meal log, macros, water, AI meal estimate |
| **Movement** | Workout log, AI workout suggestions |
| **Gym** | Demos, machines, sessions, AI training plans |
| **Sleep / Hydration / Mindfulness** | Logging + AI coaches |
| **Journal** | Entries + AI reflection |
| **Habits** | Daily habits + weekly challenges |
| **Groceries & Pantry** | Lists, stock levels, AI grocery plan, low-stock restock |
| **Spending** | Expenses, monthly wellness budget, AI coach |
| **Reports** | Weekly patterns + AI weekly story |
| **Ask VIVRΛNT** | Chat, insights, reminders |
| **Profile** | Health profile, goals, history, preferences |
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

```text
lib/
├── main.dart
├── app/
│   ├── app.dart                 # VivrantApp
│   ├── router.dart              # feature barrel imports only
│   └── shell/                   # AppShell + MoreMenuScreen
├── config/                      # Env / dart-defines
├── core/
│   ├── network/                 # Dio ApiClient (secure token storage)
│   ├── theme/                   # colors + ThemeData (+ theme.dart barrel)
│   ├── utils/                   # formatters, validators, humanize, context extensions
│   └── widgets/                 # one widget per file (+ widgets.dart barrel)
│       ├── brand.dart
│       ├── empty_state.dart / error_view.dart / loading_view.dart
│       ├── gradient_scaffold.dart / page_header.dart / panel.dart
│       ├── icon_well.dart / list_row.dart / module_tile.dart
│       ├── primary_button.dart / progress_bar.dart / score_picker.dart
│       ├── section_label.dart / stat_card.dart / async_body.dart
├── data/
│   ├── vivrant_api.dart         # VivrantApi shell + vivrantApiProvider
│   └── api/                     # part files (domain methods)
│       ├── auth_api.dart
│       ├── today_api.dart
│       ├── nutrition_api.dart
│       ├── movement_api.dart
│       ├── gym_api.dart
│       ├── wellness_api.dart    # sleep, hydration, mindfulness, journal, habits
│       ├── household_api.dart   # groceries, pantry, spending
│       ├── ai_api.dart          # chat, insights, reminders, reports
│       └── profile_api.dart     # profile, goals, settings, support, search, …
├── shared/
│   ├── constants/               # enums.dart (meal/activity/expense/pantry lists)
│   ├── models/                  # one model per file (+ models.dart barrel)
│   └── providers/               # auth_provider
└── features/
    └── <feature>/               # auth, today, nutrition, movement, gym, ai,
        │                        # sleep, hydration, mindfulness, journal,
        │                        # habits, groceries, pantry, spending,
        │                        # reports, profile, support, notifications,
        │                        # onboarding, search
        ├── <feature>.dart       # barrel export
        └── presentation/
            ├── screens/
            └── widgets/         # feature-specific UI pieces (optional)
assets/brand/                    # vivrant-mark.png, logo
docs/MOBILE_API_SPEC.md          # REST contract for viva-server
```

---

## Setup

### Prerequisites

- Flutter SDK (stable) — `flutter doctor` should be clean for Android and/or iOS
- Android Studio / Xcode as needed
- Running or deployed **viva-server** with the mobile REST routes from [`docs/MOBILE_API_SPEC.md`](./docs/MOBILE_API_SPEC.md)

### Install & run

```bash
flutter pub get

# Android emulator → host machine Next.js on :3000 (default in Env)
flutter run

# Physical Android/iOS device on the same Wi‑Fi as your PC
flutter run --dart-define=API_BASE_URL=http://192.168.254.107:3000

# Deployed viva-server
flutter run --dart-define=API_BASE_URL=https://your-app.vercel.app
```

Optional Supabase defines (only needed if the app talks to Supabase directly):

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=SUPABASE_URL=https://gcqbuccazplfpmuhperg.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_publishable_key
```

### Backend (`viva-server`)

1. In `C:\Users\PC\Desktop\viva-server`, copy `.env.example` → `.env.local` if needed.
2. Fill **real** Supabase keys from [Supabase Dashboard → Project Settings → API Keys](https://supabase.com/dashboard/project/gcqbuccazplfpmuhperg/settings/api-keys):
   - `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` / `SUPABASE_PUBLISHABLE_KEY`
   - `SUPABASE_SECRET_KEY`
3. Keep `NEXT_PUBLIC_APP_URL=http://localhost:3000` for local mobile testing.
4. Start the API: `npm run dev` (must listen on `:3000`).

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
        └── More → Gym, Sleep, Hydration, Mindfulness, Journal,
                   Habits, Groceries, Pantry, Spending, Reports,
                   Profile, Support, Notifications
```

---

## Related repos

| Repo | Role |
|------|------|
| `viva-server` / `vivrant-server` | Next.js web + Supabase + Gemini + mobile REST |
| `vivrant-mobile` (this) | Flutter iOS / Android client |

---

## License

Academic and research purposes.
