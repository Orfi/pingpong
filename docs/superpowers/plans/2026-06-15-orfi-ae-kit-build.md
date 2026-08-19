# orfi-ae-kit Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Assemble the `orfi-ae-kit` repo — 5 Claude commands, 5 Copilot skills, two installers, a README, and an MIT LICENSE — exactly as specified in `orfi-ae-kit-PRD.md`.

**Architecture:** Pure file-assembly + install-time plumbing. Copy verbatim command/skill source from `ai-augmented-dev-resources` into a `claude/commands` + `copilot/skills` layout. Adapt the trackbed `install.sh`/`install.ps1` pair to a commands-vs-skills split (Claude+OpenCode share the *command* source — no drift rule needed since they go to separate per-runtime command dirs; Copilot gets skills from its own source). Write README + keep existing MIT LICENSE.

**Tech Stack:** Bash, PowerShell (pwsh / Windows PowerShell 5+), Markdown. No runtime code, no tests framework — verification is structural (file presence, shell parse checks, dry-run install into a temp HOME).

---

## File Structure

Files created/modified by this plan, each with one responsibility:

- `claude/commands/orfi-ae-kit-*.md` (5 files) — verbatim copies of the Claude command source. The Architect/Executor relay commands. Also the OpenCode command source (reused).
- `copilot/skills/orfi-ae-kit-*/SKILL.md` (5 dirs) — verbatim copies of the Copilot skill source. Copilot's slash commands.
- `install.sh` — bash installer (interactive runtime menu, `--link`/`--uninstall`/`--help`, `place()` helper, prereq warn).
- `install.ps1` — PowerShell twin of `install.sh` (maintenance pair, identical behavior).
- `README.md` — replaces the 13-byte stub; documents pattern, relay loop, commands, install/uninstall, prereq, hard-coded paths.
- `LICENSE` — already MIT (`Copyright (c) 2026 Wael Elorfi`). No change. Verify only.

**Known facts established before planning:**
- Source command files exist: `…/ai-augmented-dev-resources/claude-tools/commands/orfi-ae-kit-{orient-architect,relay-read-result,relay-read-task,relay-to-architect,relay-to-executor}.md`
- Source skill dirs exist: `…/ai-augmented-dev-resources/copilot-tools/skills/orfi-ae-kit-*/SKILL.md`
- Trackbed installers exist at `/mnt/BA707A64707A2773/code/trackbed/install.{sh,ps1}` (read; used as template).
- Target repo `/mnt/BA707A64707A2773/code/orfi-ae-kit/` already has `.git`, MIT `LICENSE`, and a stub `README.md`.

The 5 canonical names (used in both COMMANDS and SKILLS arrays):
`orfi-ae-kit-orient-architect`, `orfi-ae-kit-relay-to-executor`, `orfi-ae-kit-relay-read-task`, `orfi-ae-kit-relay-to-architect`, `orfi-ae-kit-relay-read-result`

---

## Task 1: Create directory skeleton and copy command files

**Files:**
- Create: `claude/commands/` (dir)
- Create: `copilot/skills/` (dir)
- Copy into: `claude/commands/orfi-ae-kit-*.md` (5 files)

- [ ] **Step 1: Create the two source directories**

```bash
cd /mnt/BA707A64707A2773/code/orfi-ae-kit
mkdir -p claude/commands copilot/skills
```

- [ ] **Step 2: Copy the 5 Claude command files verbatim**

```bash
SRC=/mnt/BA707A64707A2773/code/ai-augmented-dev-resources/claude-tools/commands
cp "$SRC"/orfi-ae-kit-orient-architect.md \
   "$SRC"/orfi-ae-kit-relay-to-executor.md \
   "$SRC"/orfi-ae-kit-relay-read-task.md \
   "$SRC"/orfi-ae-kit-relay-to-architect.md \
   "$SRC"/orfi-ae-kit-relay-read-result.md \
   /mnt/BA707A64707A2773/code/orfi-ae-kit/claude/commands/
```

- [ ] **Step 3: Verify exactly 5 command files landed**

Run:
```bash
ls -1 /mnt/BA707A64707A2773/code/orfi-ae-kit/claude/commands/ | sort
```
Expected output (exactly these 5 lines):
```
orfi-ae-kit-orient-architect.md
orfi-ae-kit-relay-read-result.md
orfi-ae-kit-relay-read-task.md
orfi-ae-kit-relay-to-architect.md
orfi-ae-kit-relay-to-executor.md
```

- [ ] **Step 4: Verify copies are byte-identical to source**

