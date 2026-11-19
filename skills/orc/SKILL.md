---
name: orc
description: Builds one tracker ticket or GitHub issue into a Sol-reviewed PR through hc agents, and closes it after merge.
disable-model-invocation: true
argument-hint: "[ticket-key] | --finish [ticket-key]"
---

# orc

Take ticket `$ARGUMENTS` from spec to an open PR. If `$ARGUMENTS` starts with `--finish`, the rest is the key: follow **Finish** at the end instead of steps 0 to 10. Hand each stage to an `hc` agent; do no repo work yourself until step 7. Run inside herdr-core (`$HC_TERMINAL_ID` set); otherwise stop and say why. First run `hc label $HC_TERMINAL_ID orch.role=head`.

Needs `hc` (herdr-core), `claude`, `codex` (for the Sol reviewer), `gh`, and an issue tracker skill or CLI in this session.

The work always happens in the ticket's repo, never in this session's directory. Every `hc run` below takes `--label orch.ticket=<key>`, so each agent shows its ticket, and `--cwd`: `<repo>` for spec, build and finish, the worktree for review.

## Issue tracker

Use whichever issue tracker skill or CLI this session has loaded, for GitHub issues and tracker tickets alike. orc needs five operations from it: **read** a ticket with its comments, **start** it (mark it in progress), **comment** on it from a file, move it to **review**, and the tracker's **finish skill**, which closes a ticket after merge. If the session has none, stop and say so.

Run every tracker write from `<repo>`, as `cd <repo> && ...`. A tracker can read its config from the repo it runs in, or refuse a ticket that belongs to another repo, and this session's directory is not the ticket's repo. Step 0's read comes before `<repo>` is known, so it runs from here.

## Conventions

Set `<n>` to the ticket key in lower case with every character outside `a-z0-9-` turned into `-`, such as `abc-123` or `acme-widgets-12`. It names the worktree and every agent; write it out in full in each command, because shell variables do not persist between Bash calls.

Start every agent with `hc run --bg`. After you start or message an agent, end your turn: its reply arrives as your next input, as an `<hc from=...>` message. Any other input is from the user. If hc reports that an agent exited, errored or is blocked without replying, it has failed: read its screen with `hc read`, report, and stop.

Label your own terminal, always with `${CLAUDE_SKILL_DIR}/scripts/orc-label`, written out in full: it sets the labels a Herdr panel can read to show the run, and rejects a wrong phase. Before step 1, run `${CLAUDE_SKILL_DIR}/scripts/orc-label phase spec <key>`. As each later step starts, run `${CLAUDE_SKILL_DIR}/scripts/orc-label phase <phase>`: `build` at step 3, `review` at 5, `ship` at 7, `ci` at 8, `ticket` at 9, and `finish` after step 10, so a panel shows the ticket waits on merge and `/barrydobson-skills:orc --finish`. Each also records when the stage started and clears a stop. Whenever you stop for the user, first run `${CLAUDE_SKILL_DIR}/scripts/orc-label stop "<reason in a few words>"`.

Never put agent-written text (specs, reports, findings, answers) inside a quoted shell argument: backticks and `$` in it would run in your shell. Write it to `$TMPDIR/orc-<n>-<step>.md` with the Write tool and pass `"$(cat <file>)"`.

### Starting an agent

Each agent gets a prompt from `${CLAUDE_SKILL_DIR}/prompts/` followed by its task. Write the task to `$TMPDIR/orc-<n>-<step>.md`, starting with these lines, with your own terminal ID from `echo $HC_TERMINAL_ID` in place of `<you>`:

```
## Task

Parent: hc send <you>
```

Then start the agent with the prompt and the task joined by one `cat`:

```sh
hc run --bg --name <name> --label orch.ticket=<key> --cwd <dir> -- "$SHELL" -ic '<command> "$@"' orc "$(cat ${CLAUDE_SKILL_DIR}/prompts/<prompt>.md $TMPDIR/orc-<n>-<step>.md)"
```

| Agent | `<prompt>` | `<command>` |
| :- | :- | :- |
| spec | `spec` | `exec claude --permission-mode auto` |
| build | `build` | `exec claude --worktree <n> --permission-mode auto --model <model>` |
| reviewer | `reviewer` | `exec codex --no-daemon -a never -c default_permissions=\"reviewer\" -c permissions.reviewer.extends=\":read-only\" -c permissions.reviewer.network.enabled=true -c check_for_update_on_startup=false -c projects.$(dirname $(git rev-parse --path-format=absolute --git-common-dir)).trust_level=trusted` |
| finish | `finish` | `exec claude --permission-mode auto` |

