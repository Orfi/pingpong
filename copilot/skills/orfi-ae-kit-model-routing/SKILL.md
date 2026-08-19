---
name: orfi-ae-kit-model-routing
description: Read or update the model-routing config — report the high (thinking) and low (execution) model tiers for this runtime, or set them with `high <model>` / `low <model>`.
---

You are managing **model routing** for this session. The config file is
`<kit-root>\MODEL-ROUTING.md`, where `<kit-root>` = `<helper-files-root>\orfi-kits`.

Resolve the **helper-files root** first: read `.orfi-kits/helper-files-root` in the current repo. If it is missing, STOP and run `/orfi-ae-kit-set-helper-files-root` — ask the user for the absolute path (never search for, infer, or guess a location; no default), then continue. There is no default path — do not fall back to any hard-coded location.

**If `<kit-root>\MODEL-ROUTING.md` does not exist**, create it with the placeholder template below, then continue. Never overwrite an existing file.

```
# Model Routing

> The session runs on the high model. Execution and mechanical work are
> delegated to spawned agents on the low model. `/model` overrides the high
> model for the current pane only — it never writes back here.

## Claude Code
- high_model: claude-opus-4-6
- low_model: claude-sonnet-4-6

## OpenCode
- high_model: deepseek
- low_model: Big Pickle

## Copilot CLI
- high_model: claude-opus-4-6
- low_model: claude-sonnet-4-6
```

### Report mode (no arguments)

Read the **Copilot CLI** section and state:
- **High model (this session runs on it):** the `high_model` value.
- **Low model (spawned agents run on it):** the `low_model` value.

Then install the routing rules for this conversation:

**High model work — done by this session:**
- Design, architecture
- ADR / PRD review
- Planning
- Orchestration (both roles)
- Reading relay, tasks, plans, ADR/design files
- Verification
- Driving the Executor (pingpong)
- Branch/master sync + merge-conflict resolution

**Low model work — delegate to spawned agents on the low model:**
- Execution / implementation
- Git operations (except branch/master sync and merge conflicts)
- Jira / Atlassian operations
- Persisting state and onboarding files
- Any mechanical / execution-like work

**Verification rule:** if this session is the **Executor**, you verify your
agents' work and report verified results. If this session is the **Architect**,
you review the Executor's *verified* result and do **not** re-run the
verification the Executor already performed.

### Update mode (arguments)

- `high <model>` — replace the `high_model` value in the **Copilot CLI** section.
- `low <model>` — replace the `low_model` value in the **Copilot CLI** section.
- Anything else — ask the user which tier they meant, then update.
- If the user says they don't know the exact model name, prompt interactively for it, then update.

After an update, confirm in one line: which tier changed and the new value.

### Model changes via the runtime's model command

If the user changes the session model (e.g. via `/model` or the Copilot CLI
equivalent), that overrides the high model **for this pane only** — do **not**
write it back to `MODEL-ROUTING.md`. The config changes only via this command,
a prompt that calls it, or manual editing.

Arguments (optional extra notes to include): $ARGUMENTS