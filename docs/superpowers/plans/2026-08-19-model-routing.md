# Model Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a global `MODEL-ROUTING.md` config plus an `orfi-ae-kit-model-routing` command/skill per runtime, so each session knows its high (thinking) and low (execution) model tiers, and the Architect does not re-verify work the Executor already verified.

**Architecture:** All content lives in the kit's existing markdown command/skill files. The init commands gain a `MODEL-ROUTING.md` creation step; a new command reads/updates it; the Architect orientation's review section drops the "re-run tests yourself" re-verification instruction. Installers pick up the new artifact from their existing file lists.

**Tech Stack:** Markdown commands/skills + bash/PowerShell installers. No code.

---

## Task 1: Create the Claude/OpenCode command `orfi-ae-kit-model-routing`

**Files:**
- Create: `claude/commands/orfi-ae-kit-model-routing.md`

- [ ] **Step 1: Create the command file** with this exact content:

````markdown
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

Read the **Claude Code** section and state:
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

- `high <model>` — replace the `high_model` value in the **Claude Code** section.
- `low <model>` — replace the `low_model` value in the **Claude Code** section.
- Anything else — ask the user which tier they meant, then update.
- If the user says they don't know the exact model name, prompt interactively for it, then update.

After an update, confirm in one line: which tier changed and the new value.

### Model changes via `/model`

If the user changes the session model with `/model`, that overrides the high
model **for this pane only** — do **not** write it back to `MODEL-ROUTING.md`.
The config changes only via this command, a prompt that calls it, or manual
editing.
````

- [ ] **Step 2: Verify** the file exists and starts with the `---` frontmatter block.

## Task 2: Create the Copilot skill `orfi-ae-kit-model-routing`

**Files:**
- Create: `copilot/skills/orfi-ae-kit-model-routing/SKILL.md`

- [ ] **Step 1: Create the skill** — same content as Task 1 except:
  - frontmatter `name: orfi-ae-kit-model-routing`
  - the **Copilot CLI** section is the one read/updated in report and update modes
  - add `Arguments (optional): $ARGUMENTS` at the end

- [ ] **Step 2: Verify** the file exists.

## Task 3: Add `MODEL-ROUTING.md` creation to the init commands

**Files:**
- Modify: `claude/commands/orfi-ae-kit-init.md`
- Modify: `copilot/skills/orfi-ae-kit-init/SKILL.md`

- [ ] **Step 1 (Claude init):** in Step 3's bullet list, after the
  `executor-orientation.md` block (line ~118), add:

````markdown
- `MODEL-ROUTING.md` — write the **agnostic** model-routing config below verbatim if it does not already exist:

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
````

- [ ] **Step 2 (Copilot init):** same edit in `copilot/skills/orfi-ae-kit-init/SKILL.md`.
  Note the Copilot init template's placeholder section names (`COPILOT-SESSION-STATE.md`)
  — keep the same config content; the config's sections are runtime-named
  (`Claude Code` / `OpenCode` / `Copilot CLI`), not file-named.

## Task 4: Update the installers

**Files:**
- Modify: `install.sh`
- Modify: `install.ps1`

- [ ] **Step 1 (install.sh):** add `orfi-ae-kit-model-routing` to the `COMMANDS` array (line 38). Since `SKILLS` copies `COMMANDS`, the Copilot skill list updates automatically.

- [ ] **Step 2 (install.ps1):** add `'orfi-ae-kit-model-routing'` to the `$Commands` array (line 49). `$Skills = $Commands` updates automatically.

- [ ] **Step 3:** verify both installers reference the new name in exactly the base-artifact list, not the PingPong list.

## Task 5: Architect orientation — drop re-verification

**Files:**
- Modify: `claude/commands/orfi-ae-kit-init.md` (Architect orientation template, "How to review a result")
- Modify: `copilot/skills/orfi-ae-kit-init/SKILL.md` (same template)
- Modify: `claude/commands/orfi-ae-kit-orient-architect.md`
- Modify: `copilot/skills/orfi-ae-kit-orient-architect/SKILL.md`

- [ ] **Step 1 (init templates, "How to review a result"):** change the line
  `- **Verify claims** — if a file/behavior matters, have the Executor show evidence; re-run the project's tests yourself to reconcile.`
  to:
  `- **Verify claims** — if a file/behavior matters, have the Executor show evidence. Do NOT re-run the verification the Executor already performed — review its verified result critically.`

- [ ] **Step 2 (orient-architect commands):** after the reconciliation sentence, add one line:
  `Do not re-run verification the Executor already performed — review its verified result.`

- [ ] **Step 3:** verify both Claude and Copilot copies received identical changes.

## Task 6: README — command table + model routing section

**Files:**
- Modify: `README.md`

- [ ] **Step 1:** add a row to the command reference table:
  `| \`/orfi-ae-kit-model-routing\` | Both roles: read or update the model-routing config (report high/low tiers, or set them with \`high <model>\` / \`low <model>\`). |`

- [ ] **Step 2:** add a short **Model routing** section after "The helper-files root" section:
  - Where `MODEL-ROUTING.md` lives and how it's created (init with placeholders).
  - The three runtime sections and what each holds.
  - The three modes of the command.
  - The `/model` override is pane-only and never writes back.
  - The high-model vs low-model routing split.
  - The verification rule (Executor verifies; Architect does not re-verify).

## Task 7: Verify, commit, push

- [ ] **Step 1:** grep the repo for `orfi-ae-kit-model-routing` — must appear in:
  `claude/commands/`, `copilot/skills/`, `install.sh`, `install.ps1`, `README.md`.
- [ ] **Step 2:** grep for stale re-verification wording (`re-run the project's tests yourself`) — must have zero matches.
- [ ] **Step 3:** commit all changes with the orfi-kit commit convention.
- [ ] **Step 4:** push to origin/main.