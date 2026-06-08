---
description: Execute one task from the active plan (TDD, gates, report, escalation) — usage /task 1, /task 9a
agent: implement
---

You are executing **one task** from a Crudo implementation plan. Do exactly that task — not the next one, not the whole plan.

## What to do

Task selector: **$ARGUMENTS** (e.g. `1`, `9a`). The first token is the task id; an optional second token is a plan basename glob (else use the newest plan).

Active plan (newest unless overridden): **!`ls -t docs/plans/*.md | head -1`**

1. Read, in order: `AGENTS.md` → your role file → the active plan above → the task's spec (named in the plan header) → every `.agents/skills/` skill the task lists. Do not skip the skills.
2. Find the task block matching the selector (`## Task <id>:`). Read its **Role**, Files, Contract, Steps, Skills, Out of scope.
3. **Role routing:** if the task's Role is **not** your own (`ui` or `build`), delegate the entire task to that subagent (`@ui` / `@build`) with this same instruction and the task id. Otherwise execute it yourself.
4. Execute the task's Steps **in order, exactly as written** — TDD: failing test first, run it red, minimal implementation, run it green. The plan's code blocks are the contract — match the named types/signatures verbatim. Run `dart run build_runner build` after touching any `@freezed`/`@riverpod` file.
5. Stay strictly in the task's scope. Respect its **Out of scope** list. Do not touch files other tasks own. Do not change architecture decisions or design tokens (`docs/design_system.md §5` — dimensions from tokens only).

## Definition of done (this task)

Before reporting, run in this order and confirm green:
- `dart format .` (leaves nothing to change)
- `flutter analyze` (clean)
- `flutter test --timeout=90s` (the task's tests + the full suite — you may break another task's expectations only if the plan says so). **Always pass `--timeout`** — a hanging widget test (infinite `pumpAndSettle`, unclosed stream) otherwise stalls forever. If the run hangs anyway (deadlocked `build_runner`/process the per-test cap can't catch), wrap with `gtimeout 600 <cmd>` (or `timeout 600` on Linux/CI), treat the hang as a failure, find the offending test, and fix it or escalate — never raise the cap to mask it.

Then **invoke `@review` on your working-tree diff** (`git diff`) with the task's spec slice + named skill(s). Fix every `BLOCK` finding and re-run the gates. Only then report.

## Do NOT commit

Leave all changes in the working tree. Opus reviews the diff and makes the commit. opencode does not run the git pre-commit hook, so formatting is on you.

## Report

As your final step, append to `.opencode/handoff/<active-plan-basename>.report.md` (create if missing) a block in the `docs/workflow.md` format:

```
# <plan> — Task <id> Report (<your role>)
## Status: complete | partial | blocked
## Steps
- [x] Step 1 … done
- [ ] Step N … why not
## Verification (paste REAL output, not a summary)
dart format · flutter analyze · flutter test --timeout=90s · build_runner · @review verdict
## Files touched
## Deviations from the plan (what + why)
## Needs Opus / blockers
```

Paste the actual command output — Opus reviews from this file, never from chat.

## On error / stuck

Work the problem, don't thrash:
- **Test red after ~2 honest attempts**, or the contract doesn't compile against the real codebase → **stop editing**, hand off to `@escalate` (top model) with the failing output and what you tried. Do not delete or weaken the test to make it pass.
- **Spec/plan looks wrong** (contract references a type/signature that doesn't exist, two tasks contradict, an invariant can't hold) → **do not invent a fix**. Stop, set report Status `blocked`, write the exact contradiction under "Needs Opus", and stop. This is an architect decision.
- **Task needs something an earlier task should have produced but didn't** → report `blocked`, name the missing symbol/file. Do not stub it silently.
- **A gate fails for a reason outside your diff** (pre-existing breakage) → report it under "Needs Opus", don't try to fix unrelated code.

Never fake green: a skipped test, a weakened assertion, or a `// ignore:` to silence the analyzer is a blocked task, not a done one.
