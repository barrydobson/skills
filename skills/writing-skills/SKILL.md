---
name: writing-skills
description: Writes new Claude skills and reviews existing ones against Anthropic's skill-authoring best practice, reporting every issue in a table with a concrete fix. Use when the user asks to write, create, draft, review, audit, tidy or improve a skill or SKILL.md, asks why a skill does not trigger or triggers too often, or asks whether a skill follows best practice. Do not use to run eval benchmarks or tune a description by measurement (that is skill-creator), to review plugin manifests, hooks or marketplaces, or to write CLAUDE.md or AGENTS.md (that is writing-for-agents).
---

# Writing skills

Claude already knows the SKILL.md format. This skill covers what it gets wrong by default: descriptions that never trigger, bodies that cost context every turn, Claude Code mechanics that fail silently, and skills nobody tested.

Pick the mode from the request. **Write** covers a new skill or a rewrite. **Review** covers an existing skill. Both end in the same findings table, and both judge against [checklist.md](references/checklist.md). Read the whole checklist before you write or judge anything.

For the prose itself (leading words, pointers, pruning no-ops), also read the `writing-for-agents` skill.

## Write a skill

1. **Find the gap.** A skill earns its place only by fixing something Claude gets wrong without it. Look for the evidence: corrections the user repeated, context they kept supplying, a task this session already worked through. If there is no evidence, ask the user for one real example of the failure. Without one, you are documenting imagined problems.
2. **Write three test prompts first**: two realistic requests that should trigger the skill and one near miss that should not. These are the acceptance criteria for every later step.
3. **Choose the shape.** Decide invocation control, degree of freedom, and what goes in SKILL.md against what goes in reference files or scripts. The checklist sections "Invocation control" and "Body: instructions" give the defaults.
4. **Draft the minimum** that closes the gap. Write the body first and the description last, so the description names what the body actually does. Put the skill where the target repo's CLAUDE.md says skills live. If it says nothing, ask: personal (`~/.claude/skills/`), project (`.claude/skills/`) or a plugin's `skills/`.
5. **Review your own draft** with review steps 2 to 4. Fix every Broken and Costly finding before you show the user anything.
6. **Test it.** Give a fresh subagent the SKILL.md path and each test prompt to check the output. For the no-skill baseline and for trigger tests, use `claude plugin eval` (plugin skill) or a fresh session with the skill set to `"off"` in `skillOverrides`. A subagent in this session still sees the skill listing, so it cannot give a clean baseline. Say which tests you ran and which the user must run.
7. **Report** with the table below. List any finding you chose not to fix, and the trigger tests still to run.

## Review a skill

1. **Identify the target.** If the user gave no path, use the current directory, and ask only if it holds no skill.

   | What is there | Review |
   | :- | :- |
   | `<dir>/SKILL.md` | That skill |
   | A `skills/` folder | Each skill in it, plus collection-level checks: name consistency, overlapping descriptions, total listing cost |
   | A plugin (`.claude-plugin/plugin.json`) | Each skill under `skills/` and each file under `commands/`. Say that manifest, hooks and marketplace config are out of scope |
   | An installed skill, such as `foo@bar` | The cached copy under `~/.claude/plugins/cache/`. Say that fixes belong upstream, because the cache is overwritten on update |

   Read every file in the target before judging it: SKILL.md, reference files and scripts. A finding that a reference file would have answered is noise.

2. **Run the validator** before reading for judgement, so the review does not repeat what a tool reports:

   ```bash
   claude plugin validate --strict --json <path>
   ```

   - Pass a directory named `skills/`. On any other directory, including the skill's own, the validator fails with `No manifest found`, which is not a defect. For a skill elsewhere, copy it into `$(mktemp -d)/skills/` and validate the copy.
   - It lists only files with problems, so an empty `contents` array is a clean pass.
   - The validator misses some YAML errors (an unclosed `[` passes) and every unknown or misspelt frontmatter key. Check both against the checklist.
   - It does not follow symlinks. Resolve each with `realpath` and validate the real path.
   - Treat a warning as something to judge, not to fix automatically.

3. **Judge against the checklist.** Report only items that apply. A checklist item that does not apply is not a finding.

   The checklist covers how the skill is written. Also check what it does. Trace each script and command against the environment it will run in, and look for behaviour the author would not want: a deploy that targets whatever context is current, a step that bypasses the normal release path, a script that disagrees with the instructions that call it. These are often the most valuable findings.

4. **Check the live docs when the checklist runs out**, for example on a frontmatter key, substitution or behaviour it does not list. An unknown key and a new feature look the same until you check.

   ```bash
   curl -sL https://code.claude.com/docs/en/skills.md
   curl -sL https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices.md
   ```

   Run `claude --version` when a finding depends on a version gate.

5. **Report** with the table below.

6. **Offer to apply.** Ask which rows to apply, for example "all Broken and Costly" or by number. Edit nothing until the user answers. After editing, run the validator again and say which rows you applied and which you skipped. A rewritten description is a hypothesis: recommend measuring it with skill-creator's description optimiser, or a `claude plugin eval` case with a `tool_used: Skill` grader for a plugin skill.

## Severity

- **Broken**: it does not load, does not trigger, or does something its author did not intend. Example: a misspelt frontmatter key, which Claude Code ignores silently.
- **Costly**: it spends context or usage every session for little return. Example: a long description on a skill that only fires by hand.
- **Weak**: it works, but triggers unreliably or gives unclear instructions. Example: a menu of options with no default.
- **Polish**: style and consistency. Report these only when there are few higher findings, and group them into one row.

## Report

Use this structure. Leave out a section if it would be empty.

```markdown
# Skill review: <name>

<One or two sentences: overall state and the single most important change.>

**Validator:** <pass or fail; each error or warning with a verdict: fix, ignore (why) or judge>

| # | Severity | Location | Issue | Fix |
| - | :- | :- | :- | :- |
| 1 | Broken | `SKILL.md:4` | `disable_model_invocation` uses underscores, so Claude Code ignores it and the deploy skill can fire on its own | Rename the key to `disable-model-invocation` |
| 2 | Weak | `SKILL.md:3` | Description says what the skill does but not when to use it | Rewrite, see fix 2 below |

## Fix details

### 2. <title>
<Only for a fix too long for a table cell: a rewritten description, a diff, a restructure.>

## Not checked
<Anything you could not verify, such as triggering that needs a fresh session.>
```

- Every row has a location and a concrete fix. "Improve the description" is not a fix; the rewritten description is.
- Sort by severity, then by impact within each severity.
- Merge repeated instances into one row that lists every location.
- When a fix is a judgement call, such as splitting a skill or changing who can invoke it, give the trade-off in one clause in the Fix cell.
- No rows for things that passed, and no praise.

## Where the guidance conflicts

The sources disagree on some points. Take these positions, and say so if the user asks.

- **Explaining why against stating what.** The Claude Code docs say to state what to do, because the body is a recurring cost. The authoring guide says to explain reasoning in place of rigid MUSTs. Give a reason only for a rule the model would otherwise break or apply too literally. Cut reasons that justify the obvious.
- **Gerund names.** The guide prefers names like `processing-pdfs` but accepts noun phrases. Flag a name only if it is vague, breaks the character rules, or does not match the rest of the collection.
- **Pushy descriptions.** A description that pushes hard to trigger helps a skill that undertriggers and hurts one that already triggers too often. Base the advice on the symptom the user reports, not on a rule of thumb.
