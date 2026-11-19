---
name: orc
description: Builds one tracker ticket or GitHub issue into a Sol-reviewed PR through hc agents, and closes it after merge.
disable-model-invocation: true
argument-hint: "[ticket-key] | --finish [ticket-key]"
---

# orc

Take ticket `$ARGUMENTS` from spec to an open PR. If `$ARGUMENTS` starts with `--finish`, the rest is the key: follow **Finish** at the end instead of steps 0 to 10. Hand each stage to an `hc` agent; do no repo work yourself until step 7. Run inside herdr-core (`$HC_TERMINAL_ID` set); otherwise stop and say why. First run `hc label $HC_TERMINAL_ID orch.role=head`.

Needs `hc` (herdr-core), `claude`, `codex` (for the Sol reviewer), `gh`, `python3` (for `orc-ci`), and an issue tracker skill or CLI in this session.

The work always happens in the ticket's repo, never in this session's directory. Each agent runs with `--cwd` `<repo>` for spec, build and finish, and the worktree for review, and is labelled `orch.ticket=<key>` so it shows its ticket.

## Issue tracker

Use whichever issue tracker skill or CLI this session has loaded, for GitHub issues and tracker tickets alike. orc needs five operations from it: **read** a ticket with its comments, **start** it (mark it in progress), **comment** on it from a file, move it to **review**, and the tracker's **finish skill**, which closes a ticket after merge. If the session has none, stop and say so.

Run every tracker write from `<repo>`, as `cd <repo> && ...`. A tracker can read its config from the repo it runs in, or refuse a ticket that belongs to another repo, and this session's directory is not the ticket's repo. Step 0's read comes before `<repo>` is known, so it runs from here.

## Conventions

Set `<n>` to the ticket key in lower case with every character outside `a-z0-9-` turned into `-`, such as `abc-123` or `acme-widgets-12`. It names the worktree, every agent and the `$TMPDIR` files; `orc-start` derives it itself. Write it out in full in each command, because shell variables do not persist between Bash calls.

Start every agent with `orc-start` (see **Agents**). After you start or message an agent, end your turn: its reply arrives as your next input, as an `<hc from=...>` message. Any other input is from the user. If hc reports that an agent exited, errored or is blocked without replying, it has failed: read its screen with `hc read`, report, and stop. If its turn ended without the message its step expects, it has likely forgotten to send: read its screen and, if the reply is there, send it once, with `orc-send`, `You ended your turn without replying. Send that reply to your parent now with hc send.` If the next turn also ends without it, it has failed.

Label your own terminal, always with `${CLAUDE_SKILL_DIR}/scripts/orc-label`, written out in full: it sets the labels a Herdr panel can read to show the run, and rejects a wrong phase. `orc-start` sets the phase for `spec`, `build`, `review` (and round 1) and `ci` when it starts that terminal. Set the rest yourself as each step starts, with `${CLAUDE_SKILL_DIR}/scripts/orc-label phase <phase>`: `ship` at step 7, `ticket` at 9, and `finish` after step 10, so a panel shows the ticket waits on merge and `/barrydobson-skills:orc --finish`. Each also records when the stage started and clears a stop. Whenever you stop for the user, first run `${CLAUDE_SKILL_DIR}/scripts/orc-label stop "<reason in a few words>"`.

Never put agent-written text (specs, reports, findings, answers) inside a quoted shell argument: backticks and `$` in it would run in your shell. Write it to `$TMPDIR/orc-<n>-<step>.md` with the Write tool and pass the file on stdin to `orc-start` or `orc-send`.

### Agents

Start, message and stop agents only through these scripts in `${CLAUDE_SKILL_DIR}/scripts/`, written out in full. Each takes the ticket key and works out the terminal name from the role. Start one with `orc-start`. Write the task body to `$TMPDIR/orc-<n>-<step>.md` with the Write tool, then run:

```sh
${CLAUDE_SKILL_DIR}/scripts/orc-start <role> <key> <cwd> [<model>] < $TMPDIR/orc-<n>-<step>.md
```

`<role>` is `spec`, `build`, `reviewer` or `finish`; only `build` takes a model. The script names the agent (`spec-<n>`, `<n>`, `sol-<n>`, `finish-<n>`), picks its command, removes a terminal of that name left from a stopped run, and sends the prompt from `prompts/`, a `Parent:` header and your body inside the `<hc from=... reach=...>` tag. The tag is what makes an agent report back: without it, agents finish in their own terminal and never reply. It then sets the phase label. Its output is `hc run`'s. `orc-start ci <key> <worktree> <pr url>` starts the CI watcher instead (step 8); it takes no stdin.

