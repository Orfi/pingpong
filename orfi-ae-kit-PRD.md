# orfi-ae-kit — Build & Onboarding PRD

> **Audience:** a future Claude Code session with **no prior context**. This document is self-contained. Read it top to bottom, then assemble the `orfi-ae-kit` repository and its installer exactly as specified.
>
> **Your deliverable:** a new repo `orfi-ae-kit/` containing 5 Claude commands, 5 Copilot skills, two installers (`install.sh` + `install.ps1`), a `README.md`, and an MIT `LICENSE`.

---

## 1. Purpose

**orfi-ae-kit** packages the **Architect/Executor** two-session AI development pattern as a set of slash-command skills.

The pattern: you run **TWO context-isolated AI sessions** against one piece of work.

- The **Executor** session orchestrates — it spawns agents to do the implementation work, verifies their output, and reports results back. It does not implement code directly unless the user explicitly authorizes it.
- The **Architect** session directs and verifies — it decides what to build next, writes the task brief, and critically reviews what the Executor reports back. The Architect also acts as an **interactive thinking-partner / sidekick** to the human: helping draft the prompts that go to the Executor and helping decode the Executor's questions and results.

The two sessions never share a context window. They communicate **only through file-based relay files** on disk. A **human sits at the decision points** — approving tasks, resolving blockers, and steering the loop.

This pattern was originally explored as a standalone desktop app codenamed **"SonOfAnton."** That app was **SHELVED.** The workflow is intentionally **skill-driven only — there is no app**, no daemon, no background process. Everything is commands you invoke inside your AI CLI.

**Relationship to orfi-kit:** orfi-ae-kit is the **optional companion** to the separate, generic **orfi-kit**. The dependency is **soft** — the AE commands are nearly standalone — but in practice the Architect/Executor workflow leans on orfi-kit's generic git / test / guardrail skills to actually get work done. Therefore:

- **orfi-kit MUST be listed as a prerequisite in the README** ("install orfi-kit first").
- The two kits are **NOT merged.** They are separate repos with separate installers. orfi-ae-kit is the add-on; orfi-kit is the base.

---

## 2. Source location (where to copy FROM)

All source files currently live in:

```
/mnt/BA707A64707A2773/code/ai-augmented-dev-resources
```

…split by runtime:

| Runtime | Source directory |
| --- | --- |
| Claude Code (commands) | `claude-tools/commands/` |
| Copilot (skills) | `copilot-tools/skills/` |

> **Note:** those source directories also contain many *other* files (`orfi-kit-*`, `orfi-gsd-*`, and other unrelated items). **Copy ONLY the `orfi-ae-kit-*` items listed in the manifest below — nothing else.**

A **clean-slate copy is fine.** Git history need **NOT** be preserved — just copy the files into the new repo layout and `git init` fresh.

---

## 3. Exact file manifest for orfi-ae-kit

### Claude Code — commands (from `claude-tools/commands/`)

Five `.md` command files. Copy each verbatim:

| File | Role / purpose |
| --- | --- |
| `orfi-ae-kit-orient-architect.md` | Orients the session as the **Architect** — reads the orientation file + the shared session-state file, then confirms role/phase and proposes a first task. |
| `orfi-ae-kit-relay-to-executor.md` | **Architect** writes a self-contained task to the executor relay file (overwrites it). |
| `orfi-ae-kit-relay-read-task.md` | **Executor** reads the task the Architect left in the executor relay file. |
| `orfi-ae-kit-relay-to-architect.md` | **Executor** writes its result/report back to the architect relay file (overwrites it). |
| `orfi-ae-kit-relay-read-result.md` | **Architect** reads the Executor's result and reviews it **critically** (verify claims, note gaps, decide next step). |

### Copilot — skills (from `copilot-tools/skills/`)

Five **skill directories**, each containing a single `SKILL.md`. Copy each directory verbatim:

| Skill directory | Notes |
| --- | --- |
| `orfi-ae-kit-orient-architect/` | contains `SKILL.md` |
| `orfi-ae-kit-relay-to-executor/` | contains `SKILL.md` |
| `orfi-ae-kit-relay-read-task/` | contains `SKILL.md` |
| `orfi-ae-kit-relay-to-architect/` | contains `SKILL.md` |
| `orfi-ae-kit-relay-read-result/` | contains `SKILL.md` |