Keep the command in single quotes exactly as the table gives it. `"$SHELL" -ic` loads the user's shell profile, because hc starts a program with its own environment, which lacks the keys and paths the profile sets. The prompt reaches the agent as `"$@"`, never through the quoted command, so it arrives as its first message unchanged. The reviewer's `$(...)` runs in the agent's shell, in the worktree, and trusts the repo's main checkout.

## Steps

0. **Repo.** Read the ticket `$ARGUMENTS` with the tracker and take the target repo from it. If this session's project instructions say how to pick and locate a repo, follow them. Otherwise:
   - GitHub issue: the repo the issue belongs to, `owner/repo` in its key or URL.
   - Tracker ticket: its single component, as `org/repo`. With none or several, or one that names no org, ask the user.

   Find the clone at `~/_git/<org lower-cased>/<repo>`. If it is missing, check the current name with `gh repo view <org>/<repo> --json nameWithOwner`, because GitHub redirects a renamed repo, then `gh repo clone <org>/<repo> ~/_git/<org lower-cased>/<repo>`, using the current name for the folder. `<repo>` below is the clone's absolute path. Pass the spec agent the key in full form, `owner/repo#n` for GitHub, because a bare `#n` would resolve to the wrong repo.
1. **Spec.** Write the task (the Parent lines, then the key) to `$TMPDIR/orc-<n>-spec.md` and start the spec agent, named `spec-<n>`, with `--cwd <repo>`.
2. **Gate.** On `spec: <key> unfit`, the only reason the user can settle here is a live write the ticket needs: ask with `AskUserQuestion` whether to authorise it, write the answer to `$TMPDIR/orc-<n>-answers.md` and send it with `hc send spec-<n> "$(cat $TMPDIR/orc-<n>-answers.md)"`; a new spec follows. Every other reason goes back to the ticket: an open question belongs in the ticket, where the reviewer and the next run can see it, and a change in another repo means the ticket must be split. For those, write the spec's Goal and Fit to `$TMPDIR/orc-<n>-comment.md` under the heading `## orc: not ready for agent`, post it on the ticket with the tracker, from `<repo>`, give the user the reasons and stop. On `spec: <key> fit`, first read its Fit, Plan and Decisions. If any names a change in another repo, such as a companion PR or a follow-up in another repo, treat the spec as unfit. Then write the build task to `$TMPDIR/orc-<n>-build.md`: the Parent lines, then the whole spec message, then the line `Code only in this pass: make no live write. List each live write the spec authorises under **Live writes** in your report, with its command.` Review must come before any live change, because it cannot undo one.
3. **Build.** Mark the ticket started with the tracker, from `<repo>`. Pick the model from the spec:
   - `haiku`: mechanical or documentation-only changes;
   - `opus`: large changes, several components, or tricky logic (concurrency, auth, data migration);
   - `sonnet`: everything else.

   Start the build agent, named `<n>`, with `--cwd <repo>` and the task in `$TMPDIR/orc-<n>-build.md`. The name is the worktree name. Once it is running: `hc kill spec-<n>`, then `hc rm spec-<n>`. The agent replies `built: <key> <worktree path>`.
4. **Gate.** On `blocked:`, or a report whose Proof says a check failed, show the user the issue and stop. Agents stay running so the user can take over.
5. **Review.** In the worktree, run `git fetch origin -q` and set `base` to `git merge-base HEAD origin/<default branch>`. Write the brief to `$TMPDIR/orc-<n>-brief.md`: the Parent lines, then the round 1 brief from `barrydobson-skills:sol-loop`, with a reply line added, as follows:

   ```
   Review only. Do not edit, commit, push, comment on PRs, or start subagents. Reply via: hc send <you>.
   Repo: <repo> Base: <base> Intent: <spec Goal> Out of scope: <spec Out of scope> Checks: <the build report's Proof>
   See: git diff <base>; git status --short (read untracked).
   Read surrounding code. Find bugs, broken callers, mismatch with intent.
   Skip style unless it hides a bug. Hold to the smallest change. Flag code,
   tests, or guards the intent does not need. Other paths, rare cases, small
   perf, extra compat: nits.
   blocker = intended case wrong. should = real bug callers will hit, in intent. nit = rest.
   Reply:
   VERDICT: APPROVE or CHANGES
   S1 [blocker|should|nit] <file>:<line> <claim>. Fix: <suggestion> (stable ids)
   ```

   Before each round, run `${CLAUDE_SKILL_DIR}/scripts/orc-label round <r>`. In round 1, start one reviewer for all rounds, named `sol-<n>`, with `--cwd <worktree>` and the task in `$TMPDIR/orc-<n>-brief.md`.

   The reply starts `VERDICT:`. On `APPROVE`, go to step 6. On `CHANGES`, send the builder `Fix these review findings and prove each fix. For each finding id, reply fixed:, disagree: or declined: with evidence, then report as before.` followed by the findings, through a file as above. On its `built:` reply (apply step 4), send the reviewer `Round <r>. Same base. Check open ids and changed code only; mark each old id resolved or still open: <reason>.` followed by the builder's ledger and report, through a file. Stop after 3 rounds that end in `CHANGES`: show the user the open findings and stop.
