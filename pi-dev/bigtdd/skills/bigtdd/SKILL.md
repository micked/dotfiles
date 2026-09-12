---
name: bigtdd
description: Orchestrate large coding tasks with /bigtdd using fresh specialist agents, independent test and feature review, RED/GREEN gates, human checkpoints, and commit-per-stage branches.
---

# BigTDD orchestration

Use the `bigtdd` tool as the sole workflow controller after `/bigtdd <request>` starts a run. The extension owns branch creation, specialist dispatch, evidence artifacts, phase transitions, test locking, verification commands, and commits. Do not edit files, run the feature's Git operations, or bypass a phase from the parent session.

## Stage loop

1. Call `status` to recover the current state.
2. For `recon`, call `run_stage`. A second fresh scout may be run with a more targeted `focus` when the first brief exposes a real gap. Complete the stage only after synthesizing the evidence.
3. For `contract`, write an explicit Markdown contract containing acceptance criteria, constraints, non-goals, compatibility expectations, and observable completion evidence. Submit it through `complete_stage`.
4. For agent stages, call `run_stage`, inspect the structured report and actual changed files, then call `complete_stage` with an evidence-based summary and the correct decision.
5. At `red`, call `run_stage`, confirm the nonzero exit is caused by the missing requested behavior, then attest with `redFailureMatchesContract: true` when completing the stage.
6. At `verification`, call `run_stage`; completion is blocked unless the full command passes and locked tests are unchanged.

Never treat prose as proof when a command or repository check is available.

## Human checkpoints

Lean toward `checkpoint` whenever feedback could prevent meaningful rework. In particular, ask when:

- the request supports materially different product behaviors;
- the contract introduces or changes a public interface;
- a reviewer returns `needs_human` or two sources disagree;
- accepting a finding expands scope or changes compatibility;
- RED fails for infrastructure or setup rather than the intended missing behavior;
- tests may be wrong, overly strict, flaky, or impossible for a trivial reason;
- a destructive, security-sensitive, migration, or data-shape decision appears.

Do not ask about facts that another targeted scout can cheaply establish. When asking, state the evidence, concrete choices, and recommendation.

## Review decisions

- `advance`: evidence satisfies the current stage.
- `refine`: the independent reviewer found actionable problems. The extension launches a fresh refinement agent and sends the result back through review.
- A `needs_human` report must be resolved through `checkpoint` before advancing.

Reviewers are fresh and read-only. Do not reveal an author's private reasoning or ask a reviewer to rubber-stamp a result.

## Test lock and escape hatch

After a valid RED stage, test contents are hashed and become immutable for implementation agents. If tests later prove defective:

1. Finish or otherwise resolve the current mutating stage so the worktree is clean.
2. Call `unlock_tests` with the exact reason and approval evidence.
3. In an interactive session the extension asks the human by default. Without UI, independent-reviewer evidence is required unless configuration explicitly permits main-agent approval.
4. A fresh test refiner changes tests, a fresh alternative-model reviewer audits them, and RED is re-established before feature work resumes.

Never silently weaken a test to make GREEN easier.

## Completion

Do not claim completion until the extension reaches `done`. Summarize the resulting branch, the stage commits, verification command, and any approved waivers or unresolved notes.
