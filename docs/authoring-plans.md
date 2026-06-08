# Authoring Plans — task-block format

How Opus writes a plan in `docs/plans/` so the opencode `/task <id>` command can execute it task-by-task. This is the *format* reference; `docs/workflow.md` is the operating model (who does what), `working-with-opus.md` is the collaboration style.

A plan turns one approved spec (`docs/specs/`) into **ordered, self-contained tasks**. Each task is a contract a cheap worker can execute with no context beyond `AGENTS.md` + its role file + the named skills.

## The contract with `/task`

`.opencode/command/task.md` (`/task <id> [plan-glob]`) parses a plan mechanically. It:

1. Picks the newest `docs/plans/*.md` (or the basename glob you pass as the 2nd token).
2. Finds the block whose header matches **`## Task <id>:`** exactly (`## Task 1:`, `## Task 9a:`).
3. Reads that block's **Role** and routes: the command runs as `implement-flash` (cheap default), then `ui` → `@ui`, `build` → `@build`, `implement` → inline (or `@implement-kimi` if the `kimi` token was passed).
4. Runs the block's **Steps** in order (TDD), then the gates, then `@review`, then writes a report.

So the format is not cosmetic — **a task is only runnable if it is a `## Task <id>:` block with the subheads below.** A prose plan with no task blocks cannot be dispatched.

## Task-block template

Every task is one `## Task <id>:` section with these bold subheads, in this order:

```markdown
## Task <id>: <short title>

**Role:** ui | implement | build   (one word — drives /task routing)

**Goal:** 1–2 lines. What this task produces and why.

**Files:**
- Create / Rewrite / Modify / Test: `path` — note new imports or codegen here

**Contract:**

​```dart
// The EXACT types, signatures, provider/widget/repository shapes the task
// must produce or consume. Verbatim — the worker matches names letter-for-letter.
​```

**Steps (TDD):**

- [ ] 1. **Failing test** — write it, name the file + assertion.
- [ ] 2. **Run — red:** `flutter test --timeout=90s <file>` (quote the expected error).
- [ ] 3. **Implement** the contract (+ `dart run build_runner build` if any `@freezed`/`@riverpod` touched).
- [ ] 4. **Run — green:** `flutter test --timeout=90s <file>`.
- [ ] 5. Gates: `dart format .` · `flutter analyze` · `flutter test --timeout=90s`. Report for review.

**Skills:** `.agents/skills/<skill>` … — every skill the task needs. The worker reads them; do not omit.

**Out of scope:** what the worker must NOT touch (files other tasks own, architecture/token changes).

**Acceptance:** (optional) the behavior/tests that prove done, if not obvious from Steps.
```

## Rules

- **Role is one logical word** — `ui`, `implement`, or `build` — because `/task` string-matches it for routing. A descriptive parenthetical is fine (`**Role:** ui (Flutter UI engineer)`) but the first token must be the routing word. (`ui` = screens/widgets · `implement` = controllers/repos/services/models/tests · `build` = boilerplate/codegen/mechanical.) Role stays *logical*: `implement` runs as the cheap `implement-flash` agent by default, or `implement-kimi` when you pass the `kimi` token to `/task` — the model agent is a dispatch choice, never written into the plan.
- **Contract is verbatim.** Real Dart, named types and signatures the worker copies. No `// TODO`, no placeholders, no pseudo-code. If a type doesn't exist yet, an earlier task must produce it (and say so).
- **Steps are TDD and ordered.** Failing test → red → minimal impl → green → gates. The worker runs them literally.
- **Always `--timeout=90s` on every `flutter test`** (per `AGENTS.md` / always-timeout rule) — some widget tests hang forever; the cap turns a hang into a failure. For deadlocks the per-test cap can't catch (`build_runner`/process), wrap with `gtimeout 600`.
- **No per-task `git commit` step.** Tasks end at "report for review." Opus reviews the working-tree diff and commits. opencode skips the pre-commit hook, so the worker formats; the hook backstops Opus's own commits.
- **No superpowers `REQUIRED SUB-SKILL` line** — opencode has no superpowers; reference `.agents/skills/<name>` paths instead. Keep the header tool-agnostic.
- **Strict scope per task.** The `Out of scope` list keeps a worker from editing files another task owns. One task = one lane.

## Plan header (above Task 1)

Open with orientation the worker reads before any task:

- **One-line worker note** — what the plan is, the spec path (`docs/specs/…`), "read `.agents/skills/<x>` first."
- **Goal** — the feature slice in 1–2 lines.
- **Decisions table** — every fork settled in brainstorm (so no task re-litigates design).
- **File changes** — which files the whole plan touches (a map; each task narrows it).

Shared contracts (state shapes, widget APIs) can live in header sections that tasks point to (`**Contract:** see "Contract — partitioning" below`) — fine, as long as everything a task needs sits **under its `## Task <id>:` heading** (the block runs from its header to the next `## Task` / end of file).

## Single-task plans

A small slice can be one `## Task 1:` block. Still use the block — `/task 1` needs the header. Don't ship a prose-only "Steps" plan: the selector won't find it and Role routing has nothing to read.

## Size

One spec → ~3–8 tasks (`docs/workflow.md`). Vertical where possible. Bigger → split into multiple specs, not a 20-task plan.

## Worked examples

- Multi-task: `docs/plans/2026-06-07-s05-1-snooze-overdue.md` (canonical `## Task N:` blocks with Role/Goal/Files/Contract/Steps/Skills/Acceptance).
- Single-task: `docs/plans/2026-06-08-s08-swap-sheet-refinements.md`.

## How execution flows

Opus writes plan → human approves → in opencode: `/task 1` (then `/task 2`, … sequentially, one through review+integrate before the next) → worker does TDD + gates + `@review` → writes `.opencode/handoff/<plan-basename>.report.md` (no commit) → Opus reviews `git diff` + report → commits → tick the task's checkbox in the plan. Plans are the durable progress tracker. See `docs/workflow.md` for the full loop and quality gates.
