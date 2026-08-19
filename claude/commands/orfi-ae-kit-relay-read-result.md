---
name: orfi-ae-kit-relay-read-result
description: Architect role — read the result the executor left in the architect relay file.
---

You are acting as the **Architect**. Resolve the **helper-files root** first: read `.orfi-kits/helper-files-root` in the current repo. If it is missing, STOP and run `/orfi-ae-kit-set-helper-files-root` — ask the user for the absolute path (never search for, infer, or guess a location; no default), then continue. There is no default path — do not fall back to any hard-coded location. Define `<kit-root>` = `<helper-files-root>\orfi-kits`.

Read the file `<kit-root>\relay\relay-to-architect.md` in full — this is the result the executor Claude reported back.

If the file is empty or missing, say so and stop (no result yet).

Otherwise: review the executor's result critically. Do NOT re-run the verification the executor already performed — review its verified result, note anything that looks wrong, incomplete, or unverified, and decide the next step. If there is a follow-up task, relay it with `/orfi-ae-kit-relay-to-executor`.
