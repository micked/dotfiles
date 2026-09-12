# pi-bigtdd

`/bigtdd` is a branch-per-task, commit-per-stage workflow for large coding requests. A strong parent model controls a deterministic state machine while fresh specialist Pi processes perform reconnaissance, test authoring, independent reviews, implementation, and refinement.

## What it guarantees

- Refuses to start from a dirty worktree or detached HEAD.
- Creates `bigtdd/<request>-<timestamp>` from the current branch.
- Writes auditable evidence under `.bigtdd/<run-id>/` and commits every completed stage.
- Runs test and implementation agents in fresh, sessionless Pi processes.
- Uses different configured model families for authors and reviewers.
- Establishes RED before implementation and locks the reviewed test contents.
- Blocks the parent orchestrator and implementation agents from editing locked tests.
- Requires a passing full verification command before `done`.
- Keeps the branch and all stage commits if the workflow is aborted.

The extension does not push, merge, rebase, squash, delete a branch, or modify another worktree.

Stage artifacts can contain source excerpts and test-command output. Review them before pushing the workflow branch, just as you would review the code diff.

## Usage

```text
/bigtdd Add per-user API rate limiting with a configurable burst allowance
/bigtdd status
/bigtdd resume
/bigtdd abort
```

The happy path is:

```text
intake → recon → contract → tests → test review → RED
       → implementation → feature review → full verification → done
```

Failed reviews create fresh `test_refinement` or `feature_refinement` stages. Recon and read-only review stages can be rerun with a refined focus before the parent accepts them.

Each stage updates `state.json`, records the agent/gate evidence in Markdown, and creates one Git commit. Read-only stages therefore remain recoverable and inspectable without empty commits.

## Human checkpoints

The parent is instructed to lean toward `bigtdd({ action: "checkpoint", ... })` when:

- requirements permit materially different behavior;
- a test encodes a product or compatibility decision;
- author and reviewer evidence disagree;
- a review finding expands scope;
- a failure may be environmental rather than behavioral;
- accepting a shortcut would be costly to reverse.

The human may approve the recommendation, provide free-form feedback, or pause. Set `humanCheckpoints` to `always-contract` to require explicit contract approval on every run.

## Test escape hatch

After RED, test files are content-hashed. Implementers and feature refiners cannot edit them. If a test later proves impossible for a trivial reason, the parent can request `unlock_tests` with an exact reason and evidence.

Interactive runs require human confirmation by default. Approved reopening creates its own commit, then forces a fresh:

```text
test refinement → independent test review → RED
```

When implementation already exists, the RED gate constructs a temporary worktree at the original base commit and applies only the committed test diff. This avoids treating a test that passes against the new implementation as proof that RED once existed. Some repositories require dependencies or generated files that are unavailable in a fresh worktree; in that case the parent must ask the human before recording a RED waiver.

For unattended use, `requireHumanForTestUnlock: false` permits an independent reviewer to approve an unlock when it supplies evidence. Main-agent-only approval additionally requires `allowMainAgentTestUnlockWithoutUI: true`; it is deliberately disabled by default.

## Configuration

Defaults live in [`config.json`](config.json). Override them globally in `~/.pi/agent/bigtdd.json` or per repository in `.pi/bigtdd.json`; repository values win.

```json
{
  "humanCheckpoints": "always-contract",
  "models": {
    "orchestrator": "provider/strongest-model",
    "scout": "provider/fast-model",
    "testAuthor": "provider/strong-model",
    "testReviewer": "other-provider/strong-model",
    "implementer": "provider/cheaper-coding-model",
    "featureReviewer": "other-provider/strong-model"
  }
}
```

The checked-in defaults match the models currently enabled in these dotfiles. Missing models fail visibly at the relevant child stage; the extension never silently substitutes a reviewer model.

## Installation

This dotfile repository exposes the package at `~/.pi/agent/local/pi-bigtdd` and adds that stable local path to Pi's `packages` setting through Home Manager. Outside these dotfiles:

```sh
pi install /absolute/path/to/pi-dev/bigtdd
```

Run the local tests with:

```sh
npm test --prefix pi-dev/bigtdd
```
