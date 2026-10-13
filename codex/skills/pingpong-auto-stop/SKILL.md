---
name: pingpong-auto-stop
description: Any role — stop a running architect↔executor ping-pong loop by creating the STOP sentinel, then report loop state.
---

You may be any agent in any pane — architect, executor, or a third session. Your job is to stop a running ping-pong loop.

Resolve the **helper-files root**: read `.orfi-kits/helper-files-root` in the current repo. If missing, STOP and run `/pingpong-set-helper-files-root` — ask the user for the absolute path (never guess; no default). Define `<kit-root>` = `<helper-files-root>/orfi-kits`.

1. Create the empty sentinel file `<kit-root>/relay/STOP` (create the `relay` directory if needed). If it already exists, say so — a stop is already pending.
2. Read the RELAY FILE STATE section of `<kit-root>/CLAUDE-SESSION-STATE.md`, `<kit-root>/COPILOT-SESSION-STATE.md`, and `<kit-root>/CODEX-SESSION-STATE.md` (whichever exist) and report to the user: which round the loop appears to be on and what task is in flight, so they know what stopping interrupts.
3. Explain: the architect checks for this sentinel before every hop, so the loop halts at its next checkpoint and deletes the sentinel. For an immediate abort the user can press Esc/Ctrl+C in the architect's pane instead.

Do not touch the relay files themselves and do not delete the sentinel — the architect consumes it.