Run:
```bash
SRC=/mnt/BA707A64707A2773/code/ai-augmented-dev-resources/claude-tools/commands
DST=/mnt/BA707A64707A2773/code/orfi-ae-kit/claude/commands
for f in orfi-ae-kit-orient-architect orfi-ae-kit-relay-to-executor orfi-ae-kit-relay-read-task orfi-ae-kit-relay-to-architect orfi-ae-kit-relay-read-result; do
  diff -q "$SRC/$f.md" "$DST/$f.md" && echo "OK $f";
done
```
Expected: 5 lines `OK <name>`, no `differ` lines.

- [ ] **Step 5: Commit**

```bash
cd /mnt/BA707A64707A2773/code/orfi-ae-kit
git add claude/commands
git commit -m "chore: ADDED: Claude command files for orfi-ae-kit"
```

---

## Task 2: Copy Copilot skill directories

**Files:**
- Copy into: `copilot/skills/orfi-ae-kit-*/SKILL.md` (5 dirs)

- [ ] **Step 1: Copy the 5 Copilot skill directories verbatim**

```bash
SRC=/mnt/BA707A64707A2773/code/ai-augmented-dev-resources/copilot-tools/skills
DST=/mnt/BA707A64707A2773/code/orfi-ae-kit/copilot/skills
for d in orfi-ae-kit-orient-architect orfi-ae-kit-relay-to-executor orfi-ae-kit-relay-read-task orfi-ae-kit-relay-to-architect orfi-ae-kit-relay-read-result; do
  cp -R "$SRC/$d" "$DST/$d";
done
```

- [ ] **Step 2: Verify exactly 5 skill dirs, each with a SKILL.md**

Run:
```bash
DST=/mnt/BA707A64707A2773/code/orfi-ae-kit/copilot/skills
ls -1 "$DST" | sort
echo "---"
find "$DST" -name SKILL.md | sort
```
Expected: 5 dir names listed, then 5 `…/<name>/SKILL.md` paths.

- [ ] **Step 3: Verify skill copies are byte-identical to source**

Run:
```bash
SRC=/mnt/BA707A64707A2773/code/ai-augmented-dev-resources/copilot-tools/skills
DST=/mnt/BA707A64707A2773/code/orfi-ae-kit/copilot/skills
for d in orfi-ae-kit-orient-architect orfi-ae-kit-relay-to-executor orfi-ae-kit-relay-read-task orfi-ae-kit-relay-to-architect orfi-ae-kit-relay-read-result; do
  diff -rq "$SRC/$d" "$DST/$d" && echo "OK $d";
done
```
Expected: 5 lines `OK <name>`, no `differ` / `Only in` lines.

- [ ] **Step 4: Commit**

```bash
cd /mnt/BA707A64707A2773/code/orfi-ae-kit
git add copilot/skills
git commit -m "chore: ADDED: Copilot skill directories for orfi-ae-kit"
```

---

## Task 3: Write `install.sh`

**Files:**
- Create: `install.sh`

This adapts trackbed's `install.sh`. Key differences from trackbed, baked into the code/comments below:
- Claude + OpenCode share the **command** source (`claude/commands/`), each placed into its own per-runtime commands dir → **no drift rule needed** (commands, not shared skills).
- Copilot gets **skills** from `copilot/skills/`.
- Adds a **prerequisite warning** (orfi-kit) that warns but never blocks.

- [ ] **Step 1: Write `install.sh` with full content**

Create `/mnt/BA707A64707A2773/code/orfi-ae-kit/install.sh`:

