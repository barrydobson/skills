---
name: finish
description: Verify merged /work PRs against their tickets, move verified tickets to Done, and clean up.
argument-hint: "[PR number | ticket key ...] [--unattended]"
disable-model-invocation: true
---

# Finish merged work

For each merged PR, verify that what shipped meets its ticket. Then record the evidence on the ticket, move it to Done, and remove the worktree and branches. A ticket that can't be verified stays where it is, with a comment saying what is unverified. Ending in Done means *verified*; a merge alone doesn't count.

**Read-only against production.** You read state: PRs, CI, the merged diff, the tracker. You never apply, sync, deploy, retry or re-run anything. A check that would need a write is reported as unverified.

**At most one prompt per run,** and only to set up the repo's post-merge checks (step 2). The run is **unattended** when it was given `--unattended`. An unattended run never prompts.

Every tracker read and write goes through the `tracker` CLI. Status names live in the repo's `docs/agents/issue-tracker.md`; you never type one.

## 1. Find the work

- **No arguments:** every worktree under `.claude/worktrees/` (from `git worktree list --porcelain`) whose branch has a merged PR (`gh pr list --head <branch> --state merged`).
- **PR numbers or ticket keys:** those. Find a key's PR with `gh pr list --state merged --search "<key> in:title"`.

The ticket key is the scope in the PR title (`feat(<key>): ...`), or the `Refs` line for a GitHub issue. Each PR carries exactly one ticket. A PR with no key is reported and skipped.

Done when you hold a list of (ticket, PR, merge commit, worktree or none). If the list is empty, say so and stop.

## 2. Load the post-merge checks

Post-merge checks are the repo's own read-only checks that a merged change is live and healthy. Examples: "Terrateam apply succeeded on the PR", "the Argo app is synced and healthy", a Groundcover query. They live in the `## Post-merge checks` section of the repo's CLAUDE.md, one check per bullet. Each bullet says what to read and what counts as a pass.

- **The section exists:** use it.
- **No section, attended run:** infer likely checks from the repo, for example a Terrateam config, Argo or Helm manifests, or monitor definitions. Propose them as bullets. That message holds only this one question, and nothing in step 3 runs until it is answered. Write the confirmed section into CLAUDE.md and tell the human it's an uncommitted change to commit.
- **No section, unattended run:** carry on without it.

Done when the section exists (it was already there, or you have just written it), the human has declined, or the run is unattended.

## 3. Verify each ticket

These checks run for every ticket:

1. **Merged.** The PR state is `MERGED`.
2. **Checks green.** Read both sources. GitHub Apps such as Terrateam report only as checks, so `gh run list` alone misses them.
   - The PR's checks: `gh pr checks <n> --json name,bucket`. Every bucket is `pass` or `skipping`.
   - The merge commit's checks: `gh api repos/{owner}/{repo}/commits/<merge commit>/check-runs --jq '.check_runs[] | {name, status, conclusion}'`. Every run is completed with `success`, `skipped` or `neutral`.

   A `pending` bucket or an unfinished run means *not yet*: report it, and leave the ticket untouched for a later `/finish`. When both sources are empty, record "no checks configured".
3. **Acceptance criteria hold against what shipped.** Read `tracker view <key>`: the summary, `descriptionText`, and any `## Agent Brief` comment, which is the contract. Read the shipped change with `gh pr diff <n>`, and the merged code at the merge commit. For every criterion, record one line:
   - **MET:** the evidence (file, test name, golden, command output);
   - **NOT MET:** what is missing;
   - **LIVE CHECK:** what would need checking in a running system, and why the diff can't show it.
4. **Post-merge checks hold.** Run each check from step 2 read-only, and record pass or fail with its output. A check whose target hasn't caught up yet, such as an Argo sync still in progress, counts as *not yet*.

A LIVE CHECK criterion can be settled by running a local, read-only command against the merged code, such as a rule unit test or a template render. Record the exact command and its output as the evidence. Anything that needs the running system stays LIVE CHECK.

A ticket **passes** when every check holds and every criterion is met. Anything else **fails**. *Not yet* is neither.

## 4. Record and move

**Pass:**
1. Write the evidence to a file with the Write tool, then `tracker comment <key> --body-file <file>`. The evidence is: the PR link, the merge commit, the CI result, each post-merge check with its output, and each criterion with its MET line.
2. `tracker done <key>`.
3. Clean up:
   ```sh
   git worktree remove .claude/worktrees/<id>    # <id> as /work named it: pi-123, or gh-<n>
   git branch -D <branch>
   git push origin --delete <branch>   # skip if the remote branch is already gone
   ```
   When `git worktree remove` refuses because of uncommitted changes, leave the worktree and name it in the report.

**Fail:** `tracker comment <key> --body-file <file>` listing every NOT MET and LIVE CHECK line, plus any CI or post-merge check failure. Leave the status and the worktree as they are.

When every ticket is processed, update the default branch: `git pull --ff-only` if the main checkout is on it, otherwise `git fetch origin <default>:<default>`.

## 5. Newly unblocked tickets

For each ticket moved to Done, look at its links with relation `blocks`. A blocked ticket whose `is blocked by` links now all point at Done tickets is **unblocked**. List it with its status.

## 6. Report

One table, with a row per ticket: key, PR, result (Done / stays in review / not yet / skipped), the reason when it isn't Done, and the worktree left behind, if any. Under the table, list the unblocked tickets as `/work <keys>`.
