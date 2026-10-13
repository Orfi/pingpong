# Herdr Ping-Pong Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an explicit, user-controlled autonomous architect↔executor loop ("ping-pong") over the existing relay files, using Herdr only as a wake-up/status transport, plus installer gating so the two new skills are installed only when the user opts into Herdr support.

**Architecture:** Two new markdown skill/command artifacts (`pingpong-auto`, `pingpong-auto-stop`) authored in both source trees (`claude/commands/*.md` for Claude Code + OpenCode; `copilot/skills/*/SKILL.md` for Copilot CLI). The existing 8 relay artifacts are untouched. Both installers gain a "Herdr support?" prompt that conditionally installs the new artifacts and offers to install/update Herdr and its agent skill.

**Tech Stack:** Markdown skill files with YAML frontmatter; Bash (`install.sh`); PowerShell (`install.ps1`). No runtime scripts — the kit stays skills-only.

**Spec:** `docs/superpowers/specs/2026-07-18-herdr-pingpong-design.md` (read it before starting).

## Global Constraints

- The existing 8 relay skills/commands must NOT be modified.
- Relay files remain the only data channel; Herdr carries only wake-up calls and status observation.
- YAML frontmatter `description:` values must not contain unquoted `: ` sequences (breaks Copilot's parser) — use `—` or a `>-` block scalar.
- Commit messages: `{type}: {VERB}: description` (no ticket). NO Co-authored-by trailer or any agent attribution.
- Windows install command: `powershell -ExecutionPolicy Bypass -c "irm https://herdr.dev/install.ps1 | iex"`; Linux/macOS: `curl -fsSL https://herdr.dev/install.sh | sh`; herdr agent skill: `npx skills add ogulcancelik/herdr --skill herdr -g`.
- `--uninstall` always removes the two ping-pong artifacts if present, but never uninstalls Herdr or the herdr agent skill.
- Repo root: `/mnt/BA707A64707A2773/code/pingpong`, branch `main`, commit directly to it.

---

### Task 1: `pingpong-auto` artifact (both variants)

**Files:**
- Create: `claude/commands/pingpong-auto.md`
- Create: `copilot/skills/pingpong-auto/SKILL.md`

**Interfaces:**
- Consumes: existing skills `/pingpong-relay-to-executor`, `/pingpong-relay-read-task`, `/pingpong-relay-read-result`; herdr CLI; `<kit-root>` resolution convention.
- Produces: the skill name `pingpong-auto` (referenced by Task 3/4 installer arrays and Task 5 README); the STOP sentinel path `<kit-root>/relay/STOP` (consumed by Task 2).

- [ ] **Step 1: Write `claude/commands/pingpong-auto.md`**

Create the file with exactly this content:

````markdown
---
name: pingpong-auto
description: Architect role — run the autonomous architect↔executor ping-pong loop over the relay files via Herdr until DONE, blocked, timeout, or stopped.
---

You are acting as the **Architect** and you are about to drive the autonomous **ping-pong loop**: relay a task to the executor, nudge it through Herdr, wait, read its result, and iterate — without the user between hops. The user invoked this deliberately; never start this loop on your own initiative.

## Gate

Require Herdr: run `test "${HERDR_ENV:-}" = 1`. If it fails, say you are not running inside Herdr and that the manual relay flow (`/pingpong-relay-to-executor` → user nudges → `/pingpong-relay-read-result`) still works, then STOP.

Resolve the **helper-files root**: read `.orfi-kits/helper-files-root` in the current repo. If missing, STOP and run `/pingpong-set-helper-files-root` — ask the user for the absolute path (never guess; no default). Define `<kit-root>` = `<helper-files-root>/orfi-kits`.

## Discover the executor pane

Run `herdr pane list --workspace "$HERDR_WORKSPACE_ID"` and select panes whose `label` equals `executor` **case-insensitively** and whose `cwd` is this repo. Zero matches → report "no executor pane found" and STOP. More than one → show them and ask the user to pick. Never guess and never look in other workspaces. Note the pane's `pane_id` — use it for every nudge, wait, and read below.

## Initial task

Take the task from the arguments below or, if none, from the current conversation context — same convention as `/pingpong-relay-to-executor`. If neither yields a clear task, ask the user before starting.

## The loop

Each round:

1. **STOP check.** If `<kit-root>/relay/STOP` exists: delete it, report "ping-pong stopped by user at round N" plus what was in flight, and STOP.
2. **Relay.** Write the task with the exact procedure of `/pingpong-relay-to-executor` (overwrite `<kit-root>/relay/relay-to-executor.md`, update the session-state RELAY FILE STATE note).
3. **Pre-flight.** `herdr pane get <executor-pane>` — the executor must be `idle` or `done`. If `working`/`blocked`, wait with `herdr wait agent-status <executor-pane> --status idle --timeout 120000`; on timeout, read the pane, report, and STOP.
4. **Nudge.** Record the pane's current `revision`, then `herdr pane run <executor-pane> "/pingpong-relay-read-task"`.
5. **Wait.** `herdr wait agent-status <executor-pane> --status done --timeout 600000`; if that times out, check `herdr pane get <executor-pane>` — treat `idle` **with a changed `revision`** as completed (fast replies race past `working`; the revision change is your evidence the executor actually acted). If still unchanged or `blocked`, read the pane with `herdr pane read <executor-pane> --source recent-unwrapped --lines 60`, report, and STOP. Do NOT chain a `working` wait before the `idle`/`done` wait.
6. **Read the result.** Follow `/pingpong-relay-read-result` in this pane: read `<kit-root>/relay/relay-to-architect.md` in full and review it critically.
7. **Log.** Append one line to the RELAY FILE STATE section of your own session-state file — `CLAUDE-SESSION-STATE.md` if you are Claude Code, `COPILOT-SESSION-STATE.md` if you are Copilot CLI: round number, direction, one-sentence summary.
8. **Decide.** Stop if the result contains `## Status: DONE`, or if you judge no follow-up is needed — report the outcome to the user. Otherwise formulate the follow-up task and go to 1.

## Hard rules

- There is no round cap; the loop is done-marker driven with the stops above.
- STOP conditions, whichever comes first: done-marker; either agent `blocked`; a wait timeout; the STOP sentinel; the user interrupting you.
- Never retry silently. Anything unexpected → halt and report.
- Herdr never carries task or result content — only the nudge command and status. The relay files are the sole data channel.
- You still never implement the executor's task yourself.

Arguments (the initial task, optional): $ARGUMENTS
````

- [ ] **Step 2: Create the Copilot variant**

Create `copilot/skills/pingpong-auto/SKILL.md` with content identical to Step 1's file except: remove the trailing `Arguments (the initial task, optional): $ARGUMENTS` line and change the "Initial task" sentence to read "Take the task from the user's invocation or the current conversation context" (Copilot skills receive no `$ARGUMENTS`).

- [ ] **Step 3: Validate frontmatter of both files**

Run:
```bash
cd /mnt/BA707A64707A2773/code/pingpong && python3 - <<'EOF'
import yaml
for f in ['claude/commands/pingpong-auto.md','copilot/skills/pingpong-auto/SKILL.md']:
    d = yaml.safe_load(open(f).read().split('---')[1])
    assert d['name'] == 'pingpong-auto', f
    print('OK', f)
EOF
```
Expected: two `OK` lines. A YAML error means an unquoted `: ` slipped into the description — fix per Global Constraints.

- [ ] **Step 4: Commit**

```bash
cd /mnt/BA707A64707A2773/code/pingpong
git add claude/commands/pingpong-auto.md copilot/skills/pingpong-auto
git commit -m "feat: ADDED: pingpong-auto skill (autonomous relay loop via Herdr)"
```

---

### Task 2: `pingpong-auto-stop` artifact (both variants)

**Files:**
- Create: `claude/commands/pingpong-auto-stop.md`
- Create: `copilot/skills/pingpong-auto-stop/SKILL.md`

**Interfaces:**
- Consumes: STOP sentinel path `<kit-root>/relay/STOP` (defined in Task 1); `<kit-root>` resolution convention; both session-state file names.
- Produces: the skill name `pingpong-auto-stop` (referenced by Task 3/4 installer arrays and Task 5 README).

- [ ] **Step 1: Write `claude/commands/pingpong-auto-stop.md`**

Create the file with exactly this content:

````markdown
---
name: pingpong-auto-stop
description: Any role — stop a running architect↔executor ping-pong loop by creating the STOP sentinel, then report loop state.
---

You may be any agent in any pane — architect, executor, or a third session. Your job is to stop a running ping-pong loop.

Resolve the **helper-files root**: read `.orfi-kits/helper-files-root` in the current repo. If missing, STOP and run `/pingpong-set-helper-files-root` — ask the user for the absolute path (never guess; no default). Define `<kit-root>` = `<helper-files-root>/orfi-kits`.

1. Create the empty sentinel file `<kit-root>/relay/STOP` (create the `relay` directory if needed). If it already exists, say so — a stop is already pending.
2. Read the RELAY FILE STATE section of `<kit-root>/CLAUDE-SESSION-STATE.md` and `<kit-root>/COPILOT-SESSION-STATE.md` (whichever exist) and report to the user: which round the loop appears to be on and what task is in flight, so they know what stopping interrupts.
3. Explain: the architect checks for this sentinel before every hop, so the loop halts at its next checkpoint and deletes the sentinel. For an immediate abort the user can press Esc/Ctrl+C in the architect's pane instead.

Do not touch the relay files themselves and do not delete the sentinel — the architect consumes it.
````

- [ ] **Step 2: Create the Copilot variant**

Create `copilot/skills/pingpong-auto-stop/SKILL.md` with content identical to Step 1's file (it has no `$ARGUMENTS` line, so no change needed).

- [ ] **Step 3: Validate frontmatter of both files**

Run:
```bash
cd /mnt/BA707A64707A2773/code/pingpong && python3 - <<'EOF'
import yaml
for f in ['claude/commands/pingpong-auto-stop.md','copilot/skills/pingpong-auto-stop/SKILL.md']:
    d = yaml.safe_load(open(f).read().split('---')[1])
    assert d['name'] == 'pingpong-auto-stop', f
    print('OK', f)
EOF
```
Expected: two `OK` lines.

- [ ] **Step 4: Commit**

```bash
cd /mnt/BA707A64707A2773/code/pingpong
git add claude/commands/pingpong-auto-stop.md copilot/skills/pingpong-auto-stop
git commit -m "feat: ADDED: pingpong-auto-stop skill (halt the loop from any pane)"
```

---

### Task 3: `install.sh` — Herdr-support gating

**Files:**
- Modify: `install.sh` (arrays at lines ~38-39; add prompt after runtime selection ~line 149; uninstall block ~lines 153-161; install blocks ~lines 179-192)

**Interfaces:**
- Consumes: artifact names `pingpong-auto`, `pingpong-auto-stop` from Tasks 1-2.
- Produces: interactive behavior "Herdr support? [y/N]" that Task 4 mirrors in PowerShell.

- [ ] **Step 1: Split the artifact arrays**

In `install.sh`, replace the two array definitions:

```bash
# Base artifacts — always installed. Same 8 names for command .md files and Copilot skill dirs.
COMMANDS=(pingpong-set-helper-files-root pingpong-init pingpong-orient-architect pingpong-orient-executor pingpong-relay-to-executor pingpong-relay-read-task pingpong-relay-to-architect pingpong-relay-read-result)
SKILLS=("${COMMANDS[@]}")
# Herdr-gated artifacts — installed only with Herdr support; ALWAYS removed on uninstall.
PINGPONG=(pingpong-auto pingpong-auto-stop)
```

- [ ] **Step 2: Make uninstall always remove ping-pong artifacts**

In the `remove_commands_from` and `remove_skills_from` functions, iterate over both arrays. Replace `for c in "${COMMANDS[@]}"; do` with `for c in "${COMMANDS[@]}" "${PINGPONG[@]}"; do` and `for s in "${SKILLS[@]}"; do` with `for s in "${SKILLS[@]}" "${PINGPONG[@]}"; do`.

- [ ] **Step 3: Add the Herdr prompt and install/update logic**

Insert after the runtime-selection validation (`[ "$WANT_CC" -eq 1 ] || ... err "no runtime selected"`) and BEFORE the uninstall block, guarded so it only runs on install:

```bash
# --- herdr support (install mode only) ----------------------------------------

WANT_HERDR=0
if [ "$MODE" = "install" ]; then
  printf 'Do you want Herdr support (autonomous architect<->executor ping-pong)? [y/N]: '
  read -r herdr_choice
  case "$herdr_choice" in
    y|Y|yes|YES)
      WANT_HERDR=1
      if command -v herdr >/dev/null 2>&1; then
        printf 'herdr is already installed. Update it now? [y/N]: '
        read -r upd
        case "$upd" in y|Y|yes|YES) curl -fsSL https://herdr.dev/install.sh | sh ;; esac
      else
        say "Installing herdr..."
        curl -fsSL https://herdr.dev/install.sh | sh
      fi
      if command -v npx >/dev/null 2>&1; then
        say "Installing the herdr agent skill globally..."
        npx skills add ogulcancelik/herdr --skill herdr -g
      else
        warn "npx not found — install the herdr agent skill manually:"
        say  "  https://github.com/ogulcancelik/herdr/blob/master/SKILL.md"
      fi
      ;;
    *)
      say "Skipping Herdr support — regular (manual relay) mode only."
      ;;
  esac
fi
```

- [ ] **Step 4: Conditionally include the ping-pong artifacts on install**

Append the gated names to the install arrays right after the block from Step 3:

```bash
if [ "$WANT_HERDR" -eq 1 ]; then
  COMMANDS+=("${PINGPONG[@]}")
  SKILLS+=("${PINGPONG[@]}")
fi
```

(`install_commands_to`/`install_skills_to` then need no changes. Note the uninstall removal in Step 2 must reference the PINGPONG array explicitly — after this append, dedupe is irrelevant because uninstall exits before this point.)

- [ ] **Step 5: Syntax-check**

Run: `bash -n /mnt/BA707A64707A2773/code/pingpong/install.sh && echo SYNTAX-OK`
Expected: `SYNTAX-OK`

- [ ] **Step 6: Functional test of the "no" path with an isolated HOME**

```bash
cd /mnt/BA707A64707A2773/code/pingpong
TESTHOME=$(mktemp -d)
printf '1 2 3\nn\n' | HOME="$TESTHOME" XDG_CONFIG_HOME="$TESTHOME/.config" bash install.sh
ls "$TESTHOME/.claude/commands" | grep -c 'pingpong-' # expect 8
ls "$TESTHOME/.claude/commands" | grep pingpong && echo "FAIL: pingpong installed" || echo "OK: no pingpong"
rm -rf "$TESTHOME"
```
Expected: 8 base commands installed, `OK: no pingpong`.

- [ ] **Step 7: Functional test of uninstall removing ping-pong leftovers**

```bash
cd /mnt/BA707A64707A2773/code/pingpong
TESTHOME=$(mktemp -d)
mkdir -p "$TESTHOME/.claude/commands" "$TESTHOME/.copilot/skills/pingpong-auto"
touch "$TESTHOME/.claude/commands/pingpong-auto.md"
printf '1 3\n' | HOME="$TESTHOME" bash install.sh --uninstall
[ ! -e "$TESTHOME/.claude/commands/pingpong-auto.md" ] && [ ! -d "$TESTHOME/.copilot/skills/pingpong-auto" ] && echo "OK: pingpong removed" || echo "FAIL"
rm -rf "$TESTHOME"
```
Expected: `OK: pingpong removed`.

- [ ] **Step 8: Commit**

```bash
cd /mnt/BA707A64707A2773/code/pingpong
git add install.sh
git commit -m "feat: ADDED: Herdr-support gating to install.sh (conditional ping-pong artifacts)"
```

---

### Task 4: `install.ps1` — Herdr-support gating (twin of Task 3)

**Files:**
- Modify: `install.ps1` (arrays at lines ~49-50; removal functions ~lines 82-98; add prompt after runtime validation ~line 135; before uninstall block ~line 139)

**Interfaces:**
- Consumes: artifact names from Tasks 1-2; the exact prompt wording and flow from Task 3 (the two installers must behave identically).
- Produces: nothing new — behavioral parity.

- [ ] **Step 1: Split the artifact arrays**

Replace the `$Commands`/`$Skills` definitions:

```powershell
# Base artifacts — always installed.
$Commands = @('pingpong-set-helper-files-root','pingpong-init','pingpong-orient-architect','pingpong-orient-executor','pingpong-relay-to-executor','pingpong-relay-read-task','pingpong-relay-to-architect','pingpong-relay-read-result')
$Skills   = $Commands
# Herdr-gated artifacts — installed only with Herdr support; ALWAYS removed on uninstall.
$PingPong = @('pingpong-auto','pingpong-auto-stop')
```

- [ ] **Step 2: Make removal functions cover ping-pong artifacts**

In `Remove-CommandsFrom` change the loop to `foreach ($c in ($Commands + $PingPong))`, and in `Remove-SkillsFrom` to `foreach ($s in ($Skills + $PingPong))`.

- [ ] **Step 3: Add the Herdr prompt and install/update logic**

Insert after `if (-not ($WantCC -or $WantOC -or $WantCP)) { Die 'no runtime selected' }` and before the uninstall block:

```powershell
# --- herdr support (install mode only) ----------------------------------------

$WantHerdr = $false
if (-not $Uninstall) {
    $herdrChoice = Read-Host 'Do you want Herdr support (autonomous architect<->executor ping-pong)? [y/N]'
    if ($herdrChoice -match '^(y|yes)$') {
        $WantHerdr = $true
        if (Get-Command herdr -ErrorAction SilentlyContinue) {
            $upd = Read-Host 'herdr is already installed. Update it now? [y/N]'
            if ($upd -match '^(y|yes)$') {
                powershell -ExecutionPolicy Bypass -c "irm https://herdr.dev/install.ps1 | iex"
            }
        } else {
            Say 'Installing herdr...'
            powershell -ExecutionPolicy Bypass -c "irm https://herdr.dev/install.ps1 | iex"
        }
        if (Get-Command npx -ErrorAction SilentlyContinue) {
            Say 'Installing the herdr agent skill globally...'
            npx skills add ogulcancelik/herdr --skill herdr -g
        } else {
            Warn 'npx not found - install the herdr agent skill manually:'
            Say  '  https://github.com/ogulcancelik/herdr/blob/master/SKILL.md'
        }
    } else {
        Say 'Skipping Herdr support - regular (manual relay) mode only.'
    }
}
if ($WantHerdr) {
    $Commands = $Commands + $PingPong
    $Skills   = $Skills + $PingPong
}
```

Case-insensitivity note: PowerShell `-match` is case-insensitive by default, so `Y`/`YES` are covered.

- [ ] **Step 4: Syntax-check**

Run (pwsh if available, else the parser via python is not possible — use pwsh):
```bash
pwsh -NoProfile -Command "[System.Management.Automation.Language.Parser]::ParseFile('/mnt/BA707A64707A2773/code/pingpong/install.ps1', [ref]\$null, [ref]\$err) | Out-Null; if (\$err.Count) { \$err; exit 1 } else { 'SYNTAX-OK' }"
```
Expected: `SYNTAX-OK`. If `pwsh` is not installed on this machine, state that the syntax check was skipped and rely on careful review — do NOT install PowerShell just for this.

- [ ] **Step 5: Commit**

```bash
cd /mnt/BA707A64707A2773/code/pingpong
git add install.ps1
git commit -m "feat: ADDED: Herdr-support gating to install.ps1 (conditional ping-pong artifacts)"
```

---

### Task 5: Documentation — README and spec path correction

**Files:**
- Modify: `README.md` (Command reference table ~line 46-57; Install section ~line 61; Uninstall section ~line 105)
- Modify: `docs/superpowers/specs/2026-07-18-herdr-pingpong-design.md` (one wrong path)

**Interfaces:**
- Consumes: skill names and installer behavior from Tasks 1-4.
- Produces: user-facing docs; no downstream consumers.

- [ ] **Step 1: Fix the spec's source-path line**

In the spec, the "What is added" intro says skills live in `claude/skills/ and copilot/skills/`. Correct it to: `claude/commands/ (Claude Code + OpenCode) and copilot/skills/ (Copilot CLI), per the kit's source layout`.

- [ ] **Step 2: Extend the README command reference**

Add two rows to the command table after the `relay-read-result` row:

```markdown
| `/pingpong-auto` | Architect: autonomous relay loop via Herdr — relay, nudge, wait, read, repeat until DONE. *(Installed only with Herdr support.)* |
| `/pingpong-auto-stop` | Any pane: stop a running ping-pong loop at its next checkpoint. *(Installed only with Herdr support.)* |
```

- [ ] **Step 3: Document the installer prompt**

In the README Install section, after the runtime-selection description, add:

```markdown
The installer then asks whether you want **Herdr support** (autonomous
architect↔executor ping-pong). Answering yes installs/updates
[Herdr](https://herdr.dev), installs its agent skill
(`npx skills add ogulcancelik/herdr --skill herdr -g`), and includes the two
ping-pong commands. Answering no installs the kit exactly as before — manual
relay mode only. Uninstall always removes the ping-pong commands if present,
but never touches Herdr itself.
```

- [ ] **Step 4: Commit**

```bash
cd /mnt/BA707A64707A2773/code/pingpong
git add README.md docs/superpowers/specs/2026-07-18-herdr-pingpong-design.md
git commit -m "docs: UPDATED: README and spec for Herdr ping-pong skills"
```

---

## Verification (whole feature)

- [ ] All four new artifact files parse (Tasks 1-2 Step 3 checks).
- [ ] `bash -n install.sh` passes; isolated-HOME tests show: no-herdr install → 8 artifacts, no pingpong; uninstall removes pingpong leftovers.
- [ ] `git log --oneline` shows 5 commits, none with a Co-authored-by trailer: `git log -5 --format=%B | grep -i co-authored` returns nothing.
- [ ] Optional live test (user-driven): run `./install.sh`, answer `y` to Herdr, confirm the two skills land in `~/.claude/commands` and `~/.copilot/skills`, then invoke `/pingpong-auto` in the architect pane on a trivial task.
