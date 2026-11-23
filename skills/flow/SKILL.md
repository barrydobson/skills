---
name: flow
description: Builds the tracker ticket or GitHub issue linked to the current Orca workspace into a Codex-reviewed PR through Orca orchestration workers, and closes it after merge.
disable-model-invocation: true
argument-hint: "[ticket-key] | --finish [ticket-key]"
---

# flow

Take the ticket linked to this Orca workspace from spec to an open PR. If `$ARGUMENTS` starts with `--finish`, follow **Finish** instead of steps 0 to 6. Hand spec, build and review to Orca workers; do no repo work yourself until step 5.

The human starts flow from Orca's Tasks view: they create a workspace from the ticket, which links the ticket to it, and launch Claude there with the prompt `/barrydobson-skills:flow`. A Quick Command can hold that prompt, and `/barrydobson-skills:flow --finish`, for a workspace that already exists. Any workspace linked to the ticket works, so a script can create them too, with `orca worktree create --reference <key> --agent claude --prompt "/barrydobson-skills:flow"`.

Needs the Orca desktop app or server running, the `orca`, `claude`, `codex` and `gh` CLIs, and an issue tracker skill or CLI in this session. Workers launch with Orca's own **Agent Permissions** setting; on work repos it must not be Yolo.

## Before you start

Run `orca skills get orchestration` once and follow it for everything about workers: ending your turn after a start or a message, how Orca wakes you, answering `ask` questions, escalations, and never polling. flow adds only the steps below. Use the `orca` executable for every command.

## Issue tracker

Use whichever issue tracker skill or CLI this session has loaded. flow needs five operations from it: **read** a ticket with its comments, **start** it (mark it in progress), **comment** on it from a file, move it to **needs-info** (out of the agent queue) and to **review**, and the tracker's **finish skill**. If the session has none, stop and say so. Run every tracker command from this workspace, so it reads the repo's tracker config.

## Conventions

Before writing any file, run `${CLAUDE_SKILL_DIR}/scripts/flow-dir <key>` once. It creates the ticket's run directory, private to this user, and prints its absolute path: `<dir>` below is that path. Write it out in full in every Write and Bash call, because shell variables do not persist between Bash calls.

Never put agent-written text (specs, reports, findings, answers) inside a quoted shell argument: backticks and `$` in it would run in your shell. Write it to a file in `<dir>` with the Write tool and pass the file: `--spec-file -` from a pipe to `worker-start`, `--body-file` to `send`, a file to the tracker.

Start a worker by piping its role prompt and its task file into `worker-start`:

```sh
cat ${CLAUDE_SKILL_DIR}/prompts/<role>.md <dir>/<role>.md | orca orchestration worker-start --spec-file - --task-title "<role> <key>" --worktree current --keep-open --agent <agent> [--model <id>]
```

Orca's sidebar lists each worker by its terminal tab title, which starts as `worker-task_<id>`. Right after each start, take the worker's terminal handle from the receipt, or from `orca orchestration worker-show --dispatch <id> --json`, and name the tab after its job: `orca terminal rename --terminal <handle> --title "<key> <role>: <purpose in a few words>"`, for example `PI-2830 build: add the retry flag`. In step 1, name your own tab the same way: `orca terminal rename --title "<key> flow: coordinator"`.

For the `spec` role, put `${CLAUDE_PLUGIN_ROOT}/shared/ready-for-agent.md` between the prompt and the task file, so the worker gets the readiness rules.

All workers share this workspace, one at a time. `--keep-open` keeps the builder and reviewer sessions alive between review rounds. Reach a worker with `orca orchestration send --to dispatch:<dispatch id> --subject "<subject>" --body-file <dir>/<file>.md`. Orca records every dispatch: `orca orchestration worker-list --run <run id>` finds them again.

Whenever you stop for the user, first record the reason where Orca's sidebar shows it: `orca worktree set --worktree current --comment "flow: <reason in a few words>"`.

## Steps

0. **Ticket.** Run `orca worktree current --json`. If it fails or names the main worktree, stop: flow runs in a workspace created from the ticket. Take the key from `$ARGUMENTS` if given, else from the single issue link (Jira or GitHub) in `orca reference list --worktree current --json`. With no link or several, ask the user. If `$ARGUMENTS` named a key that is not linked, link it: `orca reference add <key or issue URL> --worktree current` (GitHub needs the full URL).

   Then check for an earlier run of this ticket: a Run in `orca orchestration run-list --json` whose objective starts with `<key>:`. If there is one, `orca orchestration run-use --id <run id>` and read `task-list --full` and `worker-list --run <run id>`. Carry on from the first step that has not finished: a linked PR means step 5 is done, and the ticket in review means step 6 is.
