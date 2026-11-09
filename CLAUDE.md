# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal Claude Code plugin, public on GitHub, `barrydobson-skills`, in the repo `barrydobson/skills`. The repo root is both the plugin and a single-plugin marketplace (`barrydobson`) whose entry has `source: "./"`. It holds personal skills that work on any machine. The skills table is in README.md.

## Project Structure

```
.claude-plugin/
  marketplace.json      # Marketplace index: one entry, source "./"
  plugin.json           # Plugin metadata (name, description, author)
skills/<skill-name>/    # One directory per skill:
  SKILL.md              #   Skill definition (frontmatter + instructions)
  references/           #   Supporting reference docs read by the skill
  assets/               #   Static assets (logos, images)
agents/                 # Subagents, namespaced as barrydobson-skills:<name>
tools/                  # Repo maintenance scripts (/scripts/ is gitignored scratch)
```

A doc two skills both depend on goes in a root `shared/` directory, reached as
`${CLAUDE_PLUGIN_ROOT}/shared/<file>.md`. Prefer this over a new skill: a shared
spine is an include, not a capability, and a skill would sit in every session's
skill listing and be liable to trigger on its own.

## Adding a New Skill

Add `skills/<skill-name>/SKILL.md`. Claude Code discovers it from the `skills/` directory, so no manifest change is needed.

A skill tied to one machine, a local binary or the Obsidian vault belongs in dotfiles as a user skill. So does anything that names Tote internals, because this repo is public.

### Vendored skills

A skill copied from another project keeps its upstream text, with these rules:

- Record the upstream tree URL and full commit under `metadata.source` and `metadata.upstream_sha` in the frontmatter.
- Commit the verbatim copy first and each local change after it, one commit each, so the local changes stay readable against upstream.
- Add the project and its licence to `THIRD_PARTY_NOTICES.md`.
- Leave its bundled scripts as upstream wrote them. Add their directory to the `shellcheck` and `shfmt` excludes in `.pre-commit-config.yaml`.
- Run `tools/upstream-diff.sh` to see what changed upstream, and `--local <skill>` to see your own changes against the recorded base.
- Pull an update with `--merge <skill>`. It three-way merges upstream's change into your copy and moves `upstream_sha` forward. Resolve any conflict markers, review `git diff`, then commit it as `chore(<skill>): merge upstream <sha>`.
- Give each local change its own commit, scoped to the skill (`feat(<skill>): ...`), with the reason in the body.

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
- Skills reference `${CLAUDE_SKILL_DIR}` in SKILL.md to point to their own directory at runtime
- The `.claude/` directory is gitignored (local plugin cache), except `.claude/skills/`
- `.mcp.json` is gitignored (may contain API keys)

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `barrydobson/skills`, via `gh`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `CONTEXT.md` and `docs/adr/`, created lazily. See `docs/agents/domain.md`.