```bash
#!/usr/bin/env bash
#
# orfi-ae-kit installer.
#
# orfi-ae-kit is skills/commands-only (no scripts at runtime). This script is
# install-time plumbing only: it copies (or symlinks) the Architect/Executor
# relay artifacts into the right directories for Claude Code, OpenCode, and/or
# GitHub Copilot CLI.
#
# Usage:
#   ./install.sh                 interactive: asks which runtime(s) to install for
#   ./install.sh --link          symlink instead of copy (dev: repo edits go live)
#   ./install.sh --uninstall     remove an existing orfi-ae-kit install
#   ./install.sh --help          show this help
#
# DIFFERENCE FROM trackbed: here the Claude/OpenCode artifacts are COMMANDS
# (not shared skills), so there is NO drift rule. Claude and OpenCode each get
# their OWN copy of the commands in their OWN commands dir:
#   * Claude Code -> ~/.claude/commands/
#   * OpenCode    -> ~/.config/opencode/commands/  (honours $XDG_CONFIG_HOME)
# Copilot is independent: its artifacts are SKILLS from a DIFFERENT source dir
# (copilot/skills), installed to its OWN home (~/.copilot/skills) — no command
# file (in Copilot a skill IS its slash command).

set -euo pipefail

# --- paths -------------------------------------------------------------------

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SRC="$REPO_DIR/claude/commands"        # Claude + OpenCode share this command source
COPILOT_SKILLS_SRC="$REPO_DIR/copilot/skills"   # Copilot has its own skill source

CLAUDE_CMDS="$HOME/.claude/commands"
OPENCODE_CMDS="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/commands"
COPILOT_SKILLS="$HOME/.copilot/skills"          # Copilot's own home — no command file

# Same 5 names for both the command .md files and the Copilot skill dirs.
COMMANDS=(orfi-ae-kit-orient-architect orfi-ae-kit-relay-to-executor orfi-ae-kit-relay-read-task orfi-ae-kit-relay-to-architect orfi-ae-kit-relay-read-result)
SKILLS=(orfi-ae-kit-orient-architect orfi-ae-kit-relay-to-executor orfi-ae-kit-relay-read-task orfi-ae-kit-relay-to-architect orfi-ae-kit-relay-read-result)

LINK=0
MODE="install"

# --- helpers -----------------------------------------------------------------

say()  { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
err()  { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  sed -n '3,23p' "${BASH_SOURCE[0]}" | sed 's/^#$//; s/^# //'
  exit 0
}

# place one item (dir or file) from src -> dest, copy or symlink per $LINK
place() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  if [ "$LINK" -eq 1 ]; then
    ln -s "$src" "$dest"
    say "  linked  $dest"
  else
    cp -R "$src" "$dest"
    say "  copied  $dest"
  fi
}

install_commands_to() {
  local target_dir="$1"
  for c in "${COMMANDS[@]}"; do
    place "$COMMANDS_SRC/$c.md" "$target_dir/$c.md"
  done
}

remove_commands_from() {
  local target_dir="$1"
  for c in "${COMMANDS[@]}"; do
    if [ -e "$target_dir/$c.md" ] || [ -L "$target_dir/$c.md" ]; then
      rm -rf "$target_dir/$c.md"
      say "  removed $target_dir/$c.md"
    fi
  done
}

install_skills_to() {
  local target_dir="$1"
  for s in "${SKILLS[@]}"; do
    place "$COPILOT_SKILLS_SRC/$s" "$target_dir/$s"
  done
}

remove_skills_from() {
  local target_dir="$1"
  for s in "${SKILLS[@]}"; do
    if [ -e "$target_dir/$s" ] || [ -L "$target_dir/$s" ]; then
      rm -rf "$target_dir/$s"
      say "  removed $target_dir/$s"
    fi
  done
}

# Prereq probe: does orfi-kit appear installed? (warn-only, never blocks)
orfi_kit_present() {
  [ -d "$HOME/.claude/skills/orfi-kit-guardrails" ] && return 0
  [ -d "$COPILOT_SKILLS/orfi-kit-guardrails" ] && return 0
  ls "$HOME"/.claude/commands/orfi-kit-*.md >/dev/null 2>&1 && return 0
  return 1
}

# --- arg parsing -------------------------------------------------------------

for arg in "$@"; do
  case "$arg" in
    --link)      LINK=1 ;;
    --uninstall) MODE="uninstall" ;;
    --help|-h)   usage ;;
    *)           err "unknown option: $arg (try --help)" ;;
  esac
done

[ -d "$COMMANDS_SRC" ] || err "commands not found at $COMMANDS_SRC — run this from the orfi-ae-kit repo"

# --- runtime selection -------------------------------------------------------

WANT_CC=0
WANT_OC=0
WANT_CP=0

say "orfi-ae-kit installer"
say "Install for which runtime(s)?"
say "  1) Claude Code"
say "  2) OpenCode"
say "  3) GitHub Copilot CLI"
say "Select one or more (e.g. '1', '3', or '1 2 3' / '1,2' for several)."
printf 'Choice: '
read -r choice

# Accept space- or comma-separated selections (1, 2, 3, "1 2", "1,3", ...).
for n in ${choice//,/ }; do
  case "$n" in
    1) WANT_CC=1 ;;
    2) WANT_OC=1 ;;
    3) WANT_CP=1 ;;
    *) err "invalid choice: '$n' (pick 1, 2 and/or 3)" ;;
  esac
done

[ "$WANT_CC" -eq 1 ] || [ "$WANT_OC" -eq 1 ] || [ "$WANT_CP" -eq 1 ] || err "no runtime selected"

# --- uninstall ---------------------------------------------------------------

if [ "$MODE" = "uninstall" ]; then
  say ""
  say "Uninstalling orfi-ae-kit..."
  [ "$WANT_CC" -eq 1 ] && remove_commands_from "$CLAUDE_CMDS"
  [ "$WANT_OC" -eq 1 ] && remove_commands_from "$OPENCODE_CMDS"
  [ "$WANT_CP" -eq 1 ] && remove_skills_from "$COPILOT_SKILLS"
  say "Done."
  exit 0
fi

# --- prerequisite check (WARN, do not block) ---------------------------------

if ! orfi_kit_present; then
  warn "orfi-kit does not appear to be installed."
  say  "orfi-ae-kit is the optional companion to orfi-kit and works best with it."
  say  "Recommended: install orfi-kit first — see the orfi-kit repo."
  say  "Continuing anyway..."
fi

# --- install -----------------------------------------------------------------
#
# No drift rule here: Claude/OpenCode artifacts are commands, so each runtime
# simply gets its own copy in its own commands dir.

say ""

if [ "$WANT_CC" -eq 1 ]; then
  say "Claude Code — commands go to $CLAUDE_CMDS"
  install_commands_to "$CLAUDE_CMDS"
fi

if [ "$WANT_OC" -eq 1 ]; then
  say "OpenCode — commands go to $OPENCODE_CMDS"
  install_commands_to "$OPENCODE_CMDS"
fi

if [ "$WANT_CP" -eq 1 ]; then
  say "GitHub Copilot CLI — skills go to $COPILOT_SKILLS (the skill is its own slash command)."
  install_skills_to "$COPILOT_SKILLS"
fi

say ""
say "Done. Orient your Architect session with /orfi-ae-kit-orient-architect"
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x /mnt/BA707A64707A2773/code/orfi-ae-kit/install.sh
```

