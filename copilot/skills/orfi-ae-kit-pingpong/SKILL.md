---
name: orfi-ae-kit-pingpong
description: Architect role — run the autonomous architect↔executor ping-pong loop over the relay files via Herdr until DONE, blocked, or stopped. Wait timeouts trigger status checks, not cancellation.
---

You are acting as the **Architect** and you are about to drive the autonomous **ping-pong loop**: relay a task to the executor, nudge it through Herdr, wait, read its result, and iterate — without the user between hops. The user invoked this deliberately; never start this loop on your own initiative.

## Gate

Require Herdr: run `test "${HERDR_ENV:-}" = 1`. If it fails, say you are not running inside Herdr and that the manual relay flow (`/orfi-ae-kit-relay-to-executor` → user nudges → `/orfi-ae-kit-relay-read-result`) still works, then STOP.

Resolve the **helper-files root**: read `.orfi-kits/helper-files-root` in the current repo. If missing, STOP and run `/orfi-ae-kit-set-helper-files-root` — ask the user for the absolute path (never guess; no default). Define `<kit-root>` = `<helper-files-root>/orfi-kits`.

## Discover the executor pane

Run `herdr pane list --workspace "$HERDR_WORKSPACE_ID"` and select panes whose `label` equals `executor` **case-insensitively** and whose `cwd` is this repo. Zero matches → report "no executor pane found" and STOP. More than one → show them and ask the user to pick. Never guess and never look in other workspaces. Note the pane's `pane_id` — use it for every nudge, wait, and read below.

## Initial task

Take the task from the user's invocation or the current conversation context — same convention as `/orfi-ae-kit-relay-to-executor`. If neither yields a clear task, ask the user before starting.

## The loop

Each round:

1. **STOP check.** If `<kit-root>/relay/STOP` exists: delete it, report "ping-pong stopped by user at round N" plus what was in flight, and STOP.
2. **Relay.** Write the task with the exact procedure of `/orfi-ae-kit-relay-to-executor` (overwrite `<kit-root>/relay/relay-to-executor.md`, update the session-state RELAY FILE STATE note).
3. **Pre-flight.** `herdr pane get <executor-pane>` — the executor must be `idle` or `done` before receiving a nudge. If `working`, wait with `herdr wait agent-status <executor-pane> --status idle --timeout 120000`. A timeout is only a status-check interval: check the same pane and continue waiting while it is working. Never interrupt or resend a task because time elapsed. If blocked on a UI requiring user input, inspect the UI and STOP. If the pane disappears, loses its agent, or remains unknown after a pane read, report that concrete problem and STOP.
4. **Nudge.** Record the pane's current `revision`, then `herdr pane run <executor-pane> "/orfi-ae-kit-relay-read-task"`.
5. **Wait.** `herdr wait agent-status <executor-pane> --status done --timeout 600000`. This is a status-check interval, not a task deadline. On timeout, check the STOP sentinel and `herdr pane get <executor-pane>`. If still `working`, repeat the wait without nudging, interrupting, restarting, or resending the task. Remain idle while the executor works; do not investigate, edit, or verify in parallel unless the user explicitly requests separate work. If `idle` or `done`, confirm activity for this dispatch through the observed working-to-settled transition, a changed revision or lifecycle sequence, or a fresh matching result relay. Do not accept a stale relay or old idle state. If blocked on a UI requiring user input, inspect and report it and STOP. If the pane disappears, loses its agent, or remains unknown after a pane read, report that concrete problem and STOP. Elapsed time or an unchanged revision alone never proves the executor is stuck. Do NOT chain a working wait before the idle/done wait.
6. **Read the result.** Follow `/orfi-ae-kit-relay-read-result` in this pane: read `<kit-root>/relay/relay-to-architect.md` in full and review it critically.
7. **Log.** Append one line to the RELAY FILE STATE section of your own session-state file — `CLAUDE-SESSION-STATE.md` if you are Claude Code, `COPILOT-SESSION-STATE.md` if you are Copilot CLI: round number, direction, one-sentence summary.
8. **Decide.** Stop if the result contains `## Status: DONE`, or if you judge no follow-up is needed — report the outcome to the user. Otherwise formulate the follow-up task and go to 1.

## Hard rules

- There is no round cap; the loop is done-marker driven with the stops above.
- STOP conditions, whichever comes first: done-marker; either agent blocked on a UI requiring user input; an unavailable or unreconcilable agent/pane; the STOP sentinel; the user explicitly cancelling or pausing the loop. A wait timeout is not a STOP condition and there is no task-duration limit.
- Continuing a wait after its status-check interval expires is normal listening, not retrying executor work. Never retry failed task actions silently; review a returned relay question and give a bounded follow-up within the user’s authorization. Stop only when the actual blocker requires user input or a STOP condition applies.
- Herdr never carries task or result content — only the nudge command and status. The relay files are the sole data channel.
- You still never implement the executor's task yourself.
