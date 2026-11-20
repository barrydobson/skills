---
name: investigate
description: Works one ticket that is not ready for an agent through its open questions with the human, then posts an agent brief and moves it to ready-for-agent, or splits, parks or closes it.
disable-model-invocation: true
argument-hint: "[ticket-key]"
---

# investigate

Resolve every open question on one ticket, with the human, in its own repo. The rules for when a ticket is ready-for-agent, needs-info or ready-for-human are in `${CLAUDE_PLUGIN_ROOT}/shared/ready-for-agent.md`; read them first. This is a conversation: recommend, but the human decides. Change no code: read code, and write only to the tracker.

Use whichever issue tracker skill or CLI this session has loaded, to read, comment on, publish and link tickets and to move a ticket to a triage role. If there is none, stop and say so.

## Steps

1. **Ticket.** Take the key from `$ARGUMENTS`, or from the single issue link in `orca reference list --worktree current --json` when running in an Orca workspace. With neither, ask.
2. **Gather context.** Read the ticket, every comment and linked blockers. Earlier notes, such as a list of reasons it is not ready or `## Triage Notes`, say what was open last time: start from them and don't re-ask what later comments settled. Read the code the ticket touches, and check every premise it states.
3. **List what is open.** Check the ticket against the rules. Show the human each reason it is not ready-for-agent, each with your recommendation first, before asking anything.
4. **Resolve, one question at a time.** Use the grilling skill if it is available. When the code settles a question, say so rather than ask. Record each answer as `Ruling: <what> - <why>`.
5. **Outcome.** Confirm it with the human, then apply it:
   - **ready-for-agent:** post an `## Agent Brief` comment (below) and move the ticket to ready-for-agent.
   - **Split:** when part of the work belongs in another repo, or the ticket is too large, draft the new tickets with the human, each in one repo. Publish them, each ready-for-agent with its own brief where the rules allow, and link which blocks which. Then apply an outcome to this ticket too.
   - **ready-for-human:** settled, but it needs a live write. Post the brief, say which step a human must do, and move the ticket to ready-for-human.
   - **needs-info:** a question only someone outside this conversation can answer. Post `## Triage Notes` with what is established and each question left, for a named role, and move the ticket to needs-info.
   - **wontfix:** comment why, and move the ticket to wontfix.

## Agent Brief

The brief outranks the description for whoever picks the ticket up, so write it to stand alone:

- **Goal:** the problem in one or two plain sentences, then the change in one.
- **Acceptance criteria:** each one checkable by a command or by observable behaviour.
- **Rulings:** every decision from step 4, as `Ruling: <what> - <why>`.
- **Out of scope:** related work the ticket does not ask for, and any split-off ticket by key.
