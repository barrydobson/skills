# Barry Dobson's Skills

A private Claude Code plugin, `barrydobson-skills`, published from its own single-plugin marketplace, `barrydobson`.

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

They need the `tote-issue-tracker` plugin (which provides the `tracker` CLI) and `mattpocock-skills`. Run `/tote-issue-tracker:setup` once per repo. After a tote-issue-tracker update, restart sessions: `/reload-plugins` doesn't refresh a plugin's `bin/` on PATH.

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