6. **Live writes.** Skip this step if the report lists none. Otherwise send `hc send <n> "Review approved. You are authorised to make the live writes you listed that can run before merge; make them now. Before each one, save what it changes or deletes to $TMPDIR/orc-<n>/rollback/. Report as before."`. Apply step 4 to its reply. Writes that need the merge first, such as a deploy sync, are left for the user.
7. **Ship.** In the worktree: commit everything with the repo's commit convention, push the branch with `-u`, and open the PR with the `barrydobson-skills:file-pr` skill. Its evidence is the build report's Proof, the live writes made, and the line `Reviewed with sol-loop: <rounds> rounds. Sol verdict: approved`. Then label your own terminal with the PR URL: `${CLAUDE_SKILL_DIR}/scripts/orc-label pr <pr url>`.
8. **CI.** `hc run --bg --rm --name ci-<n> --label orch.ticket=<key> --cwd <worktree> -- sh -c 'sleep 20; gh pr checks <pr> --watch'`, then `hc wait ci-<n>`; on `reason: timeout`, wait again. The 20 s lets GitHub register the checks, or `gh` exits with `no checks reported`. This terminal's exit is its result, not a failure. Exit 0: go to step 9. Otherwise read the failure with `gh run view <run> --log-failed`, send it to the builder, then commit and push its fix yourself and watch again. After 2 failed fixes, report to the user and stop.
9. **Ticket.** Write a comment to `$TMPDIR/orc-<n>-comment.md` and post it on the ticket with the tracker, from `<repo>`. It holds the PR link, the live writes made, anything left for the user after merge, follow-ups, and every finding the agents made that the ticket does not record, such as a premise that proved wrong. Add each file in `$TMPDIR/orc-<n>/rollback/` in full, in a code block, because it is the only copy. Redact secret values first; for a file that holds one, give its path instead of its content. Then move the ticket to review with the tracker, from `<repo>`.
10. **End.** `hc kill` then `hc rm` the `<n>` and `sol-<n>` terminals. Give the user the PR link and anything left for them, and tell them to run `/barrydobson-skills:orc --finish <key>` once the PR has merged and that work is done.

## Finish

`/barrydobson-skills:orc --finish <key>` closes the ticket once its PR has merged. The user starts it after the post-merge work step 9's comment left them, by typing it or from a Herdr panel, if one reads these labels. It works in a new session too.

F1. **Repo.** Find `<repo>` as step 0 does, with `<key>` in place of `$ARGUMENTS`, and set `<n>`. Run `${CLAUDE_SKILL_DIR}/scripts/orc-label phase finish <key>`.
F2. **PR.** `gh pr list -R <owner/repo> --state all --search "<key> in:title" --json number,url,state,title,headRefName`, and take the PR whose title has the exact scope `(<key>)`. If it is not merged, run `${CLAUDE_SKILL_DIR}/scripts/orc-label stop "PR not merged"`, tell the user and stop. Otherwise run `${CLAUDE_SKILL_DIR}/scripts/orc-label pr <pr url>`.
F3. **Checks.** Take what step 9's comment left for the user after merge; read the ticket with the tracker if this session did not post it. Turn each item that can be checked into a read-only check, such as "the old admission policy is gone from the staging cluster". Write the task to `$TMPDIR/orc-<n>-finish.md`:

    ```
    ## Task

    Parent: hc send <you>
    <key>
    Worktree: <repo>/.claude/worktrees/<n> Branch: <headRefName>
    Post-merge checks: <the checks, or none>
    Tracker: the issue tracker's finish skill
    ```
F4. **Run.** If a `finish-<n>` terminal is left from a stopped finish, `hc kill finish-<n>` then `hc rm finish-<n>`, so this run starts clean. Then start the finish agent, named `finish-<n>`, with `--cwd <repo>` and the task in `$TMPDIR/orc-<n>-finish.md`. It runs the checks, then the tracker's finish skill, and replies `finished: <key> done` or `finished: <key> skipped: <why>`.
F5. **End.** On `done`: `hc kill` then `hc rm` `finish-<n>`, run `${CLAUDE_SKILL_DIR}/scripts/orc-label phase done`, and give the user the report. On `skipped:`: run `${CLAUDE_SKILL_DIR}/scripts/orc-label stop "<why in a few words>"`, show the user the report and stop. The agent stays running so the user can take over.
