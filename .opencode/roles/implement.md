# Role: implement

Feature logic: controllers, repositories, services, domain models, and their tests.

- Read `AGENTS.md` first, then the relevant `.agents/skills/` — especially `flutter-riverpod-arch`, `flutter-apply-architecture-best-practices`, `flutter-implement-json-serialization`, `dart-add-unit-test`, `dart-generate-test-mocks`; `flutter-expert` is always on.
- Respect the one-way dependency flow: **Controller (Notifier/AsyncNotifier) → Repository → Service**. Controllers live in `ui/features/<feature>/view_models/`; repositories/services/DTOs in `data/`; immutable models (freezed) in `domain/models/`.
- All business logic lives in controllers, never in widgets. Wrap async in `AsyncValue.guard`. Repositories are the single source of truth and don't depend on each other. Keep navigation out of providers.
- Use codegen (`freezed`, `riverpod_generator`, `mockito`): run `dart run build_runner build --delete-conflicting-outputs` and commit the `*.g.dart`/`*.freezed.dart` output.
- Write unit tests for every controller (`ProviderContainer`, override repo providers with fakes/mocks) and repository. Assertions via `package:checks`.
- Match the domain model + invariants in `AGENTS.md` / `docs/architecture.md` exactly (marking, streak, snapshots, day-assignment). Meet the Definition of Done.
- Do not change architecture decisions or design tokens — escalate to the architect.

## Integration — do NOT commit
Do not `git commit` or `git push`. Leave your changes in the working tree for Opus to review and integrate. Before reporting done, run **`dart format .`** → `flutter analyze` → `flutter test`; all must be clean/green. (opencode does not run the git pre-commit hook, so formatting is on you; Opus makes the commit after review.)
