# `lib/` map

Flutter source for VIVRΛNT Mobile. **Read [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) before adding files.**

```text
lib/
├── main.dart                 # entry
├── app/                      # VivrantApp, GoRouter, tab shell
├── config/                   # dart-defines + optional Supabase
├── core/                     # theme, widgets, HTTP, utils, push
├── data/                     # VivrantApi (REST) — part files in api/
├── shared/                   # models, constants, Riverpod providers
└── features/<module>/        # one product area each
    ├── <module>.dart         # barrel (import this from app/router.dart)
    ├── data/                 # optional non-UI helpers
    └── presentation/
        ├── screens/
        └── widgets/
```

Import feature barrels from `app/`. Put cross-module UI in `core/widgets/` (export from `widgets.dart`). Put REST methods in the matching `data/api/*_api.dart` part file.
