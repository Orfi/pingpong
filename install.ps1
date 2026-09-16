#!/usr/bin/env pwsh
#
# orfi-ae-kit installer (PowerShell) — the cross-platform twin of install.sh.
# Runs on Windows PowerShell 5+, and pwsh on Windows / macOS / Linux.
#
# orfi-ae-kit is skills/commands-only (no scripts at runtime). This script is
# install-time plumbing only: it copies (or symlinks) the Architect/Executor
# relay artifacts into the right directories for Claude Code, OpenCode, GitHub
# Copilot CLI, and/or OpenAI Codex CLI.
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
# file (in Copilot a skill IS its slash command). Codex does the same: its own
# source (codex/skills, adapted executor text) into $env:CODEX_HOME/skills
# (default ~/.codex/skills) — independent, no command file (in Codex a skill is
# selected via /skills or mentioned with $).

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
$CodexSkillsSrc   = Join-Path $RepoDir 'codex/skills'       # Codex has its own adapted copy

$Home_     = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
$XdgConfig = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $Home_ '.config' }

$ClaudeCmds    = Join-Path $Home_ '.claude/commands'
$OpencodeCmds  = Join-Path $XdgConfig 'opencode/commands'
$CopilotSkills = Join-Path $Home_ '.copilot/skills'         # Copilot's own home — no command file
$CodexHome     = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $Home_ '.codex' }
$CodexSkills   = Join-Path $CodexHome 'skills'              # Codex's own home — no command file

# Base artifacts — always installed.
$Commands = @('orfi-ae-kit-set-helper-files-root','orfi-ae-kit-init','orfi-ae-kit-orient-architect','orfi-ae-kit-orient-executor','orfi-ae-kit-relay-to-executor','orfi-ae-kit-relay-read-task','orfi-ae-kit-relay-to-architect','orfi-ae-kit-relay-read-result','orfi-ae-kit-model-routing')
$Skills   = $Commands
# Herdr-gated artifacts — installed only with Herdr support; ALWAYS removed on uninstall.
$PingPong = @('orfi-ae-kit-pingpong','orfi-ae-kit-pingpong-stop')

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
    foreach ($c in ($Commands + $PingPong)) {
        $p = Join-Path $targetDir "$c.md"
        if (Test-Path $p) { Remove-Item -Recurse -Force $p; Say "  removed $p" }
    }
}

function Install-SkillsTo($targetDir, $srcDir = $CopilotSkillsSrc) {
    foreach ($s in $Skills) { Place (Join-Path $srcDir $s) (Join-Path $targetDir $s) }
}

function Remove-SkillsFrom($targetDir) {
    foreach ($s in ($Skills + $PingPong)) {
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

$WantCC = $false; $WantOC = $false; $WantCP = $false; $WantCX = $false

Say 'orfi-ae-kit installer'
Say 'Install for which runtime(s)?'
Say '  1) Claude Code'
Say '  2) OpenCode'
Say '  3) GitHub Copilot CLI'
Say '  4) OpenAI Codex CLI'
Say "Select one or more (e.g. '1', '3', or '1 2 3 4' / '1,2' for several)."
$choice = Read-Host 'Choice'

# Accept space- or comma-separated selections (1, 2, 3, 4, "1 2", "1,3", ...).
foreach ($n in ($choice -split '[,\s]+' | Where-Object { $_ -ne '' })) {
    switch ($n) {
        '1' { $WantCC = $true }
        '2' { $WantOC = $true }
        '3' { $WantCP = $true }
        '4' { $WantCX = $true }
        default { Die "invalid choice: '$n' (pick 1, 2, 3 and/or 4)" }
    }
}

if (-not ($WantCC -or $WantOC -or $WantCP -or $WantCX)) { Die 'no runtime selected' }

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

# --- uninstall ---------------------------------------------------------------

if ($Uninstall) {
    Say ''
    Say 'Uninstalling orfi-ae-kit...'
    if ($WantCC) { Remove-CommandsFrom $ClaudeCmds }
    if ($WantOC) { Remove-CommandsFrom $OpencodeCmds }
    if ($WantCP) { Remove-SkillsFrom $CopilotSkills }
    if ($WantCX) { Remove-SkillsFrom $CodexSkills }
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

if ($WantCX) {
    Say 'OpenAI Codex CLI - skills go to $env:CODEX_HOME/skills (default ~/.codex/skills; the skill is selected via /skills or mentioned with $).'
    Install-SkillsTo $CodexSkills $CodexSkillsSrc
}

Say ''
Say 'Done. Orient your Architect session with /orfi-ae-kit-orient-architect in Claude Code / OpenCode / Copilot CLI, or select the orfi-ae-kit-orient-architect skill in Codex CLI.'
