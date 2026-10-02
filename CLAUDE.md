# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A private Claude Code plugin, `barrydobson-skills`, in the repo `barrydobson/skills`. The repo root is both the plugin and a single-plugin marketplace (`barrydobson`) whose entry has `source: "./"`. It holds `/work` and `/finish`. The job-to-commands table is in README.md.

## Project Structure

```
.claude-plugin/
  marketplace.json      # Marketplace index: one entry, source "./"
  plugin.json           # Plugin metadata (name, description, author)
skills/<skill-name>/    # One directory per skill:
  SKILL.md              #   Skill definition (frontmatter + instructions)
  references/           #   Supporting reference docs read by the skill
  assets/               #   Static assets (logos, images)
```

A doc two skills both depend on goes in a root `shared/` directory, reached as
`{baseDir}/../../shared/<file>.md`. Prefer this over a new skill: a shared
spine is an include, not a capability, and a skill would sit in every session's
skill listing and be liable to trigger on its own.

## Adding a New Skill

Add `skills/<skill-name>/SKILL.md`. Claude Code discovers it from the `skills/` directory, so no manifest change is needed.

A skill that only you use and that fits no workflow here belongs in dotfiles as a user skill.

## Versioning and release

The plugin is unversioned. With no `version` in `plugin.json`, Claude Code resolves it to the git SHA of `main`, so every merge is a release. To pick it up, run `/plugin marketplace update barrydobson`, update the plugin, then restart the session. There are no changesets, release PRs or tags to manage.

## Installation and Testing

```sh
# Install
/plugin marketplace add barrydobson/skills
/plugin install barrydobson-skills@barrydobson

# Local dev
/plugin marketplace add ~/_git/barrydobson/skills
```

## Linting

Pre-commit hooks handle linting. Hooks configured:

- `shellcheck`: shell script linting
- `shfmt`: shell formatting (2-space indent)
- `check-yaml`, `check-json`: syntax validation
- `end-of-file-fixer`, `trailing-whitespace`

## Key Conventions

- No versions anywhere. Resolution is `plugin.json` → marketplace plugin entry → git SHA, and both are left without a version. `marketplace.json` `metadata` holds the description only
- Skills reference `{baseDir}` in SKILL.md to point to their own directory at runtime
- The `.claude/` directory is gitignored (local plugin cache), except `.claude/skills/`
- `.mcp.json` is gitignored (may contain API keys)

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `barrydobson/skills`, via `gh`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `CONTEXT.md` and `docs/adr/`, created lazily. See `docs/agents/domain.md`.
