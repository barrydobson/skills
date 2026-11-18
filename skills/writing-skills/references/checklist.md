# Skill checklist

Apply this to each `SKILL.md`, and to command files under `commands/`, which take the same frontmatter except `name` and `paths`. Use it to judge a skill under review and to shape a new one.

## Contents

- Frontmatter: placement and keys
- Name
- Description
- Invocation control
- Tool grants and forked execution
- Body: size and structure
- Body: instructions
- Bundled scripts, paths and injected commands
- Trust and data
- Testing

## Frontmatter: placement and keys

- **The opening `---` must be the first line of the file.** Otherwise Claude Code treats the whole file as body text and no fields are set.
- **YAML must parse.** If it doesn't, the skill still loads with no fields set, so `/name` works and Claude can never match the description. `claude --debug` shows the parse error.
- **Every key must match a known field exactly.** Claude Code ignores an unknown key without an error, so a misspelt key is a silent bug. The known keys are:
  `name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`, `metadata`, `license`, `compatibility`.
  Common mistakes are `disable_model_invocation`, `allowed_tools` and `user_invocable` (underscores where the field uses hyphens) and `when-to-use` (hyphens where the field uses underscores). Check the `skills` docs page before reporting any other key, because it may be a new field.
- **Portability.** claude.ai uploads, the Skills API and `package_skill.py` accept only `name`, `description`, `license`, `compatibility`, `metadata` and `allowed-tools`, and reject any other key with a hard error. Flag Claude Code-only keys only if the author intends to ship the skill to those surfaces.
- **`metadata` must be a map** and must not reuse frontmatter field names as keys.

## Name

- Maximum 64 characters: lowercase letters, digits and hyphens only. Must not contain `anthropic` or `claude`.
- Claude Code refuses a `name` holding `<`, `>`, control or zero-width characters, or odd whitespace. The skill then goes missing from the `/` menu with only a startup notice. `claude --debug` logs the refusal under `[names]`.
- Not vague (`helper`, `utils`, `tools`) and not too generic (`documents`, `data`).
- Consistent with the other skills in the same collection. Gerund form (`processing-pdfs`) is the preferred pattern.
- In a plugin, `name` replaces only the last segment of `/<plugin>:<name>`. Don't add the plugin prefix yourself.
- A `SKILL.md` at a plugin root needs `name` set. Without it, the skill takes the plugin's directory name.

## Description

The description decides whether the skill is ever used. Spend the most effort here.

- **States what the skill does and when to use it.** The exception is a skill with `disable-model-invocation: true`, whose description Claude never sees. There a short human-facing label is enough.
- **Third person.** "Reviews pull requests…", not "I can help you…" or "Use this to…". The description is injected into the system prompt, and a mixed point of view harms discovery.
- **Front-loads the key use case.** The listing caps `description` plus `when_to_use` at 1,536 characters. When the whole listing exceeds its budget (1% of the context window), Claude Code drops whole descriptions, starting with the least-used skills. The spec caps `description` at 1,024 characters, so stay under that if the skill might ship outside Claude Code.
- **Uses the words a user would actually type**: file types, tool names, symptoms, casual phrasings, not just the formal name of the task.
- **Names its near misses** when a neighbouring skill exists: "Do not use for X (that is skill-y)". This stops two skills competing for one request.
- **Is not vague.** "Helps with documents" gives Claude nothing to match.
- **No angle brackets or XML tags.** Claude Code shows `<` and `>` as `&lt;` and `&gt;`, and claude.ai rejects them. Write placeholders as `[branch]`, or move them to `argument-hint`.
- **Undertrigger or overtrigger.** Ask which symptom the user sees, or read the description against the requests it should and shouldn't catch. Make an undertriggering description more specific and more insistent. Narrow an overtriggering one, or make the skill manual.

## Invocation control

