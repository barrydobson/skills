# Ready for agent

A ticket is **ready-for-agent** when it is one reviewable PR in one repo, with nothing left to decide. Where the ticket, the code or the repo's conventions point to a sensible default, take it and record it as a ruling; that is not an open question.

Otherwise it is in one of two other states.

**needs-info**: someone has to answer or decide before anyone can build it. That is when:

- the ticket is ambiguous in a way that changes the result, and the code and tracker do not settle it;
- an acceptance criterion is missing or contradicts another, so no one can tell when the work is done;
- the valid options differ in something hard to undo: a public interface, a data schema or a new dependency;
- a premise does not hold: a file, function, resource or setting the ticket names is missing or not where it says;
- the work needs a change in another repo. One ticket changes one repo; this rule has no exceptions, however small the other change (code, docs, a runbook, config). Never plan a companion PR: name the other repo and the change, and recommend a new ticket for it, with which ticket blocks which;
- the work is too large for one reviewable PR. Recommend how to split it.

**ready-for-human**: it is settled, but an agent must not do it, because a criterion needs a live write: a deploy, a sync, an apply or a write to a shared system.
