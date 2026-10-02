# Implementer dispatch

Fill every `<...>`. Never pass a `name`: a named dispatch becomes an asynchronous teammate that returns no report. Foreground for a single ticket; `run_in_background: true` for each ticket in a set.

```
Agent (general-purpose):
  description: "Implement <key>"
  model: <sonnet | opus - always set>
  run_in_background: <false for one ticket, true for a set>
  prompt: |
    You are implementing ticket <key>: <summary>.

    ## The ticket

    <the contents of ${TMPDIR:-/tmp}/work/<repo>/<id>.md, pasted verbatim>

    The agent brief, where there is one, is the contract. The answers at the
    end were given by the human before the run started.

    ## Where

    Work in <worktree path> on branch <branch>. Edit, test and commit there.
    Pushing, PRs and the tracker belong to the coordinator.

    ## How

    1. Follow the `mattpocock-skills:tdd` skill. The brief's acceptance
       criteria and interfaces are the agreed seams; there is nobody to agree
       new ones with.
    2. Make the smallest change that meets every acceptance criterion, in the
       patterns this codebase already uses. Create and edit files with the
       Write and Edit tools; the shell is for running commands.
    3. Run the focused tests while you iterate. At the end run the repo's
       full suite and linters with output redirected to
       ${TMPDIR:-/tmp}/work/<repo>/<id>-suite.log, never a file inside the
       worktree, and read only the tail and any failure lines.
    4. `git add -A` (new files are untracked until you do) and commit with a
       conventional-commit message that names <key>.
    5. Read your own diff once with fresh eyes against the acceptance criteria,
       fix what you find, commit again.

    ## This run is unattended

    Nobody is there to answer. Where the ticket is silent, make the reasonable
    call and record it as an assumption. Report BLOCKED instead when the work
    needs an architectural decision with several valid answers, contradicts
    itself or the code, names an interface that does not exist, or is far
    larger than the ticket implies. An honest BLOCKED beats work you doubt.

    Do this work yourself; the coordinator runs the review after you report.

    ## Reply (under 10 lines)

    - Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - What landed, and the file count
    - Suite and linter result, with the commands
    - Each acceptance criterion: met / not met
    - Assumptions and concerns, one line each
    For BLOCKED or NEEDS_CONTEXT: what you tried and exactly what is missing.
```

## Fix round

Reuse the same implementer: its id is in `ListAgents`. `SendMessage` it the findings verbatim, and it replies with the same contract and a new commit. If it is no longer listed, dispatch this template again with the findings and the current branch state added under "The ticket".
