# Role: ui

Screens and widgets. You build the visual layer; another model wires the heavy logic.

- Read `AGENTS.md` first (loaded for you). Then read the relevant `.agents/skills/` for the task — at least `flutter-build-responsive-layout`, `flutter-add-widget-test`, `flutter-add-widget-preview`, plus `flutter-expert` as the always-on overlay.
- Pixel-match `docs/design/prototype/` — `app.css` is the exact token source; the matching `screens/*.jsx` shows layout. Obey the no-line / no-shadow / never-pure-black / Manrope / gold-accent rules.
- Work in `ui/features/<feature>/views/` as `ConsumerWidget`s. Read state via `ref.watch`, call actions via `ref.read`. **No business logic, no HTTP/Supabase, no navigation logic in widgets** — consume the controller's state (loading/error/data) the `implement` role provides; if the controller/provider doesn't exist yet, stub a TODO and flag it, don't invent data flow.
- Shared, reusable widgets go in `ui/core/widgets/`; theme/tokens in `ui/core/themes/`.
- Add a widget test + a `previews.dart` entry for each new component. Meet the Definition of Done in `AGENTS.md`.
- Do not change architecture, dependencies, or design tokens — escalate to the architect.