1. **Run.** Read the ticket with the tracker. Run `orca orchestration run-create --objective "<key>: <ticket title>"`. Then `orca worktree set --worktree current --workspace-status in-progress`, so Orca's sidebar and board show the run under In progress.
2. **Spec.** Write the key in full form (`owner/repo#n` for GitHub) to `<dir>/spec.md` and start the `spec` worker with `--agent claude`. On its report:
   - **needs-info** or **ready-for-human**, or **ready-for-agent** with a Readiness, Plan or Decision that names a change in another repo (treat that as needs-info): write the spec's Goal and Readiness to `<dir>/comment.md` under the heading `## flow: not ready for agent`, post it on the ticket and move the ticket to that state, so the next run does not pick it up again. Then give the user the reasons and stop.
   - **ready-for-agent:** write the whole spec to `<dir>/build.md` as the build task.
3. **Build.** Mark the ticket started with the tracker. Pick the model from the spec:
   - `claude-haiku-5-5`: mechanical or documentation-only changes;
   - `claude-opus-5-5`: large changes, several components, or tricky logic (concurrency, auth, data migration);
   - `claude-sonnet-5-5`: everything else.

   Start the `build` worker with `--agent claude --model <id>`. Answer its `ask` questions from the spec and the ticket; ask the user only what those do not settle. Its report starts `built: <key>`. If its outcome is failed, or its Proof says a check failed, show the user the issue and stop. The worker stays open so the user can take over in its chat.
4. **Review.** Run `git fetch origin -q` and set `base` to `git merge-base HEAD origin/<default branch>`. Write the brief to `<dir>/reviewer.md`, one field per line: `Repo: <workspace path>`, `Base: <base>`, `Intent: <spec Goal>`, `Out of scope: <spec Out of scope>`, `Checks: <the build report's Proof>`. Start the `reviewer` worker with `--agent codex`.

   Its report starts `VERDICT:`. On `APPROVE`, go to step 5. On `CHANGES`, write the findings to `<dir>/findings.md` and send them to the builder. On its `built:` report (apply step 3's failure rule), write `Round <r>.` followed by the builder's ledger and report to `<dir>/round.md` and send it to the reviewer. Stop after 3 rounds that end in `CHANGES`: show the user the open findings and stop.
5. **Ship.** Commit everything with the repo's commit convention, push the branch with `-u`, and open the PR with the `barrydobson-skills:file-pr` skill. Its evidence is the build report's Proof and the line `Reviewed by Codex: <rounds> rounds. Verdict: approved`. Link the PR to the workspace with `orca reference add <pr url> --worktree current`, so Orca's PR pane shows it with its checks.
6. **Ticket.** Write a comment to `<dir>/comment.md` under the heading `## flow: PR open` and post it on the ticket. It holds the PR link, the commit the change started from (`base`), anything left for the user after merge, follow-ups, and every finding the agents made that the ticket does not record, such as a premise that proved wrong. Move the ticket to review. Run `orca orchestration worker-release --dispatch <id>` for the builder and the reviewer, then `orca worktree set --worktree current --workspace-status in-review --comment "flow: PR open, waiting on merge"`.

   Give the user the PR link and anything left for them. CI is theirs: the PR pane shows the checks, and **Fix broken checks** hands a failure to an agent. Once the PR has merged, they run `/barrydobson-skills:flow --finish` in this workspace.

## Finish

`/barrydobson-skills:flow --finish [key]` closes the ticket once its PR has merged. It works in a new session in the ticket's workspace.

F1. **Ticket.** Find the key as step 0 does, without the earlier-run check. Run `flow-dir` for `<dir>`.
F2. **PR.** Take the PR link from `orca reference list --worktree current --json` and run `gh pr view <pr url> --json state,mergeCommit`. If it is not merged, tell the user and stop.
F3. **Checks.** Read the ticket with the tracker and take what step 6's comment left for the user after merge. Run each item that can be checked as a read-only check, such as "the old admission policy is gone from the staging cluster". If one fails, or you cannot run it, record the stop reason, show the user and stop: a ticket must not reach Done with a criterion unchecked.
F4. **Close.** Run the tracker's finish skill with the key and each check with its result. This command is the explicit request that skill needs. Tell it to leave the worktree and the local branch: Orca owns them.
F5. **End.** Give the user finish's report. Then, if `git status --short` is empty, remove the workspace as the last action, because it ends this session: `orca worktree rm --worktree current --delete-branch`. Otherwise name the uncommitted files and leave the workspace for the user.
