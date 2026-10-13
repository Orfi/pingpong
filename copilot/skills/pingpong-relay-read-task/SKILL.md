---
name: pingpong-relay-read-task
description: Executor role — read the task the architect left in the executor relay file.
---

You are acting as the **Executor**. Resolve the **helper-files root** first: read `.orfi-kits/helper-files-root` in the current repo. If it is missing, STOP and run `/pingpong-set-helper-files-root` — ask the user for the absolute path (never search for, infer, or guess a location; no default), then continue. There is no default path — do not fall back to any hard-coded location. Define `<kit-root>` = `<helper-files-root>\orfi-kits`.

Read the file `<kit-root>\relay\relay-to-executor.md` in full — this is the task the architect Copilot left for you.

If the file is empty or missing, say so and stop (nothing to do yet).

Otherwise: restate the task in one or two lines to confirm you understood it, then orchestrate agents to carry it out following all project rules (TDD, XML docs on touched `.cs` members, epic git policy, scope discipline). Verify the results before reporting. When the work is complete, write your result back with `/pingpong-relay-to-architect` so the architect can review it.
