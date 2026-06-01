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

## Working with opencode workers

The workers (`ui` / `implement` / `build` / `review`) are defined in `opencode.json`; each loads `AGENTS.md` + its role file (`.opencode/roles/<role>.md`) + the `.agents/skills` a task names. **No extra skill needed** — "how to implement / review / boilerplate" lives in the **role file**, not a separate skill. You drive them; Opus reviews + commits.

### Choosing the agent (= the model)
Agent ↔ model is bound in `opencode.json`. The plan's task **`role`** field tells you which to pick.

| Task | Agent | Model |
|---|---|---|
| Boilerplate · codegen · scaffolding · fixups | `build` | DeepSeek V4 Flash (cheapest) |
| Controllers · repos · models · logic · tests | `implement` | MiniMax M2.7 |
| Screens · widgets from `app.css`/prototype | `ui` | Kimi |
| Review a risky diff | `review` | Qwen 3.7 Max (read-only) |
| Hard logic · architecture-y · nasty bug | escalate `implement` → GLM-5.1 / Qwen 3.7 Max |

The plan is dollar-capped, so prefer the cheapest agent that fits; escalate only when needed.

### Run an implementation
1. Pick `implement` (or `build` for mechanical work).
2. Prompt: *"Implement `docs/plans/<plan>.md` task by task. Follow AGENTS.md + your role + the skills each task names. `dart format .` + `flutter analyze` + `flutter test` must be green. Do NOT commit. Report when done."*
3. It works in the same repo. When done → tell Opus → Opus reviews the working-tree diff and commits.

### Run a review
Only for risky diffs (domain logic, auth, a feature merge) — **skip** for mechanical/theme work (the hook + tests + Opus cover those).
1. Pick `review` (read-only — it can't edit).
2. Feed it only the `git diff` + the spec slice + the named skill.
3. It returns `PASS` or a bounded `BLOCK` list.

### Prompt templates (copy-paste)
Select the agent (opencode picker — `Tab` / `@name`), then paste. Prompts stay short — the role file + AGENTS.md carry the *how*; you supply *what* + guardrails.

- **Whole plan** → `@implement`: `Implement docs/plans/<plan>.md task by task. Follow AGENTS.md + your role + the skills each task names. dart format + flutter analyze + flutter test green. Do NOT commit. Report when done.`
- **One task** → `@implement`/`@build`: `Do only Task N of docs/plans/<plan>.md. Same rules: format+analyze+test green, no commit, report.`
- **A screen** → `@ui`: `Implement Task N (the <screen>) of docs/plans/<plan>.md. Match docs/design/prototype/app.css + screens/<x>.jsx exactly. Widget test. No commit. Report.`
- **Review** → `@review`: `Review the working-tree diff (git diff) against docs/specs/<spec>.md and skill <name>. Output PASS or a bounded BLOCK list. Read-only.`

Pattern: **agent = kind of work · prompt = which artifact + "no commit, report."**

### Workers never commit
They format + test + report; Opus reviews and commits (opencode doesn't run the git pre-commit hook, so the worker formats; the hook backstops Opus's commits).

### When to clear opencode context
- **Clear between tasks/features.** Each plan task is self-contained → start each fresh (less drift, fewer tokens on the capped plan).
- Keep context only within one task's implement → fix → green loop.
- Switching agent/role → clear.
