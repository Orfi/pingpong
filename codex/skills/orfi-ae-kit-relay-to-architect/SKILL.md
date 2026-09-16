---
name: orfi-ae-kit-relay-to-architect
description: Executor role — write a result/output to the architect relay file (overwrite).
---

You are acting as the **Executor**. Report the result of the work you just orchestrated back to the **architect** Codex.

Resolve the **helper-files root** first: read `.orfi-kits/helper-files-root` in the current repo. If it is missing, STOP and run `/orfi-ae-kit-set-helper-files-root` — ask the user for the absolute path (never search for, infer, or guess a location; no default), then continue. There is no default path — do not fall back to any hard-coded location. Define `<kit-root>` = `<helper-files-root>\orfi-kits`.

Overwrite the entire contents of `<kit-root>\relay\relay-to-architect.md` with your report. Create the file if it does not exist. Do not append — replace the whole file.

Report honestly and specifically (no summaries that hide failures). Use this structure:

```
# Relay → Architect

## What I did
<concise account of the change>

## Result
<actual outcome — real test counts (passed/failed/skipped), build status, errors verbatim if any>

## Files changed
<paths>

## Open / blocked / needs decision
<anything the architect must decide, or "none">
```

If a command produced output the architect should see, paste the relevant real output (e.g. the `dotnet test` summary line) — do not paraphrase pass/fail numbers.

After writing the result, also update the **RELAY FILE STATE** section of `<kit-root>\CODEX-SESSION-STATE.md` so the next session can tell this result is the current/unreviewed one (the relay files have no timestamp — the state note is the freshness authority). One line is enough, e.g. "`relay-to-architect.md` = <result> (CURRENT — awaiting Architect review <date>)".

After writing, confirm in one line: the file path written and a one-sentence summary of the result.

Arguments (optional extra notes to include): take them from the invocation after the skill name, or from the current conversation context.