| Situation | Recommend |
| :- | :- |
| Side effects such as deploy, commit, send a message or write to a ticket | `disable-model-invocation: true`. It also removes the description from context, prevents preloading into subagents and stops the skill firing from a scheduled task |
| Background knowledge that is meaningless as a `/command` | `user-invocable: false` |
| Only relevant when certain files are being worked on | `paths:` with globs. They match relative to the current working directory only, so files in a sibling worktree never activate the skill |
| A rule that must hold every time, such as "never edit X" or "always run Y after editing" | A hook, not prose: the skill's `hooks` frontmatter, or a plugin hook. A skill is guidance Claude can drift from; a hook always runs |
| A skill that only ever fires by hand | `disable-model-invocation: true`, so its description stops costing context every turn |

Flag a skill with side effects that Claude can invoke on its own as Broken: Claude may deploy because the code "looks ready".

In a collection, every model-invocable description is in context every turn. Check which skills Claude must genuinely choose on its own, and recommend making the rest manual. `/skill-doctor` lists skills that are never invoked.

## Tool grants and forked execution

- **`allowed-tools` pre-approves tools for the invoking turn only.** It doesn't restrict tools; `disallowed-tools` does. Flag broad grants such as `Bash` or `Bash(*)` on skills that live in a repository: workspace trust doesn't gate them, so anyone running Claude Code there gets the grant.
- **Match the grant to the command.** When the body runs a bundled script, write the same `${CLAUDE_SKILL_DIR}/scripts/x.sh *` path in the grant and the body, so the call runs without a prompt.
- **`context: fork` needs a task, not guidelines.** The subagent receives only the skill body, not the conversation. Check that the body stands on its own.
- **Forks run in the background by default.** They get the narrower background tool set, and their edits bypass checkpoints, so `/rewind` can't undo them. If the skill needs the full tool set or its result in the same turn, recommend `background: false`.
- **`agent: Explore` or `agent: Plan`** skips CLAUDE.md, so project conventions don't reach the fork.
- **`model` and `effort` overrides** need a reason. A model the organisation's allowlist excludes is silently not used.

## Body: size and structure

- **The body is a recurring cost.** Once invoked, it stays in context for the rest of the session. Cut anything Claude already knows, such as what a PDF or a REST API is. Test each paragraph: would Claude get this wrong without it?
- **Keep it under 500 lines.** Move detail into reference files that SKILL.md links to directly. Each link says what the file holds and when to read it.
- **Split reference files by branch or domain** (`reference/finance.md`, `reference/sales.md`), so a task loads only the file it needs. A large reference costs nothing until read, so complete docs and big datasets can ship with the skill.
- **Keep references one level deep from SKILL.md.** Claude often previews a file linked from another reference with `head` and misses the rest.
- **Reference files over 100 lines need a table of contents at the top**, so a partial read still shows the whole scope.
- **Put the most important instructions first.** After compaction, Claude Code re-attaches only the first 5,000 tokens of each invoked skill, within 25,000 tokens across all skills, most recent first.
- **Use descriptive file names**, such as `form-validation-rules.md`, not `doc2.md`.

## Body: instructions

- **Write standing instructions, not one-off steps.** Claude Code doesn't re-read the file on later turns, so "Run the tests after every edit" holds and "Run the tests" fades.
- **Match the degree of freedom to the risk.** Fragile, must-be-exact operations such as migrations get an exact command and "do not add flags". Tasks with one preferred pattern get a template or parameterised script. Judgement tasks such as reviews get heuristics.
- **Give one default, with an escape hatch.** "Use pdfplumber; for scanned PDFs use pytesseract", not a menu of five libraries.
- **Use one term per concept.** Not "field", "box" and "control" for the same thing.
- **No time-sensitive statements** such as "before August 2025, use…". Move legacy behaviour into a labelled "old patterns" section.
- **Show output with examples.** Where style matters, give input and output pairs. Give a template for the output format, and say whether it is strict ("use exactly this structure") or a default to adapt.
- **Number the steps of a multi-step workflow.** For a long one, give a checklist Claude copies into its response and ticks off.
- **Route decision points explicitly**: "Creating new content? Follow X. Editing? Follow Y." Move a large branch into its own file.
- **Add a feedback loop to quality-critical tasks**: validate, fix, repeat, continue only when validation passes. The validator can be a script or a reference document Claude checks against.
- **Plan, validate, execute** for batch, destructive or high-stakes work: Claude writes the plan to a file such as `changes.json`, a script validates it, and only then does anything change.
- **Give every step a clear completion criterion**, so Claude can tell done from not done.
- **Use all-caps MUST and NEVER rarely.** If a rule needs shouting, it may belong in a hook. If it stays as prose, one line of reason usually works better than capitals.

