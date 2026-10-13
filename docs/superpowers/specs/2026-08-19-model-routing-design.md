# Model Routing for pingpong — Design

Date: 2026-08-19
Status: Approved

## Problem

The kit defines two roles (Architect, Executor) but no model policy. A session
runs one model; spawned agents inherit whatever that session supports. As the
Executor becomes an orchestrator that spawns agents, there is no mechanism to
route *thinking* work to a high model (Opus) and *execution/mechanical* work to
a cheap model (Sonnet) — for any runtime (Claude Code, OpenCode, Copilot CLI, Codex CLI).

## Goal

A global, per-repo-independent, per-runtime model-routing config plus a
slash-command that:

1. Tells the current session which model tier it runs on (high) and which tier
   its spawned agents should use (low).
2. Installs the routing rules for the conversation: high-model work vs
   low-model work.
3. Lets the user change the config via the command, a plain prompt, or manual
   editing.

## Design

### 1. Config file: `MODEL-ROUTING.md`

Lives in `<helper-files-root>\orfi-kits\` — the same directory already used for
relays, orientation, state, and onboarding files. It is global to that root
(shared across repos), not per-repo.

Created by `/pingpong-init` (create-if-absent, never overwrite) and by
`/pingpong-model-routing` if missing. Four sections, one per runtime:

```markdown
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

## Codex CLI
- high_model: gpt-5.1-codex
- low_model: gpt-5.1-codex-mini
```

Placeholders are the current top tier (Opus) / mid tier (Sonnet) for Claude
Code and Copilot CLI; OpenCode uses `deepseek` (high) / `Big Pickle` (low).
These are initial placeholders only — the whole point is they are editable.

### 2. New command per runtime

- Claude Code + OpenCode: `claude/commands/pingpong-model-routing.md`
  (both runtimes share the command source, per the kit's existing layout).
- Copilot CLI: `copilot/skills/pingpong-model-routing/SKILL.md` (adapted
  copy, per existing parity).
- Codex CLI: `codex/skills/pingpong-model-routing/SKILL.md` (adapted copy,
  per existing parity).

Three modes:

| Mode | Trigger | Behavior |
|---|---|---|
| Report | no arguments | Read the matching runtime section; state high/low models; install routing rules for the session |
| Update | `high <model>` or `low <model>` | Write that model into the matching section (create config first if missing) |
| Interactive | user says they don't know the exact name | Prompt for the model name, then update |

Missing config at any mode → create with placeholders first, then continue.

### 3. Routing rules the command installs

**High model — the session itself runs on this:**
- Design, architecture
- ADR / PRD review
- Planning
- Orchestration (both roles)
- Reading relay, tasks, plans, ADR/design files
- Verification
- Driving the Executor (pingpong)
- Branch/master sync + merge-conflict resolution

**Low model — spawned agents run on this:**
- Execution / implementation
- Git operations (except branch/master sync and merge conflicts)
- Jira / Atlassian operations
- Persisting state and onboarding files
- Any mechanical / execution-like work

### 4. Session model behavior

The session runs on the high model. `/model` (or the runtime equivalent)
overrides the high model **for the current pane only** and **never writes back
to the config**. The config is the persistent source of truth; it changes only
via the command (`high X` / `low Y`), a plain prompt that invokes the command,
or manual editing.

### 5. Verification rule (both orientations)

The Executor verifies its agents' work. The Architect reviews the *verified*
result and does **not** re-run the verification the Executor already performed.
The Architect remains the quality gate for scope, correctness of the report,
and stability — but does not duplicate the Executor's verification pass.

## Files

- Create: `claude/commands/pingpong-model-routing.md`
- Create: `copilot/skills/pingpong-model-routing/SKILL.md`
- Modify: `claude/commands/pingpong-init.md` (create `MODEL-ROUTING.md`)
- Modify: `copilot/skills/pingpong-init/SKILL.md` (create `MODEL-ROUTING.md`)
- Modify: `claude/commands/pingpong-orient-architect.md` (verification rule)
- Modify: `copilot/skills/pingpong-orient-architect/SKILL.md` (verification rule)
- Modify: `claude/commands/pingpong-init.md` / Copilot init — Architect
  orientation template "How to review a result" (no re-verification)
- Modify: `install.sh` + `install.ps1` (add `pingpong-model-routing` to the
  command/skill lists)
- Modify: `README.md` (command table + "Model routing" section)

## Out of scope

- Auto-detecting models from the runtime's available list.
- Per-repo model overrides (the config is intentionally global to the root).
- Enforcement — the routing is instruction-level; the runtime's own model
  selection (`/model`) is the enforcement mechanism.