Send an agent a message with `${CLAUDE_SKILL_DIR}/scripts/orc-send <role> <key> < $TMPDIR/orc-<n>-<step>.md`. Stop terminals with `${CLAUDE_SKILL_DIR}/scripts/orc-stop <key> [<role>...]`: it kills and removes each one, skips any that are missing, and with no role stops them all.

## Steps

0. **Repo.** Read the ticket `$ARGUMENTS` with the tracker and take the target repo from it. If this session's project instructions say how to pick and locate a repo, follow them. Otherwise:
   - GitHub issue: the repo the issue belongs to, `owner/repo` in its key or URL.
   - Tracker ticket: its single component, as `org/repo`. With none or several, or one that names no org, ask the user.

   Find the clone at `~/_git/<org lower-cased>/<repo>`. If it is missing, check the current name with `gh repo view <org>/<repo> --json nameWithOwner`, because GitHub redirects a renamed repo, then `gh repo clone <org>/<repo> ~/_git/<org lower-cased>/<repo>`, using the current name for the folder. `<repo>` below is the clone's absolute path. Pass the spec agent the key in full form, `owner/repo#n` for GitHub, because a bare `#n` would resolve to the wrong repo.
1. **Spec.** Write the key to `$TMPDIR/orc-<n>-spec.md` and start the `spec` agent with `<repo>` as its cwd.
2. **Gate.**
   - **Unfit, and the only reason is a live write the ticket needs:** ask the user with `AskUserQuestion` whether to authorise it, write the answer to `$TMPDIR/orc-<n>-answers.md` and send it to the `spec` agent with `orc-send`. A new spec follows; gate it again.
   - **Unfit for any other reason:** the reason goes back to the ticket. An open question belongs in the ticket, where the reviewer and the next run can see it, and a change in another repo means the ticket must be split. Write the spec's Goal and Fit to `$TMPDIR/orc-<n>-comment.md` under the heading `## orc: not ready for agent`, post it on the ticket with the tracker, from `<repo>`, give the user the reasons and stop.
   - **Fit:** read its Fit, Plan and Decisions first. If any names a change in another repo, such as a companion PR or a follow-up in another repo, follow the previous bullet. Otherwise write the build task to `$TMPDIR/orc-<n>-build.md`: the whole spec message, then the line `Code only in this pass: make no live write. List each live write the spec authorises under **Live writes** in your report, with its command.` Review must come before any live change, because it cannot undo one.
3. **Build.** Mark the ticket started with the tracker, from `<repo>`. Pick the model from the spec:
   - `haiku`: mechanical or documentation-only changes;
   - `opus`: large changes, several components, or tricky logic (concurrency, auth, data migration);
   - `sonnet`: everything else.

   Start the `build` agent with `<repo>` as its cwd, the model, and the task in `$TMPDIR/orc-<n>-build.md`. Its name, `<n>`, is the worktree name. Once it is running, stop the spec agent: `orc-stop <key> spec`. The agent replies `built: <key> <worktree path>`.
