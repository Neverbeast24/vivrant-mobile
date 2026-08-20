# VIVRΛNT Mobile architecture

This document is the **folder map** for `vivrant-mobile`. Follow it when adding screens, widgets, or API methods so `lib/` stays easy to browse.

REST contracts live in [`MOBILE_API_SPEC.md`](./MOBILE_API_SPEC.md). Full Flutter guide: [`VIVRANT_Mobile_Documentation.md`](./VIVRANT_Mobile_Documentation.md). Product overview lives in the [root README](../README.md) and the [web complete docs](https://github.com/Neverbeast24/vivrant-server/blob/main/docs/VIVRANT_Complete_Documentation.md).

---

## Layers

| Folder | Owns | Must not own |
|--------|------|----------------|
| `lib/app/` | `VivrantApp`, GoRouter, tab shell | Feature UI, API calls |
| `lib/config/` | `--dart-define` env, optional Supabase bootstrap | Widgets |
| `lib/core/` | Theme, shared widgets, HTTP client, formatters | Feature screens |
| `lib/data/` | `VivrantApi` + `part` files per domain | Widgets |
| `lib/shared/` | Models, More-menu catalog, Riverpod providers | Screens |
| `lib/features/<name>/` | One product module | Cross-cutting widgets (those go in `core/widgets/`) |

Dependency direction:

```text
features  →  data, shared, core, config
data      →  core, shared
shared    →  core (theme / models only as needed)
app       →  features (barrels only), shared, core
core      →  config  (and a rare documented exception to features/gym/data)
```

`lib/app/router.dart` imports **feature barrels** (`package` paths like `../features/gym/gym.dart`), never `presentation/screens/*.dart`.

---

## Feature template

Every module under `lib/features/` looks like this:

```text
lib/features/<name>/
├── <name>.dart                 # barrel — library doc + exports
└── presentation/
    ├── screens/                # full pages (one screen per file)
    └── widgets/                # optional, only if used by this feature
```

Add `data/` **only** when the feature has non-UI helpers (constants, device APIs). Gym is the example:

```text
lib/features/gym/
├── gym.dart
├── data/
│   ├── gym_labels.dart         # catalog / muscle / equipment vocabulary
│   └── gym_rest_alert.dart     # rest-timer sound + haptics
└── presentation/
    ├── screens/
    └── widgets/
```

Hubs that only route to other modules (Training, Wellness, Kitchen) still get their own feature folder + barrel.

---

## Where a new file goes

| You are adding… | Put it in… |
|-----------------|------------|
| A new member page | `features/<module>/presentation/screens/<name>_screen.dart` + export from `<module>.dart` |
| UI used by **one** module | `features/<module>/presentation/widgets/` |
| UI used by **two or more** modules | `core/widgets/` (one widget per file) + export from `widgets.dart` |
| A REST method | Matching `data/api/*_api.dart` `part` of `vivrant_api.dart` |
| A JSON type | `shared/models/` + export from `models.dart` |
| A More-menu entry | `shared/constants/app_modules.dart` **and** a route in `app/router.dart` |
| Form option lists | `shared/constants/enums.dart` |
| Theme / spacing | `core/theme/` |
| Parse / format helper | `core/utils/` |

Do **not** drop helpers next to screens (`presentation/gym_labels.dart` is the anti-pattern). If it is not a `Widget`, it does not belong under `presentation/`.

---

## Barrels

Each folder that is a public surface has a short barrel with a library comment:

| Barrel | Path |
|--------|------|
| Feature | `lib/features/<name>/<name>.dart` |
| Widgets | `lib/core/widgets/widgets.dart` |
| Theme | `lib/core/theme/theme.dart` |
| Utils | `lib/core/utils/utils.dart` |
| Models | `lib/shared/models/models.dart` |
| Constants | `lib/shared/constants/constants.dart` |
| Providers | `lib/shared/providers/providers.dart` |

Inside a feature, relative imports (`../widgets/…`) are fine. From **outside** the feature, import the barrel.

---

## Feature catalog

| Feature | Barrel | What it is |
|---------|--------|------------|
| `admin` | `admin.dart` | Staff console (role-gated) |
| `ai` | `ai.dart` | Chat, insights, reminders |
| `archive` | `archive.dart` | Restore / export soft-deleted rows |
| `auth` | `auth.dart` | Splash, login, signup, reset |
| `groceries` | `groceries.dart` | Shopping list |
| `gym` | `gym.dart` | Demos, machines, sessions, programs |
| `habits` | `habits.dart` | Streaks + weekly challenges |
| `hydration` | `hydration.dart` | Water log |
| `journal` | `journal.dart` | Dated notes |
| `kitchen` | `kitchen.dart` | Hub → groceries & pantry |
| `mindfulness` | `mindfulness.dart` | Mood / practice |
| `movement` | `movement.dart` | Daily activity log |
| `notifications` | `notifications.dart` | Inbox |
| `nutrition` | `nutrition.dart` | Meals + macros |
| `onboarding` | `onboarding.dart` | First launch |
| `pantry` | `pantry.dart` | Household stock |
| `profile` | `profile.dart` | Goals, history, preferences |
| `reports` | `reports.dart` | Weekly patterns |
| `search` | `search.dart` | Cross-module search |
| `sleep` | `sleep.dart` | Sleep log |
| `spending` | `spending.dart` | Expenses + budget + sheet |
| `support` | `support.dart` | Member tickets |
| `today` | `today.dart` | Home check-in |
| `training` | `training.dart` | Hub → activity & gym |
| `wellness` | `wellness.dart` | Hub → sleep, water, mood |

---

## Data / API files

`lib/data/vivrant_api.dart` is the only HTTP façade. Domain methods are `part` files:

| File | Domain |
|------|--------|
| `api/auth_api.dart` | Login / signup / reset |
| `api/today_api.dart` | Today payload |
| `api/nutrition_api.dart` | Meals |
| `api/movement_api.dart` | Workouts |
| `api/gym_api.dart` | Gym catalog & plans |
| `api/wellness_api.dart` | Sleep, hydration, mindfulness, journal, habits |
| `api/household_api.dart` | Groceries, pantry, spending |
| `api/ai_api.dart` | Chat, insights, reminders, reports |
| `api/profile_api.dart` | Profile, goals, archive, support, search |
| `api/admin_api.dart` | Staff console |

Add a new endpoint next to its domain, not as a new top-level client.

---

## Naming

- Screens: `<thing>_screen.dart` (`GroceriesScreen`)
- Sheets: `<thing>_sheet.dart`
- Shared widgets: one public widget per file
- Avoid `vivrant_widgets.dart`-style aliases — use `widgets.dart`