- [ ] **Step 3: Verify the script parses (syntax check, no execution)**

Run:
```bash
bash -n /mnt/BA707A64707A2773/code/orfi-ae-kit/install.sh && echo "SYNTAX OK"
```
Expected: `SYNTAX OK`

- [ ] **Step 4: Verify `--help` prints usage**

Run:
```bash
/mnt/BA707A64707A2773/code/orfi-ae-kit/install.sh --help
```
Expected: usage block beginning `orfi-ae-kit installer.` including the four `./install.sh ...` lines. Exit 0.

- [ ] **Step 5: Verify unknown flag errors**

Run:
```bash
/mnt/BA707A64707A2773/code/orfi-ae-kit/install.sh --bogus; echo "exit=$?"
```
Expected: `error: unknown option: --bogus (try --help)` and `exit=1`.

- [ ] **Step 6: Dry-run install into a throwaway HOME**

Run:
```bash
TMP=$(mktemp -d)
HOME="$TMP" XDG_CONFIG_HOME="$TMP/.config" \
  bash -c 'echo "1 2 3" | /mnt/BA707A64707A2773/code/orfi-ae-kit/install.sh'
echo "=== placed ==="
ls -1 "$TMP/.claude/commands" 2>/dev/null | sort
ls -1 "$TMP/.config/opencode/commands" 2>/dev/null | sort
ls -1 "$TMP/.copilot/skills" 2>/dev/null | sort
rm -rf "$TMP"
```
Expected: prereq warning fires (no orfi-kit in temp HOME); 5 `.md` under `.claude/commands`, 5 `.md` under `.config/opencode/commands`, 5 dirs under `.copilot/skills`; final `Done.` line.

- [ ] **Step 7: Dry-run uninstall into a throwaway HOME**

Run:
```bash
TMP=$(mktemp -d)
HOME="$TMP" XDG_CONFIG_HOME="$TMP/.config" bash -c 'echo "1 2 3" | /mnt/BA707A64707A2773/code/orfi-ae-kit/install.sh' >/dev/null
HOME="$TMP" XDG_CONFIG_HOME="$TMP/.config" bash -c 'echo "1 2 3" | /mnt/BA707A64707A2773/code/orfi-ae-kit/install.sh --uninstall'
echo "=== remaining (should be empty) ==="
ls -1 "$TMP/.claude/commands" 2>/dev/null
ls -1 "$TMP/.config/opencode/commands" 2>/dev/null
ls -1 "$TMP/.copilot/skills" 2>/dev/null
rm -rf "$TMP"
```
Expected: `removed` lines for all 15 items, `Done.`, and the three listings empty.

- [ ] **Step 8: Commit**

```bash
cd /mnt/BA707A64707A2773/code/orfi-ae-kit
git add install.sh
git commit -m "chore: ADDED: bash installer for orfi-ae-kit"
```

---

## Task 4: Write `install.ps1` (PowerShell twin)

**Files:**
- Create: `install.ps1`

Behavior-identical maintenance pair of `install.sh`. Same menu, flags, prereq warning, destinations.

- [ ] **Step 1: Write `install.ps1` with full content**

Create `/mnt/BA707A64707A2773/code/orfi-ae-kit/install.ps1`:

