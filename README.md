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
| [writing-skills](skills/writing-skills/) | Writes and reviews skills against Anthropic best practice, with a findings table and a fix per issue. |
| [be-ambitious](skills/be-ambitious/) | `/be-ambitious` makes a task or prompt more ambitious. |
| [technical-docs](skills/technical-docs/) | `/technical-docs` writes reader-facing prose in Google developer documentation style, through the `technical-writer` agent. |
| [theme-factory](skills/theme-factory/) | Applies a colour and font theme to visual output, including my Voltaic dark and light themes. |
| [correct](skills/correct/) | `/correct` finds mistakes agents repeat in a repo and makes each one impossible. |
| [blast-radius](skills/blast-radius/) | `/blast-radius` finds what a change could break outside the diff, and proves the fact it is safe because of. |
| [unslop](skills/unslop/) | `/unslop` cuts AI tells from any writing. |
| [sol-loop](skills/sol-loop/) | Reviews a working-tree change with GPT Sol in a loop until it approves, through a route the user can watch or a native subagent. |
| [find-docs](skills/find-docs/) | Fetches current library and API docs through Context7. Needs `npx` (runs `ctx7`). |
| [officecli-pptx](skills/officecli-pptx/) | Reads, creates and edits `.pptx` decks. Needs `officecli`. |
| [tavily-search](skills/tavily-search/) | Searches and reads the web with Tavily. Needs `tvly`. |
| [tavily-research](skills/tavily-research/) | Researches a topic in depth across many sources with Tavily. Needs `tvly`. |

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
