# Crudo

Ingredient-first nutrition adherence app — Crudo reminds you to eat what you already planned, and holds you accountable.

A Flutter app (mobile-first). The product, design, and architecture are fully specified; implementation is in progress.

## Documentation

- [`docs/product.md`](docs/product.md) — product definition, MVP scope, onboarding flow, screens.
- [`docs/design_system.md`](docs/design_system.md) — visual language: colors, type, components.
- [`docs/architecture.md`](docs/architecture.md) — stack, domain model, folder layout, conventions.
- [`docs/design/prototype/`](docs/design/prototype/) — exported HTML/React design prototype (the pixel-perfect target).
- [`CLAUDE.md`](CLAUDE.md) — guidance for working in this repo.

## Getting started

```bash
flutter pub get      # install dependencies
flutter run          # run on a connected device/simulator
flutter analyze      # static analysis
flutter test         # run tests
```

Requires the Dart SDK `^3.11.5` (see `pubspec.yaml`).

## Architecture

Layer-first MVVM with Riverpod for state and `go_router` for navigation. Source lives under `lib/`:

- `ui/features/<feature>/` — `views/` (widgets) + `view_models/` (Riverpod controllers)
- `ui/core/` — shared themes & widgets
- `domain/models/` — immutable domain models
- `data/` — `repositories/`, `services/`, `models/`
- `config/`, `routing/`, `utils/`

See `docs/architecture.md` for the full breakdown and the project skills in `.agents/skills/`.