```powershell
#!/usr/bin/env pwsh
#
# orfi-ae-kit installer (PowerShell) — the cross-platform twin of install.sh.
# Runs on Windows PowerShell 5+, and pwsh on Windows / macOS / Linux.
#
# orfi-ae-kit is skills/commands-only (no scripts at runtime). This script is
# install-time plumbing only: it copies (or symlinks) the Architect/Executor
# relay artifacts into the right directories for Claude Code, OpenCode, and/or
# GitHub Copilot CLI.
#
# Usage:
#   ./install.ps1                 interactive: asks which runtime(s) to install for
#   ./install.ps1 -Link           symlink instead of copy (dev: repo edits go live)
#   ./install.ps1 -Uninstall      remove an existing orfi-ae-kit install
#   ./install.ps1 -Help           show this help
#
# DIFFERENCE FROM trackbed: here the Claude/OpenCode artifacts are COMMANDS
# (not shared skills), so there is NO drift rule. Claude and OpenCode each get
# their OWN copy of the commands in their OWN commands dir:
#   * Claude Code -> ~/.claude/commands/
#   * OpenCode    -> ~/.config/opencode/commands/  (honours $XDG_CONFIG_HOME)
# Copilot is independent: its artifacts are SKILLS from a DIFFERENT source dir
# (copilot/skills), installed to its OWN home (~/.copilot/skills) — no command
# file (in Copilot a skill IS its slash command).

[CmdletBinding()]
param(
    [switch]$Link,
    [switch]$Uninstall,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# --- paths -------------------------------------------------------------------

$RepoDir          = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommandsSrc      = Join-Path $RepoDir 'claude/commands'    # Claude + OpenCode share this command source
$CopilotSkillsSrc = Join-Path $RepoDir 'copilot/skills'     # Copilot has its own skill source

$Home_     = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
$XdgConfig = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $Home_ '.config' }

$ClaudeCmds    = Join-Path $Home_ '.claude/commands'
$OpencodeCmds  = Join-Path $XdgConfig 'opencode/commands'
$CopilotSkills = Join-Path $Home_ '.copilot/skills'         # Copilot's own home — no command file

# Same 5 names for both the command .md files and the Copilot skill dirs.
$Commands = @('orfi-ae-kit-orient-architect','orfi-ae-kit-relay-to-executor','orfi-ae-kit-relay-read-task','orfi-ae-kit-relay-to-architect','orfi-ae-kit-relay-read-result')
$Skills   = @('orfi-ae-kit-orient-architect','orfi-ae-kit-relay-to-executor','orfi-ae-kit-relay-read-task','orfi-ae-kit-relay-to-architect','orfi-ae-kit-relay-read-result')

# --- helpers -----------------------------------------------------------------

function Say($msg)  { Write-Host $msg }
function Warn($msg) { Write-Warning $msg }
function Die($msg)  { Write-Error "error: $msg"; exit 1 }

function Show-Usage {
    Get-Content $MyInvocation.PSCommandPath | Select-Object -Skip 2 -First 22 |
        ForEach-Object { $_ -replace '^#$','' -replace '^# ','' }
    exit 0
}

# place one item (dir or file) from src -> dest, copy or symlink per -Link
function Place($src, $dest) {
    $parent = Split-Path -Parent $dest
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    if ($Link) {
        New-Item -ItemType SymbolicLink -Path $dest -Target $src | Out-Null
        Say "  linked  $dest"
    } else {
        Copy-Item -Recurse -Force $src $dest
        Say "  copied  $dest"
    }
}

function Install-CommandsTo($targetDir) {
    foreach ($c in $Commands) { Place (Join-Path $CommandsSrc "$c.md") (Join-Path $targetDir "$c.md") }
}

function Remove-CommandsFrom($targetDir) {
    foreach ($c in $Commands) {
        $p = Join-Path $targetDir "$c.md"
        if (Test-Path $p) { Remove-Item -Recurse -Force $p; Say "  removed $p" }
    }
}

function Install-SkillsTo($targetDir) {
    foreach ($s in $Skills) { Place (Join-Path $CopilotSkillsSrc $s) (Join-Path $targetDir $s) }
}

function Remove-SkillsFrom($targetDir) {
    foreach ($s in $Skills) {
        $p = Join-Path $targetDir $s
        if (Test-Path $p) { Remove-Item -Recurse -Force $p; Say "  removed $p" }
    }
}

# Prereq probe: does orfi-kit appear installed? (warn-only, never blocks)
function Test-OrfiKitPresent {
    if (Test-Path (Join-Path $Home_ '.claude/skills/orfi-kit-guardrails')) { return $true }
    if (Test-Path (Join-Path $CopilotSkills 'orfi-kit-guardrails')) { return $true }
    if (Get-ChildItem (Join-Path $Home_ '.claude/commands') -Filter 'orfi-kit-*.md' -ErrorAction SilentlyContinue) { return $true }
    return $false
}

# --- arg parsing -------------------------------------------------------------

if ($Help) { Show-Usage }
if (-not (Test-Path $CommandsSrc)) { Die "commands not found at $CommandsSrc - run this from the orfi-ae-kit repo" }

# --- runtime selection -------------------------------------------------------

$WantCC = $false; $WantOC = $false; $WantCP = $false

Say 'orfi-ae-kit installer'
Say 'Install for which runtime(s)?'
Say '  1) Claude Code'
Say '  2) OpenCode'
Say '  3) GitHub Copilot CLI'
Say "Select one or more (e.g. '1', '3', or '1 2 3' / '1,2' for several)."
$choice = Read-Host 'Choice'

# Accept space- or comma-separated selections (1, 2, 3, "1 2", "1,3", ...).
foreach ($n in ($choice -split '[,\s]+' | Where-Object { $_ -ne '' })) {
    switch ($n) {
        '1' { $WantCC = $true }
        '2' { $WantOC = $true }
        '3' { $WantCP = $true }
        default { Die "invalid choice: '$n' (pick 1, 2 and/or 3)" }
    }
}

if (-not ($WantCC -or $WantOC -or $WantCP)) { Die 'no runtime selected' }

# --- uninstall ---------------------------------------------------------------

if ($Uninstall) {
    Say ''
    Say 'Uninstalling orfi-ae-kit...'
    if ($WantCC) { Remove-CommandsFrom $ClaudeCmds }
    if ($WantOC) { Remove-CommandsFrom $OpencodeCmds }
    if ($WantCP) { Remove-SkillsFrom $CopilotSkills }
    Say 'Done.'
    exit 0
}

# --- prerequisite check (WARN, do not block) ---------------------------------

if (-not (Test-OrfiKitPresent)) {
    Warn 'orfi-kit does not appear to be installed.'
    Say  'orfi-ae-kit is the optional companion to orfi-kit and works best with it.'
    Say  'Recommended: install orfi-kit first - see the orfi-kit repo.'
    Say  'Continuing anyway...'
}

# --- install -----------------------------------------------------------------
#
# No drift rule here: Claude/OpenCode artifacts are commands, so each runtime
# simply gets its own copy in its own commands dir.

Say ''

if ($WantCC) {
    Say "Claude Code - commands go to $ClaudeCmds"
    Install-CommandsTo $ClaudeCmds
}

if ($WantOC) {
    Say "OpenCode - commands go to $OpencodeCmds"
    Install-CommandsTo $OpencodeCmds
}

if ($WantCP) {
    Say "GitHub Copilot CLI - skills go to $CopilotSkills (the skill is its own slash command)."
    Install-SkillsTo $CopilotSkills
}

Say ''
Say 'Done. Orient your Architect session with /orfi-ae-kit-orient-architect'
```

