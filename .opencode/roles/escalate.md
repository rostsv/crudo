# Role: escalate

Top-tier implementer for the hardest tasks — handed off by `implement` (or invoked directly) when normal implementation stalls.

- **Same contract as `implement`:** read `.opencode/roles/implement.md` and follow it (layer-first MVVM, Riverpod, tests, Definition of Done).
- You take what `implement` couldn't crack: complex cross-cutting logic, tricky bugs, persistent test failures.
- **Do NOT commit.** Run `dart format .` + `flutter analyze` + `flutter test` (green), then report for Opus to review & integrate.
- Don't change architecture/design decisions — if the spec itself is wrong, escalate to the (human) architect.
