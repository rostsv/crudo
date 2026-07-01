---
name: fix-design
description: Use when the user wants to hand off a Crudo Flutter UI/design fix to another model — off-grid spacing, hardcoded fontSize/Border/Color, wrong or missing design tokens, layout/padding tweaks, visual parity against a screenshot or mockup. Triggers on "/fix-design", "fix this design", "delegate this UI fix".
---

# Fix Design (Crudo)

## Overview
Dispatch ONE Sonnet subagent to apply a described design/UI fix in this Flutter project, honoring the design system, then relay its diff + test result. The user describes **what** to fix and **how**; screenshots are optional file paths.

## Steps

1. **Parse the task** from the invocation args: the *what* + the *how* + any screenshot file paths. If the *how* is missing or the target screen/widget is ambiguous, ask the user ONE clarifying question before dispatching — a vague task produces a bad fix.

2. **Dispatch one subagent** with the Agent tool:
   - `subagent_type: general-purpose`
   - `model: sonnet`
   - foreground (not background) — the user waits on the result
   - `prompt`: the template below, with the task + screenshot paths filled in

3. **Relay the result**: files changed, tokens used, and the `flutter test` outcome. Do **not** commit — leave changes in the working tree for the user to review (per project rule: never auto-commit).

## Subagent prompt template

> You are fixing a UI/design issue in **Crudo**, a Flutter nutrition-adherence app. Work only in the current repo.
>
> **Read first, in order:**
> 1. `AGENTS.md` — architecture, conventions, commands (single source of truth).
> 2. `docs/design_system.md` — the design system. It is **law**: 4px spacing grid + named tokens.
> 3. Any screenshot paths listed below — Read them to see the target visual.
>
> **Hard rules:**
> - Map every value to a design token. A raw `fontSize:`, off-grid `EdgeInsets`, ad-hoc `Border`/`Color`, or magic number is a bug — use the token.
> - Match surrounding widget style, naming, and token usage.
> - After changes, run `flutter test --timeout=90s` (ALWAYS pass the timeout — some tests hang forever). All tests must stay green; fix regressions you cause.
> - Do **not** commit or push. Leave changes staged.
> - Do not expand scope beyond the task below.
>
> **The fix (what + how):**
> {{USER_TASK}}
>
> **Screenshots:** {{SCREENSHOT_PATHS or "none"}}
>
> **Report back:** files changed, which tokens you used (and any raw values you replaced), and the exact `flutter test` summary line.

## Notes
- One task = one subagent. For multiple unrelated fixes, dispatch them separately (or in parallel if independent).
- If the subagent reports failing tests it can't resolve, surface that to the user — don't hide it.