4. **Gate.** On `blocked:`, or a report whose Proof says a check failed, show the user the issue and stop. Agents stay running so the user can take over.
5. **Review.** In the worktree, run `git fetch origin -q` and set `base` to `git merge-base HEAD origin/<default branch>`. Write the brief to `$TMPDIR/orc-<n>-brief.md` as follows:

   ```
   Review only. Do not edit, commit, push, comment on PRs, or start subagents.
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

   In round 1, start one `reviewer` agent for all rounds, with the worktree as its cwd and the task in `$TMPDIR/orc-<n>-brief.md`; it is named `sol-<n>`. Before rounds 2 and 3, run `${CLAUDE_SKILL_DIR}/scripts/orc-label round <r>`.

   The reply starts `VERDICT:`. On `APPROVE`, go to step 6. On `CHANGES`, send the `build` agent `Fix these review findings and prove each fix. For each finding id, reply fixed:, disagree: or declined: with evidence, then report as before.` followed by the findings, with `orc-send`. On its `built:` reply (apply step 4), send the `reviewer` `Round <r>. Same base. Check open ids and changed code only; mark each old id resolved or still open: <reason>.` followed by the builder's ledger and report, with `orc-send`. Stop after 3 rounds that end in `CHANGES`: show the user the open findings and stop.
6. **Live writes.** Skip this step if the report lists none. Otherwise send the `build` agent, with `orc-send`: `Review approved. You are authorised to make the live writes you listed that can run before merge; make them now. Before each one, save what it changes or deletes to $TMPDIR/orc-<n>/rollback/. Report as before.` Apply step 4 to its reply. Writes that need the merge first, such as a deploy sync, are left for the user.
7. **Ship.** In the worktree: commit everything with the repo's commit convention, push the branch with `-u`, keeping its name `worktree-<n>` because Finish finds the PR by it, and open the PR with the `barrydobson-skills:file-pr` skill. Its evidence is the build report's Proof, the live writes made, and the line `Reviewed with sol-loop: <rounds> rounds. Sol verdict: approved`. Then label your own terminal with the PR URL: `${CLAUDE_SKILL_DIR}/scripts/orc-label pr <pr url>`.
8. **CI.** `${CLAUDE_SKILL_DIR}/scripts/orc-start ci <key> <worktree> <pr url>`, then `hc wait ci-<n>`; on `reason: timeout`, wait again. `orc-ci` waits until the base branch's required checks (or every check, when none is required) are green on the PR's head, and prints one result line. This terminal's exit is its result, not a failure. Read its output with `hc read ci-<n>`, then `orc-stop <key> ci`. Exit 0: go to step 9. Otherwise each failed check is a line with its link. Read the failure with `gh run view <run> --log-failed`, send it to the builder, then commit and push its fix yourself and watch again. After 2 failed fixes, report to the user and stop.
9. **Ticket.** Write a comment to `$TMPDIR/orc-<n>-comment.md` and post it on the ticket with the tracker, from `<repo>`. It holds the PR link, the live writes made, anything left for the user after merge, follow-ups, and every finding the agents made that the ticket does not record, such as a premise that proved wrong. For rollback, list the path of each file in `$TMPDIR/orc-<n>/rollback/` and the commit the change started from (`base`, from step 5). Never post a rollback file's content: a copy of live state can hold secrets or customer data. Then move the ticket to review with the tracker, from `<repo>`.
10. **End.** `orc-stop <key> build reviewer`. Give the user the PR link and anything left for them, and tell them to run `/barrydobson-skills:orc --finish <key>` once the PR has merged and that work is done.

## Finish

`/barrydobson-skills:orc --finish <key>` closes the ticket once its PR has merged. The user starts it after the post-merge work step 9's comment left them, by typing it or from a Herdr panel, if one reads these labels. It works in a new session too.

F1. **Repo.** Find `<repo>` as step 0 does, with `<key>` in place of `$ARGUMENTS`, and set `<n>`. Run `${CLAUDE_SKILL_DIR}/scripts/orc-label phase finish <key>`.
F2. **PR.** Run `${CLAUDE_SKILL_DIR}/scripts/orc-pr <key> <owner/repo>`. It finds the PR on the build agent's branch, `worktree-<n>`, prints `<state> <pr url>` and labels your terminal. Exit 0: it merged; go on. Exit 1: not merged; tell the user and stop. Exit 2: no PR on that branch; tell the user and stop.
F3. **Checks.** Take what step 9's comment left for the user after merge; read the ticket with the tracker if this session did not post it. Turn each item that can be checked into a read-only check, such as "the old admission policy is gone from the staging cluster". Write the task to `$TMPDIR/orc-<n>-finish.md`:

    ```
    <key>
    Worktree: <repo>/.claude/worktrees/<n> Branch: worktree-<n>
    Post-merge checks: <the checks, or none>
    Tracker: the issue tracker's finish skill
    ```
F4. **Run.** Start the `finish` agent with `<repo>` as its cwd and the task in `$TMPDIR/orc-<n>-finish.md`; `orc-start` removes a `finish-<n>` terminal left from a stopped finish. It runs the checks, then the tracker's finish skill, and replies `finished: <key> done` or `finished: <key> skipped: <why>`.
F5. **End.** On `done`: `orc-stop <key> finish`, run `${CLAUDE_SKILL_DIR}/scripts/orc-label phase done`, and give the user the report. On `skipped:`: run `${CLAUDE_SKILL_DIR}/scripts/orc-label stop "<why in a few words>"`, show the user the report and stop. The agent stays running so the user can take over.