- [ ] **Step 2: Verify the script parses (PowerShell tokenizer, no execution) — if pwsh is available**

Run:
```bash
command -v pwsh >/dev/null 2>&1 && pwsh -NoProfile -Command '
  $ErrorActionPreference="Stop";
  $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Raw /mnt/BA707A64707A2773/code/orfi-ae-kit/install.ps1), [ref]$null);
  "PARSE OK"' || echo "pwsh not installed — SKIPPED (note this in the report)"
```
Expected: `PARSE OK`, or an explicit `SKIPPED` line if `pwsh` is absent. **If skipped, report it — do not claim the ps1 was verified.**

- [ ] **Step 3: Dry-run install into a throwaway HOME — if pwsh is available**

Run:
```bash
command -v pwsh >/dev/null 2>&1 || { echo "pwsh not installed — SKIPPED"; exit 0; }
TMP=$(mktemp -d)
HOME="$TMP" XDG_CONFIG_HOME="$TMP/.config" pwsh -NoProfile -Command "'1 2 3' | & /mnt/BA707A64707A2773/code/orfi-ae-kit/install.ps1"
echo "=== placed ==="
ls -1 "$TMP/.claude/commands" 2>/dev/null | sort
ls -1 "$TMP/.config/opencode/commands" 2>/dev/null | sort
ls -1 "$TMP/.copilot/skills" 2>/dev/null | sort
rm -rf "$TMP"
```
Expected: same placement as the bash dry-run (5/5/5), or explicit `SKIPPED` if `pwsh` is absent.

- [ ] **Step 4: Commit**

```bash
cd /mnt/BA707A64707A2773/code/orfi-ae-kit
git add install.ps1
git commit -m "chore: ADDED: PowerShell installer for orfi-ae-kit"
```

---

## Task 5: Write `README.md`

**Files:**
- Modify: `README.md` (replace the 13-byte stub)

Must cover all 8 points from PRD §6. Full content below — write it verbatim.

- [ ] **Step 1: Replace `README.md` with full content**

