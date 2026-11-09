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

## Releasing

There is nothing to release. The plugin carries no `version`, so Claude Code resolves it to the git SHA of `main`, and every merge is a release. To pick up a change:

```sh
/plugin marketplace update barrydobson
```

Then update the plugin from `/plugin`, and restart the session.
