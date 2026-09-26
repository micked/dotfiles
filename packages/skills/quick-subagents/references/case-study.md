# Field study: reading the Lighthouse timestamp

Run on 2026-09-20. User priority: a result that can be trusted, then token
efficiency. Task: implement local beats 6 onward in `23_LFSR_impl`, starting at
production commit `c8acc6b6aeb5ca95841e2f44b558b03390041949`. Skill baseline:
dotfiles commit `c10f049` (`SKILL.md`: 1,113 words, 7,718 bytes).

This is one evolving field trial, not a controlled A/B comparison. The baseline
and revised workflow handled different assignments. Director usage is not
available; no total-token, cost, or quality-parity savings are established.

## Observations that changed the instructions

| Observation | Decision |
| --- | --- |
| A production-only worker could not see the sibling framework. It searched repeatedly and concluded the checkout needed restoring, although the director could see it on the host. | Brief actual visible roots; scope negative findings to the inspected environment; report unavailable dependencies once. |
| Discovery read its own growing JSON transcript. The run used 52 tool calls and reported 1,793,308 cumulative tokens, including 1,692,672 cache-read tokens. | Exclude transcripts and build artifacts from discovery; extract compact reports outside the model context. These are cumulative usage fields, not unique context. |
| An open-ended audit timed out at 240 seconds with no final report. An instruction rewrite timed out at 300 seconds while streaming its first write arguments; the file had not changed. | Give discovery a stopping question; request tangible increments and allow realistic generation time. A short final-report budget does not bound investigation. |
| The broad lesson implementation produced no source edits before its director became unavailable. | Settle interfaces and split execution into independently owned model, timing/review, and drawing modules. Preserve artifacts and ownership in addition to process session IDs. |
| A report helper passed all six worker-written tests, yet marked a real timeout's usage complete and treated a tool request as final output. | Independently inspect critical semantics. Three counterexample tests now cover interrupted turns, timeouts, and complete JSON without a newline. |
| A timing worker returned incorrect beat mappings and leading phase offsets; a drawing repair still used the wrong row-flight phase and inverse-swap direction. | Define shared timing contracts once, then test their use in the consumer. A repaired report needs fresh acceptance. |
| Low-thinking implementation calls exhausted ten-minute limits without edits. Thinking-off calls produced edits but still required semantic repairs. | Treat thinking settings as execution choices, not quality guarantees or token caps; settle hard decisions before delegating mechanical work. |
| Documentation claimed both search heads reached landmarks and that the review harness read narration. Neither matched the implementation. | Verify documentation against behavior; successful prose generation is not factual validation. |
| An existing review directory contained screenshots from earlier source with a different stage count. | Use fresh output and associate evidence with current files; generating an image is distinct from inspecting it. |

The director independently enumerated all 131,071 states of P2 and searched for
the globally nearest matching-prefix landmarks. The script's recovered state at
52,640, forward distance 607, backward distance 1,441, and all eight adjusted
records agreed. That establishes the numerical reference, not visual acceptance.

## Reproducing the instruction checks

Run the skill-creator structural validator against this directory. It requires
PyYAML. Run the report helper's focused tests with:

```sh
python3 -m unittest discover -s scripts -p 'test_*.py' -v
```

The helper also runs on the actual study logs, including timeouts; usage from
unfinished generation remains unavailable. Keep the final report, process exit,
provider stop reason, captured check output, and director acceptance separate.
Local raw evidence is under `/tmp/quick-subagents-study`; it is temporary and is
not a runtime dependency of the skill.

## Delivered result and acceptance evidence

The chapter now has 26 presses, preserving its first 13 and implementing local
beats 6–9 plus the closing handoff. The new sequence separates the recovered
pattern, searches toward stored landmarks, reveals position 52,640, constructs
eight table rows, extracts six-bit hashes, adjusts the records, and demonstrates
that complete records can be shuffled and restored. Geometry and displayed
numbers use the same cached numerical model.

Director review corrected a cycle-boundary subtraction error, phase-index
mismatches, the feedback bit in the visible shift, inverse shuffle motion, and
visual collisions. The numerical boundary regression checks a state at position
131,070: the forward search must not invent a one-step wrapped result. Drawing
tests check whole-record separation through all eight swaps, restoration, and
coherent updates of the adjusted state, hash, position, and landmark tick.

Final source passed formatting, strict Clippy, all 201 workspace tests, and the
release review-example build. A fresh real-time harness run exited zero and
produced 119 frames with source hashes. The director inspected samples from
every new stage, including moving states and corrected collision sites, alongside
the written narration. This was **not a continuous narrated playback review**:
no recorded narration was supplied, and sampled frames cannot establish every
intermediate frame or the performed avatar's readability. The preview uses the
existing central avatar pose, which overlaps the overlay; performance staging
still needs review with the intended take.

The instruction package's report helper has nine passing focused tests. The
main instructions are shorter, but brevity is not the measured success criterion.
This trial supports the specific safeguards above; it does not demonstrate an
end-to-end token saving. Several interrupted generations have no reported usage,
and director usage is unavailable. Cache-read totals must not be described as
unique tokens or compared as though these assignments were equivalent.
