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
| [file-pr](skills/file-pr/) | Files a concise pull request with a problem-first body, evidence and merge risk. |
| [leaving-pr-comments](skills/leaving-pr-comments/) | Rules for leaving comments on GitHub. |
| [reviewing-plugins](skills/reviewing-plugins/) | Reviews skills, plugins and marketplaces against current Anthropic guidance. |
| [be-ambitious](skills/be-ambitious/) | `/be-ambitious` makes a task or prompt more ambitious. |
| [technical-docs](skills/technical-docs/) | `/technical-docs` writes reader-facing prose in Google developer documentation style, through the `technical-writer` agent. |
| [personal-brand](skills/personal-brand/) | Applies my personal colours and fonts to visual output. |
| [handoff](skills/handoff/) | `/handoff` compacts the conversation into a document another agent can pick up. |
| [retro](skills/retro/) | `/retro` runs a retrospective on a coding session. |
| [writing-for-agents](skills/writing-for-agents/) | How to write skills, `AGENTS.md` and `CLAUDE.md`. |
| [diagnosing-bugs](skills/diagnosing-bugs/) | A diagnosis loop for hard bugs, CI failures and performance regressions. |
| [wizard](skills/wizard/) | Generates a bash wizard that walks a human through steps only they can do. |
| [correct](skills/correct/) | `/correct` finds mistakes agents repeat in a repo and makes each one impossible. |
| [blast-radius](skills/blast-radius/) | `/blast-radius` finds what a change could break outside the diff, and proves the fact it is safe because of. |
| [unslop](skills/unslop/) | `/unslop` cuts AI tells from any writing. |
| [grilling](skills/grilling/) | Grills you about a plan, decision or idea until it holds up. |
| [to-spec](skills/to-spec/) | `/to-spec` turns the conversation into a spec on the issue tracker. |
| [to-tickets](skills/to-tickets/) | `/to-tickets` breaks a plan into tracer-bullet tickets, one repo each, with blocking edges. |
| [triage](skills/triage/) | `/triage` moves issues through triage roles and writes agent-ready briefs. |
| [setup-matt-pocock-skills](skills/setup-matt-pocock-skills/) | `/setup-matt-pocock-skills` configures a repo's issue tracker, triage labels and domain docs for the planning skills. |

Some of these are copied from other projects. [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) lists them and their licences. To see what has changed upstream since they were copied, run:

```sh
tools/upstream-diff.sh        # summary
tools/upstream-diff.sh -p     # with patches
```

## Releasing

There is nothing to release. The plugin carries no `version`, so Claude Code resolves it to the git SHA of `main`, and every merge is a release. To pick up a change:

```sh
/plugin marketplace update barrydobson
```

Then update the plugin from `/plugin`, and restart the session.
