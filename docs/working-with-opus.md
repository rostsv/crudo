# Working with Opus — operator guide

How you (the human) drive Opus (Claude Code, the architect/orchestrator) day to day. Companion to `workflow.md` (which is the agent-facing loop). Read this when you forget the rhythm.

## Roles
- **You** — vision, product decisions, approvals, "what's next," and the relay to the opencode workers.
- **Opus** — brainstorms, writes specs & plans, reviews worker diffs, integrates (commits), keeps the docs the source of truth. Does **not** mass-write feature code.
- **opencode workers** (`ui`/`implement`/`build`/`review`) — implement one well-specified task at a time.

## Opus has no memory across sessions
Every new session starts blank. Continuity lives **only in files** — `AGENTS.md` → `docs/` → git. So:
- Every decision must land in a committed file (Opus does this). **Never leave a conclusion only in chat before you clear.**
- To resume, Opus reads `AGENTS.md` → `git log` → newest `docs/plans/` → first unchecked task.

## When to `/clear`
Context is per-session and gets auto-summarized when long (lossy). Clearing is **cheap** — Opus rebuilds from files.
- **Clear at phase boundaries, after committing:** spec done · plan done · feature merged · switching feature or topic · context feels bloated/slow.
- **Don't clear** mid-decision when the conclusion isn't committed yet — commit first, then clear.
- Prefer short, file-anchored sessions over one giant session.

## The plan → execute loop (one feature/usable point at a time)
1. **Brainstorm** with Opus → it writes the **spec** → `docs/specs/` → commit. *(you approve)*
2. **Plan** → Opus runs `writing-plans` → `docs/plans/` (bite-size TDD tasks) → commit. *(you approve)*
3. **Execute** → you hand the plan to the opencode `implement`/`build` worker → it does the tasks + commits (pre-commit hook gates format/analyze) → tell Opus "done." *(no Opus session needed while it runs)*
4. **Review / integrate** → Opus reviews the diff (+ the `review` worker for risky/feature diffs) → fixes → push.
5. Repeat for the next spec.

## Practical session rhythm
- **Session A** (with Opus): brainstorm + spec + plan → commit → `/clear`.
- *(run the worker in opencode — separate, no Opus session)*
- **Session B** (with Opus): "review the X implementation" → Opus reviews the commits → integrate → `/clear`.

Short single features can stay in one session through plan → review.

## Picking a worker model
See `docs/architecture.md` / `opencode.json`. Quick: `build` (DeepSeek Flash) = boilerplate/codegen; `implement` (MiniMax) = logic/tests; `ui` (Kimi) = screens; `review` (Qwen 3.7 Max) = selective second opinion on risky diffs only.
