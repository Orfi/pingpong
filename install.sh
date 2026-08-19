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

# Base artifacts — always installed. Same 8 names for command .md files and Copilot skill dirs.
COMMANDS=(orfi-ae-kit-set-helper-files-root orfi-ae-kit-init orfi-ae-kit-orient-architect orfi-ae-kit-orient-executor orfi-ae-kit-relay-to-executor orfi-ae-kit-relay-read-task orfi-ae-kit-relay-to-architect orfi-ae-kit-relay-read-result orfi-ae-kit-model-routing)
SKILLS=("${COMMANDS[@]}")
# Herdr-gated artifacts — installed only with Herdr support; ALWAYS removed on uninstall.
PINGPONG=(orfi-ae-kit-pingpong orfi-ae-kit-pingpong-stop)

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
  for c in "${COMMANDS[@]}" "${PINGPONG[@]}"; do
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
  for s in "${SKILLS[@]}" "${PINGPONG[@]}"; do
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

if [ "$WANT_HERDR" -eq 1 ]; then
  COMMANDS+=("${PINGPONG[@]}")
  SKILLS+=("${PINGPONG[@]}")
fi

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
