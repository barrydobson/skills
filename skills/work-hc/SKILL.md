---
name: work-hc
description: How /tote-issue-tracker:work delegates when the session runs inside herdr-core ($HC_TERMINAL_ID set) - each ticket's implementer and reviewer run as hc terminals the human can watch and steer. Use when /work reaches implementation or review inside Herdr. Not for /work outside Herdr, which implements in the session.
user-invocable: false
---

# /work through hc

The `/work` skill still owns the steps: read, decide, implement, review, PR. This skill only changes who does steps 3 and 4. You stay the coordinator: you hold the decisions, open the PRs and move the tickets. Run `hc --skill` once before the first start if you have not read it this session.

## Starting a child

Names are shared with every session on the machine, so use `<repo>-<id>-impl` and `<repo>-<id>-review`.

1. Write the prompt to `${TMPDIR:-/tmp}/work/<repo>/<id>-<impl | review>-prompt.md` with the Write tool.
   - **Implementer:** the ticket key, the worktree path and branch, the human's answers from step 2, and: "Implement this ticket following steps 3 and 4 of the `tote-issue-tracker:work` skill. Commit on the branch; pushing, the PR and the tracker are mine. Reply with status (DONE / BLOCKED), each criterion met or not met with its evidence, and rulings."
   - **Reviewer:** "Invoke `tote-issue-tracker:reviewing-changes` for <key>: worktree <path>, base <SHA>. You did not write this code and do not change it. Reply with the skill's report only."
   - End both with: "Write your reply to `${TMPDIR:-/tmp}/work/<repo>/<id>-<impl | review>-report.md`, then `hc send <your $HC_TERMINAL_ID> \"<that path>\"`. Do the same after every later turn. Start no agents."
2. Start it in the worktree:

   ```sh
   hc run --bg --name <name> --cwd <worktree path> claude \
     --model <model> --permission-mode <mode> \
     "Read <prompt file> and follow it."
   ```

   - `--model` is always set; the child does not inherit yours. `sonnet` for implementers unless the ticket asks otherwise, `opus` for reviewers.
   - `--permission-mode` is this session's mode. An hc child starts in `default` and stops at its first edit without it. Never pass a mode more permissive than your own.
3. Check `first_message.sent` in the JSON. If it is false, `hc read <name>` before anything else; never resend blindly.

## Waiting

Wait with `hc wait --children any`, never sleep or poll. A report arrives tagged `<hc from="<t> <name>">`; read the file it names before acting. A `timeout` is a check-in: wait again.

- **`blocked`**: the child waits on a person, usually a permission prompt. Leave it for the human, who can see it in Herdr, and carry on with other tickets. Still blocked at the end: report "blocked in <name>".
- **`error`** or **exited**: `hc read --lines 100 <name>`, and treat it as BLOCKED with what the screen shows.

## Fix round

Write the reviewer's open findings verbatim to `${TMPDIR:-/tmp}/work/<repo>/<id>-findings.md` and `hc send <repo>-<id>-impl "<that path>"`. One round; whatever stays open goes in the PR body.

## A /work request over hc

A request that arrives over hc carries the sender's address in `reach`: `<hc from="t3 lead" reach="hc send t3 when done or stuck">`. Send your step 2 questions and the final report there.

## Cleanup

Kill and remove a reviewer once its report is in hand, and an implementer once its PR is open. Leave a blocked or failed child alive and name it in the report. Remove only terminals you started.