## Bundled scripts, paths and injected commands

- **Prefer a script for deterministic work.** A script is more reliable than generated code, and only its output costs tokens.
- **Say whether to run a script or read it.** "Run `x.py` to …" for execution; "See `x.py` for the algorithm" for reference. Document each script's input and output format.
- **Scripts handle their own errors** with specific, actionable messages ("Field `signature_date` not found. Available: …"), not a stack trace for Claude to decode.
- **No unexplained constants.** Every timeout and retry count carries a one-line reason.
- **Declare dependencies** by name, with the install command. The Claude API has no network access and can't install packages; claude.ai can.
- **Use `${CLAUDE_SKILL_DIR}` for files bundled with the skill**, and `${CLAUDE_PLUGIN_ROOT}` for files shared across a plugin. A bare relative path such as `scripts/x.py` resolves against the user's working directory.
- **Write those variables in the Markdown, where Claude Code substitutes them.** They are not in the Bash tool's environment, so `echo $CLAUDE_PLUGIN_ROOT` prints nothing.
- **Keep state out of the skill directory.** In a plugin, `${CLAUDE_PLUGIN_ROOT}` is replaced on every update; use `${CLAUDE_PLUGIN_DATA}`.
- **Injected `` !`cmd` `` commands abort the whole invocation on a non-zero exit**, and Claude never sees the skill. Append `|| true` to a command that can legitimately exit non-zero. They run in the session's current directory, so use `${CLAUDE_SKILL_DIR}` or `${CLAUDE_PROJECT_DIR}` in their paths.
- **Use forward slashes** in all paths.
- **Name MCP tools in full**: `Server:tool` in skill text, `mcp__<server>__<tool>` in hook matchers.
- **Mark Claude Code-only features.** `` !`cmd` `` injection and `$ARGUMENTS` substitution don't work on claude.ai or through the API.
- **Escape literal dollar amounts.** Write `\$1.00`, or `$1` expands to the second argument.

## Trust and data

Skills run as the user, with no sandbox. For a skill from outside the user's organisation, or one with scripts, list every shell command, network endpoint and broad `allowed-tools` grant, and anything that sends prompts, code, transcripts or files off the machine. Name the data that leaves and where it goes, and flag it for the user to decide. Don't treat it as acceptable by default: the user may work under regulatory or contractual data-handling rules.

## Testing

- **Evidence before instructions.** A skill should close a gap observed when Claude ran the task without it. Flag a skill whose content answers no observed failure.
- **At least three realistic prompts**, run with the skill and without it, in a fresh session. Leftover context from writing the skill masks gaps. Turn a personal or project skill off for the baseline with `"off"` in `skillOverrides`; for a plugin skill, use `claude plugin eval`, which runs a no-plugin baseline.
- **Trigger and output are separate checks.** A trigger proves Claude found the skill, not that the skill helped.
- **Check for an eval suite.** skill-creator uses `evals/evals.json` inside the skill. `claude plugin eval` uses `evals/` cases inside a plugin. The formats aren't interchangeable. A `tool_used: Skill` grader measures triggering but is excluded from the with-minus-without score, so a delta of zero on it alone means nothing.
- **Watch how Claude navigates the skill.** Files read in an unexpected order suggest the structure isn't obvious. A link Claude never follows is too weak or the file is unneeded. A file Claude reads every time belongs in SKILL.md.
- **Check model coverage.** On Haiku, check the instructions give enough guidance. On Opus, check they don't over-explain.
