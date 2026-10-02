---
name: work
description: Work ready-for-agent tickets to open PRs, in parallel, unattended after one up-front check-in.
argument-hint: "<key ...> | <parent key> | all ready-for-agent  [--yes]"
disable-model-invocation: true
---

# Work tickets to PRs

You are the **coordinator**. You resolve the work set, check in with the human once, and then run unattended. For each ticket you claim it, dispatch an implementer, review the work, open the PR and move the ticket to review. Tickets run in parallel, each in its own worktree with its own PR. The implementers write the code; you keep your context for the run.

Every tracker read and write goes through the `tracker` CLI (`tracker <verb> <key>`, JSON on stdout, exit 1 with `{"error": ...}` on failure). The repo's tracker config, including this repo's `component` and the status each verb maps to, is the frontmatter of `docs/agents/issue-tracker.md`.

## 1. Resolve the work set

Expand the arguments into candidate tickets:

- **A key** (Jira `PI-123`, or GitHub `#12`, `owner/repo#12` or an issue URL): `tracker view <key>`. If it is a parent (`issueType` is `Epic`, or `tracker children <key>` lists any child), the candidates are `tracker children <key> --ready --repo <component>`, and the parent itself is never a candidate.
- **"all ready-for-agent"** (or similar wording): the candidates are `tracker ready`.

For every candidate, `tracker view` it and read the summary, `descriptionText` and every comment. A `## Agent Brief` comment is the contract and outranks the description.

Then sort each candidate into one of two groups:

- **Skipped, with the reason.** Use the first reason that applies:
  - its status is not the one mapped to `ready-for-agent`. A GitHub issue with no triage label is ready only when the human named it explicitly;
  - it has a link with relation `is blocked by` to a ticket whose status is not the one mapped to `done`. Record it as "waits on <blocker> merging", including when the blocker is in this same set.
- **Workable:** everything else.

Every workable ticket is independent of the others, so they all run at once. Each ticket gets its own PR, because `/finish` maps one PR to one ticket. When two tickets look like one change, name the overlap in the check-in as a note for `to-tickets`, and still give them separate PRs.

Done when every candidate is either workable or skipped with a reason.

## 2. Check in (the only interactive step)

Send one message containing:

- the plan: one row per workable ticket, with key, summary, branch name and implementer model;
- the skipped list, with reasons;
- every open question, grouped by ticket. Look for missing acceptance criteria, ambiguous behaviour, and interfaces the ticket names that the code lacks. Also ask about any ticket whose component isn't this repo's `component` or that has no component: should it be worked here?

Give a recommended answer with every question. Wait for "go". The answers can drop tickets from the plan. "Go" with questions left unanswered accepts the recommended answer for each, and those defaults go in the step 7 report. With `--yes` and no open questions, go straight on.

Done when the human has said go (or `--yes` applied) and every question has an answer. From here until step 7, nothing reaches the human.

## 3. Claim, isolate, dispatch

For each workable ticket:

```sh
tracker start <key>
git fetch origin
base=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
git worktree add .claude/worktrees/<id> -b <id>-<short-slug> "origin/$base"
```

`<id>` is the lowercase Jira key (`pi-123`), or `gh-<n>` for a GitHub issue. If `.claude/worktrees/<id>` already exists from an earlier run, reuse it instead of adding it, and record its HEAD as the base SHA. Otherwise record the base SHA of the new worktree. Write the ticket to `${TMPDIR:-/tmp}/work/<repo>/<id>.md`, where `<repo>` is the repo's directory name: the summary, `descriptionText`, the agent brief, and the answers from step 2.

Then dispatch one implementer per ticket with [references/implementer.md](references/implementer.md). Model: `sonnet`, or `opus` when the brief or a comment asks for it. With one ticket, dispatch it in the foreground. With several, send them all in one message with `run_in_background: true`; each one notifies you when it finishes.

As each implementer reports:

- **DONE / DONE_WITH_CONCERNS** → steps 4 to 6 for that ticket.
- **BLOCKED / NEEDS_CONTEXT** → the failure path.

## 4. Review

Run `mattpocock-skills:code-review` (the fully qualified name; the bare `/code-review` is a different, built-in skill) from inside the ticket's worktree, with fixed point `<base SHA>` and spec `${TMPDIR:-/tmp}/work/<repo>/<id>.md`.

## 5. One fix round

Send findings that are correct and inside the ticket's scope back to the same implementer: find its id with `ListAgents` and `SendMessage` the findings verbatim. There is one round. Every finding still open after it goes into the PR body.

## 6. PR and hand-off

```sh
git -C .claude/worktrees/<id> push -u origin HEAD
gh pr create --title "<type>(<key>): <summary>" --body-file <body file>
tracker review <key>
```

`<type>` is the conventional-commit type of the change (`feat`, `fix`, `refactor`...), because the squash-merge makes the title the commit subject on `main`.

Open the PR non-draft, and only once. The body covers, in this order:

- each acceptance criterion, with met / not met;
- the suite and linter result the implementer reported;
- assumptions logged;
- review findings still open;
- the worktree path.

For a GitHub issue, reference it with `Refs #<n>`, so the issue stays open until `/finish` verifies it.

## 7. Report

Once every ticket has a PR or has failed, send one table with a row per ticket: key, PR URL or "needs-info", the status it is now in, and open findings. Under it, list the skipped tickets with what each waits on, and any recommended answers taken by default at step 2.

## Failure path

When an implementer is BLOCKED or NEEDS_CONTEXT, or `git worktree add` or a push fails, for that ticket only:

1. `tracker comment <key> --body-file <file>`, saying what was attempted, what is missing, and the worktree path if it holds commits.
2. `tracker needs-info <key>`.
3. Remove the worktree and branch when they hold no commits. Otherwise, leave them and name them in the report.

The other tickets carry on. This one goes back through triage.

## Rules for the coordinator

- **Unattended after step 2.** A question that comes up later is logged as an assumption in that ticket's PR body.
- **The implementers write the code.** A one-line fix from the review is the only code you touch, and you list it in the PR body as coordinator-fixed.
- **Status names live in the config.** You move tickets only with `tracker start | review | needs-info`; `tracker` picks the transition.
- **Dependencies wait for merges.** A ticket blocked by unmerged work is skipped and reported, never stacked on another branch.
- **The PR is where a ticket's run ends.** CI, merging and Done belong to the human and `/finish`.