This gives **full parity**: 5 Claude commands mirrored as 5 Copilot skills. **In Copilot, a skill IS its slash command** — there is no separate command file. (The Copilot `SKILL.md` text is lightly adapted, e.g. it says "Executor Copilot" instead of "Executor Claude"; keep whatever the source files say — do not rewrite.)

### Scope: what this kit contains

- **5 commands (Claude)** + **5 skills (Copilot)**. That is the entire kit.
- There are **NO** standalone skills for Claude, **NO** hooks, and **NO** Copilot extensions in this kit. Do not invent any.

### IMPORTANT — hard-coded relay/orientation paths inside the commands

The command/skill bodies reference the user's **real Windows relay setup** with absolute paths. These appear literally inside the files and must be preserved as-is on copy:

```
C:\repos\helper_files\relay\relay-to-executor.md     (task: Architect → Executor)
C:\repos\helper_files\relay\relay-to-architect.md    (result: Executor → Architect)
C:\repos\helper_files\architect-orientation.md       (who the Architect is / how it operates)
C:\repos\helper_files\CLAUDE-SESSION-STATE.md         (shared handoff state)
C:\repos\helper_files\ONBOARDING.md                   (epic single source of truth, read if it exists)
```

These paths are **environment-specific** (one user's Windows machine). Do not "fix" them when copying — they are part of the current working setup.

> **TODO (future improvement — mention only, DO NOT implement or require):** make the relay root configurable (e.g. an env var / config value) rather than hard-coding it to `C:\repos\helper_files`. This is a known limitation to document, not a build requirement.

---

## 4. Proposed repo layout

```
orfi-ae-kit/
  claude/
    commands/   <- the 5 orfi-ae-kit-*.md command files
  copilot/
    skills/     <- the 5 orfi-ae-kit-* skill dirs (each with SKILL.md)
  install.sh
  install.ps1
  README.md
  LICENSE       (MIT)
```

Note what is **absent** and should stay absent:

- **No** `claude/skills/` — the Claude artifacts here are commands, not skills.
- **No** `hooks/` anywhere.
- **No** `copilot/extensions/`.
- **No** `opencode/` source directory of its own — OpenCode reuses the Claude command source (see §5).

---

## 5. Installer requirements — REPLICATE the trackbed installer behavior

Ship **two equivalent installers**: `install.sh` (bash) and `install.ps1` (cross-platform `pwsh`, also Windows PowerShell 5+). They are a **maintenance pair** — any change to one must be mirrored in the other. They do **install-time plumbing only** (copy/symlink files into the right directories); there is no runtime component.

**Reference implementation — READ THESE FIRST and adapt them:**

```
/mnt/BA707A64707A2773/code/trackbed/install.sh
/mnt/BA707A64707A2773/code/trackbed/install.ps1
```

The trackbed installers are the proven template. Match their structure, helper names, flag conventions, comment style, and runtime-selection UX. The notes below describe how to adapt them for orfi-ae-kit's **commands-vs-skills** split.

### 5.1 Interactive runtime selection

On launch (no flag), print a menu and read a choice:

```
Install for which runtime(s)?
  1) Claude Code
  2) OpenCode
  3) GitHub Copilot CLI
Select one or more (e.g. '1', '3', or '1 2 3' / '1,2' for several).
```

Accept **multiple** selections, **space- or comma-separated** (`1`, `1 2`, `1,3`, `1 2 3`). Invalid token → error out. No selection → error out.

### 5.2 Flags

| bash | PowerShell | Meaning |
| --- | --- | --- |
| `--link` | `-Link` | symlink instead of copy (dev mode: repo edits go live) |
| `--uninstall` | `-Uninstall` | remove an existing orfi-ae-kit install |
| `--help` / `-h` | `-Help` | print usage (derive from the header comment block, as trackbed does) |

### 5.3 The `place()` helper

Mirror trackbed's `place()` (bash) / `Place()` (PowerShell):

1. `mkdir -p` the destination's parent directory.
2. Remove any existing destination (`rm -rf` / `Remove-Item -Recurse -Force`).
3. If `--link`/`-Link`: create a symlink `src → dest`. Otherwise copy (`cp -R` / `Copy-Item -Recurse -Force`).
4. Print `  linked <dest>` or `  copied <dest>`.

### 5.4 Per-runtime placement — THE KEY DIFFERENCE FROM trackbed

Trackbed ships **skills** that Claude and OpenCode **share** (one skill source, one skill home, with a drift-avoidance rule). **orfi-ae-kit is different: its Claude/OpenCode artifacts are COMMANDS, not skills, and Copilot's are skills.** That makes the layout simpler — but still follow trackbed's overall structure for consistency.

Define two distinct sources:

- **Command source** (Claude + OpenCode): `claude/commands/` — the 5 `orfi-ae-kit-*.md` files.
- **Copilot skill source**: `copilot/skills/` — the 5 `orfi-ae-kit-*` skill dirs.

Placement per selected runtime:

| Runtime selected | Source | Destination |
| --- | --- | --- |
| **Claude Code** | `claude/commands/*.md` | `~/.claude/commands/` |
| **OpenCode** | `claude/commands/*.md` | `~/.config/opencode/commands/` (honour `$XDG_CONFIG_HOME`) |
| **GitHub Copilot CLI** | `copilot/skills/<skill-dir>/` | `~/.copilot/skills/` |

Key points to make explicit in the installer comments:

- **OpenCode conflict rule (the trackbed concern):** OpenCode reads BOTH `~/.claude/skills` and `~/.config/opencode/skills` — which is why trackbed forces *skills* into a single home to prevent drift. **In this kit there are NO shared skills between Claude and OpenCode** — the Claude/OpenCode artifacts are **commands**, and **commands go to each runtime's own commands dir** (`~/.claude/commands/` vs `~/.config/opencode/commands/`). So the drift rule does **not** apply here; each runtime simply gets its own copy of the commands. Note this simplification in a comment, referencing why (commands, not skills).
- **Copilot is independent:** its artifacts are **skills**, from a **different source dir** (`copilot/skills`), installed to **its own home** (`~/.copilot/skills`), with **no command file** (the skill IS the slash command).
- Be **explicit in the code/comments** that Claude/OpenCode commands and Copilot skills come from **different source directories**.

Use list variables like trackbed's `$Skills` array, e.g. a `COMMANDS=(orfi-ae-kit-orient-architect orfi-ae-kit-relay-to-executor orfi-ae-kit-relay-read-task orfi-ae-kit-relay-to-architect orfi-ae-kit-relay-read-result)` list (the `.md` files) and a matching `SKILLS=(...)` list of the same 5 names (the Copilot skill dirs). Provide `install_commands_to <dir>` / `install_skills_to <dir>` and `remove_*` helpers analogous to trackbed's.

### 5.5 Uninstall

For each selected runtime, remove what install placed:

- Claude Code → remove the 5 `*.md` from `~/.claude/commands/`.
- OpenCode → remove the 5 `*.md` from `~/.config/opencode/commands/`.
- Copilot → remove the 5 skill dirs from `~/.copilot/skills/`.

Print `  removed <path>` for each, then `Done.`

### 5.6 Prerequisite check (WARN, do not block)

On **install** (not uninstall), detect whether **orfi-kit** appears installed. A reasonable probe: check for a known orfi-kit artifact, e.g.

- `~/.claude/skills/orfi-kit-guardrails` (dir), **or**
- any `~/.claude/commands/orfi-kit-*.md` command, **or**
- `~/.copilot/skills/orfi-kit-guardrails` (when only Copilot is selected).

If **none** is found, print a **WARNING** (yellow/`say`-level, not fatal) along the lines of:

```
warning: orfi-kit does not appear to be installed.
orfi-ae-kit is the optional companion to orfi-kit and works best with it.
Recommended: install orfi-kit first — see <orfi-kit repo URL>.
Continuing anyway...
```

It must **warn, not block** — installation proceeds regardless.

### 5.7 Final message

After a successful install, print a `Done.` line plus an example invocation:

```
Done. Orient your Architect session with /orfi-ae-kit-orient-architect
```

---

## 6. README requirements

Write `README.md` covering all of the following:

1. **What orfi-ae-kit is** — the Architect/Executor two-session pattern delivered as slash-command skills; the optional companion to orfi-kit; the "SonOfAnton was shelved, this is skills-only, no app" note.
2. **PREREQUISITE — orfi-kit (prominent):** state clearly at the top that **orfi-kit should be installed first**, link/point to its repo, and that the two kits are separate (not merged). The installer only *warns* if it's missing — the README is where the requirement is documented.
3. **The Architect/Executor pattern explained** — two context-isolated sessions (Executor orchestrates agents + verifies, Architect directs + verifies + acts as the human's thinking-partner), communicating only through file-based relay files, with a human at the decision points.
4. **The relay loop** — document the cycle:
   ```
   orient (Architect)
     → relay-to-executor (Architect writes task)
       → relay-read-task (Executor reads task)
          → Executor orchestrates the work
           → relay-to-architect (Executor writes result)
             → relay-read-result (Architect reviews critically)
               → repeat (Architect relays the next task)
   ```
5. **Command reference** — list each of the 5 commands with a one-line description:
   - `/orfi-ae-kit-orient-architect` — orient this session as the Architect (reads orientation + session-state + onboarding).
   - `/orfi-ae-kit-relay-to-executor` — Architect: write the next task to the executor relay file.
   - `/orfi-ae-kit-relay-read-task` — Executor: read the task the Architect left.
   - `/orfi-ae-kit-relay-to-architect` — Executor: write your result/report back.
   - `/orfi-ae-kit-relay-read-result` — Architect: read and critically review the Executor's result.
6. **Install instructions** — show **both** `install.sh` (bash) and `install.ps1` (PowerShell), the interactive runtime menu, and all flags (`--link`/`-Link`, `--uninstall`/`-Uninstall`, `--help`/`-Help`). Document per-runtime install destinations.
7. **Uninstall** — `./install.sh --uninstall` / `./install.ps1 -Uninstall`.
8. **Known environment assumption** — the relay/orientation files are **hard-coded** to `C:\repos\helper_files\...` (Windows). Document the five paths from §3 and note the configurable-relay-root **TODO** as a known limitation.

---

## 7. Acceptance checklist

Before declaring the build done, verify all of:

- [ ] All **5 Claude commands** present under `claude/commands/` (`orfi-ae-kit-orient-architect`, `-relay-to-executor`, `-relay-read-task`, `-relay-to-architect`, `-relay-read-result`).
- [ ] All **5 Copilot skills** present under `copilot/skills/`, each a directory containing `SKILL.md`.
- [ ] No `claude/skills/`, no `hooks/`, no `copilot/extensions/` — only what §4 specifies.
- [ ] `install.sh` and `install.ps1` both: handle the interactive runtime menu, accept multiple space/comma-separated selections, and implement `--link`/`-Link`, `--uninstall`/`-Uninstall`, `--help`/`-Help`.
- [ ] Installers place Claude commands → `~/.claude/commands/`, OpenCode commands → `~/.config/opencode/commands/`, Copilot skills → `~/.copilot/skills/`, from the correct (distinct) source dirs.
- [ ] Prerequisite **warning** fires when orfi-kit is absent — and does **not** block install.
- [ ] `README.md` documents the Architect/Executor pattern, the full relay loop, all 5 commands, install/uninstall for both shells, and **prominently states the orfi-kit prerequisite**.
- [ ] The hard-coded `C:\repos\helper_files` relay paths are documented in the README as a known environment assumption (with the configurable-root TODO noted).
- [ ] `LICENSE` is MIT.

---

## Appendix A — quick build recipe

1. `mkdir -p orfi-ae-kit/claude/commands orfi-ae-kit/copilot/skills`
2. Copy the 5 `orfi-ae-kit-*.md` from `…/ai-augmented-dev-resources/claude-tools/commands/` → `orfi-ae-kit/claude/commands/`.
3. Copy the 5 `orfi-ae-kit-*` skill dirs from `…/ai-augmented-dev-resources/copilot-tools/skills/` → `orfi-ae-kit/copilot/skills/`.
4. Adapt `/mnt/BA707A64707A2773/code/trackbed/install.sh` and `install.ps1` per §5 → drop into the repo root.
5. Write `README.md` per §6 and an MIT `LICENSE`.
6. `git init` (fresh history — no need to preserve source history).
7. Run through the §7 acceptance checklist.
