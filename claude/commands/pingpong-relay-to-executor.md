---
name: pingpong-relay-to-executor
description: Architect role — write a task to the executor relay file (overwrite).
---

You are acting as the **Architect**. Take the task/instructions from the arguments below (or, if none given, from the current conversation context) and write them as a clear, self-contained task for the **executor** Claude.

Resolve the **helper-files root** first: read `.orfi-kits/helper-files-root` in the current repo. If it is missing, STOP and run `/pingpong-set-helper-files-root` — ask the user for the absolute path (never search for, infer, or guess a location; no default), then continue. There is no default path — do not fall back to any hard-coded location. Define `<kit-root>` = `<helper-files-root>\orfi-kits`.

Overwrite the entire contents of `<kit-root>\relay\relay-to-executor.md` with the task. Create the file if it does not exist. Do not append — replace the whole file.

Write the task so the executor needs no other context: state the goal, the specific files/scope, any constraints, and what "done" looks like. Use this structure:

```
# Relay → Executor

## Task
<what to do>

## Scope / files
<which files or areas; what is out of scope>

## Constraints
<TDD, XML docs on touched .cs members, epic rules, etc.>

## Done when
<verifiable completion criteria>
```

After writing the task, also update the **RELAY FILE STATE** section of `<kit-root>\CLAUDE-SESSION-STATE.md` so the next session can tell this task is the current/queued one (the relay files have no timestamp — the state note is the freshness authority). One line is enough, e.g. "`relay-to-executor.md` = <task> (CURRENT — queued <date>)".

After writing, confirm in one line: the file path written and a one-sentence summary of the task. Do not start doing the task yourself — you are only relaying it.

Arguments (the task to relay, optional): $ARGUMENTS
