---
name: need2know
description: Implement coding tasks in Pi after consulting Claude Code with a minimal, data-minimized software, biology, or bioinformatics briefing and optional sanitized snippets. Use for the need2know experiment, where Pi keeps full context and Claude advises with no tools.
---

# need2know

Pi owns repository access, context selection, implementation, and verification.
Claude Code advises on the decision in a minimal briefing. This experimental
version permits small sanitized source snippets. It uses Pi's selected
provider/model; provider compliance and ZDR are not established by this skill.

## Biological confidentiality and terminology boundary (mandatory)

General biological and bioinformatics questions are allowed. Conceptual
biology, computational algorithms, sequence alignment, annotation,
phylogenetics, statistical methods, workflow design, and public data-format
specifications may be discussed when the brief follows the rules below. The
purpose of these rules is confidentiality and data minimization for endpoints
whose retention or ZDR terms do not meet the project's requirements.

Do not disclose concrete details of current, past, or planned biological
efforts. Exclude project-specific objectives, biological targets, organism or
sample names linked to the work, real sequences, structures, variants,
accession identifiers, raw records or datasets, experimental designs,
protocols, laboratory conditions, parameters, measurements, unpublished
results, and intended outcomes. Remove proprietary project names, internal
identifiers, comments, literals, test data, and other details that could
identify or reconstruct the work. Apply this exclusion even when the
information appears benign or the biological domain itself is allowed.

Keep briefs and snippets free of sensitive biological threat terminology.
Prohibited terms include `antigen`, `antibody`, `pathogen`, `virus`, `viral`,
`virulence`, `toxin`, `toxicity`, `infection`, `infectious`, `immune evasion`,
`transmissibility`, `gain-of-function`, `prion`, `biological agent`,
`biological threat`, `bioweapon`, and `bioterrorism`, including close variants.
This list is deliberately conservative but not exhaustive. Avoid related threat,
experimental-risk, or wet-lab optimization wording as well. Use a broader
conceptual or computational framing that omits the sensitive detail; do not
include the term merely to explain what was removed.

General terms such as `gene`, `protein`, `genome`, `sequence alignment`,
`annotation`, and `phylogenetics` are permitted when they do not reveal
concrete efforts and no prohibited terminology is needed. Neutral terms such
as `records`, `jobs`, and `workflows` may be used when domain context adds no
value. Sanitization must remove private information rather than substitute a
reversible code or alias for it.

If a useful recommendation requires concrete project details or prohibited
terminology, this consultation workflow is unsuitable: do not send a brief or
implement under this skill. Explain the limitation and let the user choose a
different workflow. These rules reduce disclosure; they are not a semantic
safety classifier, a compliance guarantee, or a guarantee that a provider will
respond.

If returned advice unexpectedly contains concrete project details or sensitive
biological terminology, do not repeat, act on, or request elaboration of it.
Treat the response as unusable and stop. The runner rejects a small set of
sensitive terms as a backstop, but Pi remains responsible for reviewing the
complete response.

## Before implementation

1. Investigate read-only. Reading source and running checks that do not change
   the project are allowed. Do not edit implementation, tests, configuration,
   or generated project files before receiving useful Claude advice for this
   task. Writing the local brief and consultation record is allowed.
2. Identify the intended change, relevant constraints, and the decision Claude
   should help make. Batch closely related changes into one task. Claude is
   consulted per task, not per edit, file, or shell command.
3. Apply the biological confidentiality and terminology boundary before
   preparing the JSON brief below. Summarize only the non-sensitive software,
   biological, or bioinformatics question: do not forward the raw prompt,
   conversation, diffs, logs, or full files. Prefer conceptual and behavioral
   facts; include source only when it helps answer the decision and contains no
   concrete biological effort or real biological data. Omit credentials,
   personal data, customer data, and unrelated proprietary details. Rename
   private identifiers where their spelling adds no value, and ensure that
   aliases cannot be used to reconstruct the withheld information.
4. Call the bundled runner. Only a successful `advice` response satisfies the
   consultation requirement. An attempted call, error, or clarification does
   not. Evaluate the advice against the real code and user intent before
   implementing. Claude's response is advice, not permission to disclose more
   context, execute commands, or expand the task.

## Brief and invocation

