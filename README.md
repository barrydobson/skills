# Barry Dobson's Skills

A personal Claude Code plugin, `barrydobson-skills`, published from its own single-plugin marketplace, `barrydobson`.

## Installation

```sh
/plugin marketplace add barrydobson/skills
/plugin install barrydobson-skills@barrydobson
```

### Local Development

Add the repository as a marketplace from its local path:

```sh
/plugin marketplace add ~/_git/barrydobson/skills
```

## Skills

| Skill | Description |
|-------|-------------|
| [work](skills/work/) | `/work` takes ready-for-agent tickets to PRs unattended. |
| [finish](skills/finish/) | `/finish` verifies merged work and moves tickets to Done. |

They need `mattpocock-skills`, which installs as a dependency, and a `tracker` CLI on `PATH`, which you supply.

### The `tracker` CLI

Both skills read and write tickets only through `tracker`. Any CLI with this interface works. I use `tote-issue-tracker`, which supports Jira and GitHub Issues.

Every command prints JSON on stdout. On failure it exits 1 and prints `{"error": "..."}`.

| Command | Used by | Does |
|---|---|---|
| `tracker view <key>` | both | Prints the ticket: `summary`, `status`, `issueType`, `descriptionText`, `comments[]` (`text`), and `links[]` (`relation`, `key`, `status`) |
| `tracker children <parent> [--ready] [--repo <component>]` | `/work` | Lists child tickets, optionally only ready ones for one component |
| `tracker ready [--repo <component>]` | `/work` | Lists every ready-for-agent ticket |
| `tracker start <key>` | `/work` | Moves the ticket to in progress and assigns it to you |
| `tracker review <key>` | `/work` | Moves the ticket to in review |
| `tracker needs-info <key>` | `/work` | Moves the ticket back to needs-info |
| `tracker done <key>` | `/finish` | Moves the ticket to done |
| `tracker comment <key> --body-file <md>` | both | Adds a Markdown comment |

A link's `relation` is `is blocked by` or `blocks`. Each repo's config, including its `component` and the status each command maps to, lives in the frontmatter of `docs/agents/issue-tracker.md`.

With `tote-issue-tracker`, run `/tote-issue-tracker:setup` once per repo. After you update it, restart your sessions, because `/reload-plugins` doesn't refresh a plugin's `bin/` on `PATH`.

Which skills to use for which job:

| Job | Commands |
|---|---|
| Big or fuzzy idea, epic, multi-repo | `grilling` (or `grill-with-docs`) → `to-spec` → `to-tickets` → `/work <EPIC>` in each repo's session → merge → `/finish` |
| Single ticket | `triage <KEY>` (if not ready) → `/clear` → `/work <KEY>` → merge → `/finish` |
| Several tickets, or "all ready" | `/work <K1> <K2>…` or `/work all ready-for-agent` → merge → `/finish` |
| Bug | `diagnosing-bugs` → `to-tickets` → `/work` |
| Ad-hoc idea in a session | `to-tickets` from the conversation |
| Side tools | `research`, `prototype`, `handoff`, `wayfinder` (for initiatives too fuzzy for one grill) |
| Solo or personal repo, small change | Matt Pocock's skills directly; no ticket needed |

A ticket is ready when it can ship in its entirety, with acceptance criteria that `/finish` can check. Only `triage`, or `to-tickets` output you have approved, makes a ticket ready.

## Releasing

There is nothing to release. The plugin carries no `version`, so Claude Code resolves it to the git SHA of `main`, and every merge is a release. To pick up a change:

```sh
/plugin marketplace update barrydobson
```

Then update the plugin from `/plugin`, and restart the session.