Write `/mnt/BA707A64707A2773/code/orfi-ae-kit/README.md`:

````markdown
# orfi-ae-kit

**orfi-ae-kit** packages the **Architect/Executor** two-session AI development pattern as a set of slash-command skills. It is the **optional companion** to the generic [orfi-kit](#prerequisite--orfi-kit). The pattern was originally explored as a standalone desktop app codenamed *SonOfAnton* — that app was **shelved**. orfi-ae-kit is **skills-only: there is no app**, no daemon, no background process. Everything is commands you invoke inside your AI CLI.

## Prerequisite — orfi-kit

**Install [orfi-kit](https://github.com/) first.** orfi-ae-kit is a separate add-on, **not merged** with orfi-kit. The dependency is soft — the AE commands are nearly standalone — but the Architect/Executor workflow leans on orfi-kit's generic git / test / guardrail skills to get work done. The installer only **warns** if orfi-kit is missing (it never blocks); this README is where the requirement is documented.

## The Architect/Executor pattern

You run **two context-isolated AI sessions** against one piece of work:

- The **Executor** session orchestrates — it spawns agents to do the implementation work, verifies their output, and reports results back.
- The **Architect** session directs and verifies — it decides what to build next, writes the task brief, and critically reviews what the Executor reports back. The Architect also acts as an **interactive thinking-partner / sidekick** to the human: helping draft the prompts that go to the Executor and helping decode the Executor's questions and results.

The two sessions never share a context window. They communicate **only through file-based relay files** on disk. A **human sits at the decision points** — approving tasks, resolving blockers, and steering the loop.

## The relay loop

```
orient (Architect)
  → relay-to-executor (Architect writes task)
    → relay-read-task (Executor reads task)
      → Executor orchestrates the work
        → relay-to-architect (Executor writes result)
          → relay-read-result (Architect reviews critically)
            → repeat (Architect relays the next task)
```

## Command reference

| Command | Role |
| --- | --- |
| `/orfi-ae-kit-orient-architect` | Orient this session as the Architect (reads orientation + session-state + onboarding). |
| `/orfi-ae-kit-relay-to-executor` | Architect: write the next task to the executor relay file. |
| `/orfi-ae-kit-relay-read-task` | Executor: read the task the Architect left. |
| `/orfi-ae-kit-relay-to-architect` | Executor: write your result/report back. |
| `/orfi-ae-kit-relay-read-result` | Architect: read and critically review the Executor's result. |

In Claude Code these are **commands**; in GitHub Copilot CLI the equivalent **skills** are their own slash commands. Full parity: 5 Claude commands mirrored as 5 Copilot skills.

## Install

Two equivalent installers — use whichever matches your shell.

```bash
# bash (Linux / macOS / WSL)
./install.sh
```

```powershell
# PowerShell (Windows PowerShell 5+, or pwsh anywhere)
./install.ps1
```

Each launches an interactive runtime menu:

```
Install for which runtime(s)?
  1) Claude Code
  2) OpenCode
  3) GitHub Copilot CLI
Select one or more (e.g. '1', '3', or '1 2 3' / '1,2' for several).
```

Selections may be **space- or comma-separated** (`1`, `1 2`, `1,3`, `1 2 3`).

### Flags

| bash | PowerShell | Meaning |
| --- | --- | --- |
| `--link` | `-Link` | symlink instead of copy (dev mode: repo edits go live) |
| `--uninstall` | `-Uninstall` | remove an existing orfi-ae-kit install |
| `--help` / `-h` | `-Help` | print usage |

### Install destinations

| Runtime | Source | Destination |
| --- | --- | --- |
| Claude Code | `claude/commands/*.md` | `~/.claude/commands/` |
| OpenCode | `claude/commands/*.md` | `~/.config/opencode/commands/` (honours `$XDG_CONFIG_HOME`) |
| GitHub Copilot CLI | `copilot/skills/<dir>/` | `~/.copilot/skills/` |

Claude and OpenCode share the same **command** source; each gets its own copy in its own commands dir. Copilot's **skills** come from a different source dir and install to their own home.

## Uninstall

```bash
./install.sh --uninstall
```

```powershell
./install.ps1 -Uninstall
```

Removes the 5 commands from the Claude/OpenCode commands dirs and the 5 skill dirs from `~/.copilot/skills`, for whichever runtimes you select.

## Known environment assumption — hard-coded relay paths

The command/skill bodies reference one user's **real Windows relay setup** with absolute paths. These appear literally inside the files and are preserved as-is:

```
C:\repos\helper_files\relay\relay-to-executor.md     (task: Architect → Executor)
C:\repos\helper_files\relay\relay-to-architect.md    (result: Executor → Architect)
C:\repos\helper_files\architect-orientation.md       (who the Architect is / how it operates)
C:\repos\helper_files\CLAUDE-SESSION-STATE.md         (shared handoff state)
C:\repos\helper_files\ONBOARDING.md                   (epic single source of truth, read if it exists)
```

These paths are environment-specific (one user's Windows machine).

> **TODO (known limitation):** make the relay root configurable (e.g. an env var / config value) rather than hard-coding it to `C:\repos\helper_files`. Documented here as a known limitation, not yet implemented.

## License

MIT — see [LICENSE](LICENSE).
````

- [ ] **Step 2: Verify all 8 PRD §6 points are present**

Run:
```bash
README=/mnt/BA707A64707A2773/code/orfi-ae-kit/README.md
for needle in "Architect/Executor" "Prerequisite — orfi-kit" "relay loop" "orfi-ae-kit-orient-architect" "install.sh" "install.ps1" "--uninstall" "C:\\repos\\helper_files" "TODO"; do
  grep -qF "$needle" "$README" && echo "OK  $needle" || echo "MISSING  $needle";
done
```
Expected: 9 `OK` lines, no `MISSING`.

- [ ] **Step 3: Commit**

```bash
cd /mnt/BA707A64707A2773/code/orfi-ae-kit
git add README.md
git commit -m "docs: ADDED: README for orfi-ae-kit"
```

---

## Task 6: Verify LICENSE and run the §7 acceptance checklist

**Files:**
- Verify only: `LICENSE` (already MIT — no change)

- [ ] **Step 1: Confirm LICENSE is MIT**

Run:
```bash
head -1 /mnt/BA707A64707A2773/code/orfi-ae-kit/LICENSE
```
Expected: `MIT License`. (No edit — the existing file is already correct.)

- [ ] **Step 2: Confirm absent dirs stay absent (PRD §4)**

Run:
```bash
cd /mnt/BA707A64707A2773/code/orfi-ae-kit
for d in claude/skills hooks copilot/extensions opencode; do
  [ -e "$d" ] && echo "UNEXPECTED: $d exists" || echo "OK absent: $d";
done
```
Expected: 4 `OK absent` lines.

- [ ] **Step 3: Run the full PRD §7 acceptance checklist**

Run:
```bash
cd /mnt/BA707A64707A2773/code/orfi-ae-kit
echo "5 Claude commands:"; ls -1 claude/commands/*.md | wc -l
echo "5 Copilot skills w/ SKILL.md:"; find copilot/skills -name SKILL.md | wc -l
echo "installers present:"; ls install.sh install.ps1
echo "license:"; head -1 LICENSE
```
Expected: `5`, `5`, both installer names listed, `MIT License`. Cross-check every box in PRD §7 manually and report any that fail.

- [ ] **Step 4: Final commit (any remaining tracked changes, e.g. the plan doc)**

```bash
cd /mnt/BA707A64707A2773/code/orfi-ae-kit
git add -A
git status --short
git commit -m "chore: ADDED: build plan and finalize orfi-ae-kit assembly" || echo "nothing left to commit"
```

---

## Self-Review (completed by plan author)

**Spec coverage (PRD §3–§7):**
- §3 manifest — 5 commands (Task 1), 5 skills (Task 2). ✓
- §3 hard-coded paths preserved verbatim — copies are byte-identical (verified by diff in Tasks 1–2); README documents them (Task 5). ✓
- §4 layout + absent dirs — Tasks 1–2 create only `claude/commands` + `copilot/skills`; Task 6 Step 2 asserts no `claude/skills`/`hooks`/`copilot/extensions`/`opencode`. ✓
- §5 installers — Task 3 (sh) + Task 4 (ps1): menu, multi-select, `place()`/`Place()`, three flags, per-runtime destinations, commands-vs-skills split with no-drift comment, prereq warn. ✓
- §6 README — Task 5 covers all 8 points; Step 2 greps for each. ✓
- §7 acceptance checklist — Task 6 mechanizes it. ✓
- LICENSE MIT — already present; Task 6 verifies. ✓

**Placeholder scan:** No TBD/TODO-as-work/"add error handling"/"similar to Task N". The only "TODO" is the literal configurable-relay-root limitation text required by the PRD (content, not a plan gap). ✓

**Type/name consistency:** COMMANDS and SKILLS arrays use the identical 5 canonical names in both installers; helper names (`install_commands_to`/`Install-CommandsTo`, `install_skills_to`/`Install-SkillsTo`, `place`/`Place`) are consistent sh↔ps1. Destinations match across installers and README table. ✓

**Honest limitation noted for the executor:** the `install.ps1` verification (Task 4 Steps 2–3) depends on `pwsh` being installed on this Linux box. If absent, those steps are SKIPPED and MUST be reported as unverified — not claimed as passing (guardrail #8, #11).
