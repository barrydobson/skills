# orc --finish

Follow this only for `/barrydobson-skills:orc --finish <key>`. `<skill dir>` is the directory SKILL.md gave when it sent you here. Everything in SKILL.md before **Steps** (Issue tracker, Conventions, Agents) still applies.

`/barrydobson-skills:orc --finish <key>` closes the ticket once its PR has merged. The user starts it after the post-merge work step 9's comment left them, by typing it or from a Herdr panel, if one reads these labels. It works in a new session too.

F1. **Repo.** Find `<repo>` as step 0 does, with `<key>` in place of `$ARGUMENTS`, and set `<n>`. Run `<skill dir>/scripts/orc-label phase finish <key>`.
F2. **PR.** Run `<skill dir>/scripts/orc-pr <key> <owner/repo>`. It finds the PR on the build agent's branch, `worktree-<n>`, prints `<state> <pr url>` and labels your terminal. Exit 0: it merged; go on. Exit 1: not merged; tell the user and stop. Exit 2: no PR on that branch; tell the user and stop.
F3. **Checks.** Take what step 9's comment left for the user after merge; read the ticket with the tracker if this session did not post it. Turn each item that can be checked into a read-only check, such as "the old admission policy is gone from the staging cluster". Write the task to `$TMPDIR/orc-<n>-finish.md`:

    ```
    <key>
    Worktree: <repo>/.claude/worktrees/<n> Branch: worktree-<n>
    Post-merge checks: <the checks, or none>
    Tracker: the issue tracker's finish skill
    ```
F4. **Run.** Start the `finish` agent with `<repo>` as its cwd and the task in `$TMPDIR/orc-<n>-finish.md`; `orc-start` removes a `finish-<n>` terminal left from a stopped finish. It runs the checks, then the tracker's finish skill, and replies `finished: <key> done` or `finished: <key> skipped: <why>`.
F5. **End.** On `done`: `orc-stop <key> finish`, run `<skill dir>/scripts/orc-label phase done`, and give the user the report. On `skipped:`: run `<skill dir>/scripts/orc-label stop "<why in a few words>"`, show the user the report and stop. The agent stays running so the user can take over.
