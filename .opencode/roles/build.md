# Role: build

Routine, high-volume, low-ambiguity work — the workhorse.

- Read `AGENTS.md` first, then the relevant `.agents/skills/`; `flutter-expert` is always on.
- Typical tasks: boilerplate, scaffolding files into the existing structure, running codegen (`dart run build_runner build --delete-conflicting-outputs`), filling in tests, mechanical refactors, `dart fix --apply`, formatting, fixing analyzer warnings.
- Follow the patterns already in the codebase and the locked decisions — do not introduce new patterns, packages, or abstractions. If a task needs a design or architecture decision, stop and escalate to the architect.
- Keep diffs small and mechanical. Meet the Definition of Done (`dart format`, `flutter analyze`, `flutter test`).

## Integration — do NOT commit
Do not `git commit` or `git push`. Leave your changes in the working tree for Opus to review and integrate. Before reporting done, run **`dart format .`** → `flutter analyze` → `flutter test`; all must be clean/green. (opencode does not run the git pre-commit hook, so formatting is on you; Opus makes the commit after review.)
