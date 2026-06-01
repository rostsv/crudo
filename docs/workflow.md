a# Crudo — Development Workflow

How the human, Opus (Claude Code), and the opencode worker models collaborate to build Crudo. This is the operating model; `AGENTS.md` carries a short pointer to it and the per-agent rules.

## Roles

- **Human (you)** — vision, domain knowledge, approvals at every gate, and the **relay**: you run the opencode workers and bring their diffs back. Final call on everything.
- **Opus (Claude Code) — architect / orchestrator** — facilitates brainstorming, writes specs and plans, decomposes work into per-task contracts, reviews and verifies diffs, integrates (commits), and keeps `AGENTS.md` + `docs/` the source of truth. Does not mass-produce feature code; it specs and reviews it.
- **opencode workers** — execute one well-specified task each:
  - `ui` (kimi) — screens & widgets, pixel-matching the prototype.
  - `implement` (minimax) — controllers, repositories, services, models, tests.
  - `build` (deepseek) — boilerplate, codegen, test fill-in, mechanical fixups.
- **review** — the `review` worker drafts compressed findings; **Opus verifies them and makes the call**. Review = review worker + Opus, together.

## Dispatch model: manual relay, sequential

Tasks cross the Opus↔opencode boundary as **files**. One task goes fully through implement → review → integrate **before the next** (sequential, on the main working tree — no parallel worktrees for now). The per-task spec is the contract that lets a cheaper worker produce correct code with no context beyond `AGENTS.md` + its role file + the named skill(s).

## The loop (per feature slice)

| # | Phase | Who | Tool / skill | Output |
|---|-------|-----|--------------|--------|
| 1 | **Brainstorm** | you + Opus | `superpowers:brainstorming` | a spec in `docs/specs/` |
| 2 | **Plan** | Opus | `superpowers:writing-plans` | a plan in `docs/plans/` (ordered tasks) |
| 3 | **Delegate** | you relay | opencode worker (`ui`/`implement`/`build`) | a diff in the working tree |
| 4 | **Review** | Opus (+ review worker on risky/feature diffs) | `git diff` + the task's skill + `superpowers:verification-before-completion` | pass/fail + fixes |
| 5 | **Integrate** | Opus + hook | `caveman-commit` + `.githooks/pre-commit` | a commit |
| 6 | **Finish** | Opus | `superpowers:finishing-a-development-branch` | pushed slice |

## Interaction rules (specs & plans)

- During **brainstorm** and **plan**, Opus asks the human **domain questions one at a time** (multiple-choice when possible) — meal/streak/plan rules, edge cases, copy, etc.
- After **each spec** and **each plan**, Opus gives a **brief report** of what's planned before proceeding.
- Specs and plans are approved by the human before moving on (gates below).

## What one spec represents

**One feature or one usable point** — a foundation or a user-visible capability that ships something demoable, sized so its plan is ~3–8 tasks. Vertical where possible (testable end-to-end). Oversized areas are split into multiple specs rather than crammed into one.

## Handoff artifacts

- `docs/specs/<YYYY-MM-DD>-<topic>.md` — the *what / why* (from brainstorm).
- `docs/plans/<YYYY-MM-DD>-<topic>.md` — ordered **tasks** (from writing-plans).
- **Each task block is self-contained** and includes:
  - **Title + role** (`ui`/`implement`/`build`)
  - **Goal** (1–2 lines)
  - **Files** to create/edit
  - **Contract** — the exact provider/state shape, widget API, or repository signature it must produce or consume
  - **Skills** to read (e.g. `flutter-riverpod-arch` + `flutter-add-widget-test`)
  - **Acceptance** — the tests/behavior that prove it's done
  - **Out of scope** — so the worker stays in its lane

## Quality gates

1. Human approves the **spec** before planning.
2. Human approves the **plan** before delegating.
3. **Opus reviews every task diff** against spec + skill; `flutter analyze` + `flutter test` run before commit. The **review worker** runs *selectively* (see below), not on every diff.
4. The **pre-commit hook** (`.githooks/pre-commit`) mechanically enforces `dart format` + `flutter analyze` on every commit, whichever model wrote the code. Enable once per clone: `git config core.hooksPath .githooks`.

## When to run the review worker

The `review` worker (Qwen 3.7 Max, read-only, `.opencode/roles/review.md`) is a **selective second opinion, not a default gate** — Opus reviews every diff, and the pre-commit hook + tests catch mechanical issues. Don't run it blindly.

- **Skip** for: boilerplate · scaffolding · theme tokens · formatting · trivial diffs.
- **Run** for: domain logic (adherence/streak, snapshots, day-assignment, meal-marking) · auth/security · a whole-feature merge.
- **Strict scope** (enforced by the role file): it reviews **only the given diff** vs its spec/skill/invariants; flags only correctness / spec / invariant / security issues; never refactors, re-architects, or raises lint the hook already covers. Output = `PASS` or a bounded `BLOCK` list. Feed it just `git diff` + the spec slice + the named skill — never the whole repo.

## caveman fit

Workers run caveman → compressed *summaries*; **code, commits, and PRs stay normal** (caveman's own boundary). Opus's task specs may be terse, but Opus stays in normal mode for reviews, security notes, and decisions where clarity matters.

## Sequencing

No fixed feature list in this doc — specs are chosen as we go. Only standing rule: **foundations before the features that depend on them.** The concrete backlog and order live in a plan/roadmap when we set one, not in this process doc.

## Resume protocol (any new session)

A new session has no memory of prior conversations — context comes only from durable files. To pick up:

1. `AGENTS.md` loads automatically (via `CLAUDE.md`) — the source of truth; it routes to `docs/`.
2. `git log` + `git status` — what's committed and in flight.
3. Open the active plan in `docs/plans/` — the first **unchecked** task is the next work; its spec in `docs/specs/` is the why.
4. Read the skills that task names before touching code.
5. Resume the loop (delegate → review → integrate); use `superpowers:executing-plans` to drive a plan with checkpoints.

**Plans are the durable progress tracker** — each task is a checkbox in the plan file, ticked when integrated, so any session sees exactly where things stand. Every decision lands in a file (`AGENTS.md` / `docs/` / spec / plan), never only in chat.