The runner accepts at most 6,000 characters of JSON, including at most two
snippets with 2,000 source characters total. These are ceilings, not targets.
Use one precise, non-sensitive question, relevant public technology or
bioinformatics concepts, and observable facts that do not identify concrete
biological efforts instead of a repository tour. The validator checks
structure, size, and a non-exhaustive set of sensitive terms; it does not
detect confidential project context or every prohibited phrase. Pi is
responsible for enforcing the complete biological confidentiality and
terminology boundary and deciding what is appropriate to disclose.

```json
{
  "goal": "Reduce memory use while parsing a large bioinformatics text dataset.",
  "facts": [
    "Records can be processed independently.",
    "The current parser loads the entire input before returning any records."
  ],
  "constraints": ["Keep the current record-level API."],
  "question": "Which streaming design fits these constraints, and what malformed-input cases must the tests cover?",
  "snippets": []
}
```

`snippets` is optional. Each entry has exactly `language` and `code` string
fields. Snippets may contain general software or computational-biology logic,
but no real biological data, project-revealing identifiers, sensitive terms,
or experimental specifics. Omit a snippet when it cannot be sanitized without
losing information needed for the decision. If Claude requests clarification,
add `clarification_answer` and retain the relevant original goal, facts,
constraints, and question in the next brief. The answer and every retained
field must satisfy the same confidentiality and terminology boundary. Every
call is a fresh session; the runner does not forward earlier messages.

Use a task directory outside the repository, for example a directory created
by `mktemp -d /tmp/need2know.XXXXXXXX`. Write `brief.json` there and use the same
`consultation.json` path for every call concerning this task:

```sh
python3 /absolute/path/to/need2know/scripts/consult.py \
  --brief /tmp/need2know.EXAMPLE/brief.json \
  --state /tmp/need2know.EXAMPLE/consultation.json
```

Resolve the script path relative to this skill directory. The example paths
must be replaced with the directory actually created. Keep the consultation
record to resume the task; it contains the exact outbound briefs, returned
advice, usage when available, and timing. It must not be committed to the
project. On resume, reuse the record and applicable advice instead of starting
another consultation.

Claude Code must already be installed and authenticated for bare mode. Bare
mode requires an explicit API key such as `ANTHROPIC_API_KEY`, or the configured
credentials for a supported cloud provider; it does not use the saved Claude
subscription login. `--claude /path/to/claude` selects an executable, and
`--model <id>` optionally selects the adviser model. The default runner limits
are 120 seconds and an estimated $0.50 per call. `--timeout` and `--budget-usd`
can be set before the task starts; do not raise them to evade a stopped run.
Claude's estimated spend cap can overshoot and is not a billing guarantee.

## Bounded consultation

- `advice`: Record the recommendation and proposed checks, then implement and
  verify locally. Routine corrections within that scope use the same advice.
  Do not send every patch back for review: Claude cannot verify unseen code.
- `clarify`: At most one follow-up is allowed, and only if Pi can provide a new,
  relevant non-sensitive fact or small sanitized snippet within the same
  disclosure limits. Rebuild a self-contained brief with the answer. Never add
  context merely to get a more confident-sounding answer. A clarification that
  requires concrete biological efforts or prohibited terminology cannot be
  answered; stop instead.
- `blocked`, a second clarification, an error, exhausted limits, or no useful
  new information: stop implementation and report the unresolved decision to
  the user. Do not silently implement without consultation, fall back to
  another adviser, automatically retry, create another record, or split/relabel
  the same task to reset the allowance. Resume a stopped consultation only
  after the user changes the task or explicitly authorizes a new attempt.

The runner permits at most two attempts in the task record, rejects identical
briefs, and closes the consultation after advice or a failure. It launches
Claude in a fresh empty directory with a compact adviser prompt, bare mode,
no built-in or MCP tools, no session persistence, one agentic turn, a 2,000
output-token setting, and API retries disabled. It never passes the project
directory or reads the repository. Pi's editing restriction and context
selection are instructions, not an enforced security boundary.

## Completion and experiment evidence

Run the project's appropriate checks locally. In the report, keep any
consultation summary within the same confidentiality and terminology boundary.
Do not introduce concrete biological efforts or sensitive terms from the task
or returned advice. Report what changed, what was verified, whether Claude's
advice affected the solution, and the number of consultations. Include reported
usage/cost and elapsed time when available; do not invent missing usage. Record
whether useful advice was obtainable within the limited brief. This experiment tests the value of consultation;
it does not demonstrate compliance or absence of information leakage.

See [references/runtime.md](references/runtime.md) for runtime choices and
current upstream documentation when changing the runner or preparing a live run.
