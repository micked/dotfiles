# Research and evaluation

Reviewed 2026-09-20. These sources motivate the workflow; they do not establish
that this particular DeepSeek setup saves tokens or matches director quality.

- [Anthropic: How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
  describes clear assignment boundaries, effort scaled to task complexity,
  artifact handoffs, and outcome-based evaluation. It also reports substantial
  total token overhead and difficulty with tightly coupled coding work. Here,
  prefer one useful worker initially, bounded assignments, and explicit checks.
- [Anthropic: Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
  describes isolated worker contexts with condensed results and retrieving
  details through references. Here, workers absorb exploration while the
  director receives compact evidence and reads selected source slices.
- [Pi's upstream documentation](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/README.md)
  documents print mode, ephemeral sessions, explicit model selection, and tool
  selection. For this installation, `pi --help`, the local model catalog, and
  `modules/dev.nix` / `modules/dev-sandbox.nix` determine the actual launch and
  mount behavior. The configured model was verified as
  `openrouter` / `deepseek/deepseek-v4.1-flash`.

Mandatory session-long delegation is the user's operating preference, not a
research finding that delegation is always cheaper. The 300-word return budget
and bounded repairs are local defaults intended to limit coordination overhead.

To evaluate revisions, compare representative discovery, small-edit, and
multi-file tasks with and without the skill. Measure director input/output
tokens separately from worker tokens, elapsed time, repair rounds, and task
correctness under the same acceptance criteria. Include startup instructions
and review costs. Check observable behavior: a useful worker starts before
deep exploration, routine work stays delegated, the director avoids duplicate
work, and completion is supported by evidence. Report unavailable usage data
as unavailable; a successful worker smoke test alone proves no savings.
