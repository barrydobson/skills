# Barry Dobson's Skills

A personal agent skills plugin, `barrydobson-skills`, for Claude Code and Codex, published from its own single-plugin marketplace, `barrydobson`. Both use the same `skills/` directory.

## Installation

### Claude Code

```sh
/plugin marketplace add barrydobson/skills
/plugin install barrydobson-skills@barrydobson
```

### Codex

```sh
codex plugin marketplace add barrydobson/skills
codex plugin add barrydobson-skills@barrydobson
```

Start a new session after installing. Use `/skills` or type `$` to select a skill, for example `$file-pr`. Skills marked explicit-only in Claude Code stay explicit-only in Codex through `agents/openai.yaml`.

The [OpenAI plugin packaging guide](https://developers.openai.com/plugins/build/plugins) documents the Codex manifest and marketplace format. This repo uses the supported `.codex-plugin/plugin.json` format to keep the existing unversioned release workflow.

### Local Development

Add the repository as a marketplace from its local path:

```sh
/plugin marketplace add ~/_git/barrydobson/skills
```

For Codex, register the checkout and install the plugin:

```sh
codex plugin marketplace add ~/_git/barrydobson/skills
codex plugin add barrydobson-skills@barrydobson
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
tools/upstream-diff.sh                 # what changed upstream
tools/upstream-diff.sh -p              # the same, with patches
tools/upstream-diff.sh --local <skill> # your local changes to a skill
tools/upstream-diff.sh --merge <skill> # pull upstream changes into your copy
```

## Releasing

There is nothing to release. The manifests carry no `version`. Claude Code resolves the plugin to the git SHA of `main`, so every merge is a release. To pick up a change in Claude Code:

```sh
/plugin marketplace update barrydobson
```

Then update the plugin from `/plugin`, and restart the session.

For a Git-backed Codex installation, refresh the marketplace and reinstall the plugin, then start a new session:

```sh
codex plugin marketplace upgrade barrydobson
codex plugin add barrydobson-skills@barrydobson
```
