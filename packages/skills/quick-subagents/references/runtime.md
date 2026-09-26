# Pi worker runtime

Launch Pi through `pibx`, supplied by these dotfiles (`modules/dev.nix` and
`modules/dev-sandbox.nix`). Each invocation is an independent worker; it does
not inherit Codex's conversation. Use the shell execution tool to manage it,
not Codex's built-in subagent tools.

## Prepare the runtime

Choose the working directory deliberately: the sandbox mounts the current
directory and discovers the nearest ancestor `flake.nix`. Inspect applicable
project instructions and sandbox configuration before relying on its access
boundaries. Do not run from the home directory merely to make more files visible.
For sibling repositories, establish which roots the chosen sandbox actually
mounts before assigning cross-repository work. Name unavailable dependencies in
the brief. A failed lookup inside that sandbox says nothing about host absence;
report it once. Run dependent checks from a supported, authorized environment
instead of asking a worker to hunt for a path it cannot see.

Check `command -v pibx` and consult `pi --help` for locally supported flags.
If `pibx` is unavailable or the sandbox cannot start, report the prerequisite
or error; do not silently retry with unsandboxed `pi`.

## Launch

Use a fresh, non-interactive, ephemeral session. Pass a quoted prompt as a
single argument after `--`; do not interpolate task text into shell code.
For example, run this with the execution tool's working directory set to the
project root:

```sh
task_prompt=$(cat <<'PROMPT'
Locate src/parser error-handling paths and existing malformed-input tests.
Stop once you can cite the entry point and one relevant test command.
Search src and tests only; exclude transcripts, generated output, and caches.
Do not edit files, run commands, or delegate. Read applicable AGENTS.md.
Return DONE, BLOCKED, or PARTIAL, then an evidence map with file paths and
line numbers, missing coverage, and uncertainty, in at most 300 words.
Do not claim a bug without supporting evidence. Report blockers and finish.
PROMPT
)
pibx --offline --print --mode text --no-session \
  --provider openrouter --model deepseek/deepseek-v4.1-flash \
  --no-extensions --no-skills --no-prompt-templates \
  --tools read,grep,find,ls -- "$task_prompt" </dev/null
```

For implementation or checks requiring a shell, replace the tool allowlist
with `--tools read,bash,edit,write,grep,find,ls` and specify the owned files and
allowed commands in the assignment. Tool restrictions reduce capabilities;
the sandbox supplies the filesystem boundary. `--offline` disables startup
network operations, not model API calls or network access from tools.
Discovery flags keep unrelated extensions, skills, and prompt templates out
of the worker. Project context instructions remain enabled, subject to Pi's
local trust settings; include essential instructions in the task explicitly.
The stdin redirect prevents print mode from waiting for piped input when the
complete assignment is already in the prompt argument.

Select the worker explicitly: this installation lists provider `openrouter`
and model ID `deepseek/deepseek-v4.1-flash`. Verify availability with
`pi --offline --list-models deepseek-v4.1-flash` when the environment changes.
Do not silently substitute a model or use Pi's default. If unavailable, report
the missing model/provider configuration. Leave thinking at its configured
default unless the assignment warrants a supported override. Supported choices
include `--thinking low` and `--thinking off`; consider `off` for a mechanical
edit with settled interfaces. This does not remove the need to check its result.
`low` is not a hard reasoning-token budget. Split a large assignment before
trying to cure repeated planning with a timeout.
Allow enough wall time for code generation and checks. A long tool call does not
write its partial arguments to disk before the call completes. Use existing Pi
authentication; never print credentials or put API keys in command arguments.

For a long prompt, create a prompt file inside the mounted working directory
and pass `@relative/path/to/prompt.md` after `--`. A host `/tmp` file is not
necessarily visible inside the sandbox. Remove only temporary files created
for this run after collecting the result.

## Capture evidence without rereading transcripts

Text mode is enough for a small assignment. For evaluation, long runs, or failure
diagnosis, select `--mode json` and redirect stdout and stderr to a fresh host
directory outside the worker's search roots. Shell redirection occurs outside
the sandbox, so host `/tmp` is suitable for these logs, unlike worker prompt
files. Save the actual process status alongside them. For example, after setting
`task_prompt` as above, adapt the timeout and tools to the assignment:

```sh
task_logs=$(mktemp -d /tmp/pi-worker.XXXXXX)
if timeout --signal=TERM --kill-after=10s 600s \
  pibx --offline --print --mode json --no-session \
  --provider openrouter --model deepseek/deepseek-v4.1-flash \
  --no-extensions --no-skills --no-prompt-templates \
  --tools read,grep,find,ls -- "$task_prompt" </dev/null \
  >"$task_logs/events.jsonl" 2>"$task_logs/stderr.log"
then task_status=0
else task_status=$?
fi
printf '%s\n' "$task_status" >"$task_logs/exit-code"
```

Use [scripts/pi_report.py](../scripts/pi_report.py) from the host:
`python3 <skill-directory>/scripts/pi_report.py <events.jsonl> --exit-code <N>`.
It extracts bounded final text, tool-error counts, terminal events, and reported
usage. Multiple log paths are supported without `--exit-code`; their process
statuses then remain unknown. Inspect stderr or a specific failed tool event
only when the compact report leaves a question unanswered. Do not feed the raw
stream back to a worker as project context.

Only assistant `message_end` events count toward usage; `agent_end` repeats
messages. Interrupted generation may have no completed usage event, so recorded
totals can be incomplete even when every line parses. Cache reads are cumulative
reported usage, not unique context. Process exit, model stop reason, final text,
and task acceptance are separate facts. An exit-zero provider error or a timeout
with partial edits must not be reported as a completed task. Tool errors may have
been repaired; inspect the decisive evidence before accepting or rejecting work.

## Sandbox scope

`pibx` invokes `agent-sandbox --mount-pi` with the packaged Pi executable.
The default sandbox enables networking, mounts the current directory, uses a
persistent sandbox home, and mounts the host `~/.pi` read-write for Pi state
and authentication. It can also forward configured provider environment
variables. Workers therefore have access to Pi credentials and can change
mounted project files and Pi state; this is not a disposable or secret-free
environment. `--no-session` prevents saving a conversation, not other writes.

A project's exported sandbox configuration can replace the default
permissions, and its default development shell can supply dependencies.
Respect that configuration. Missing dependencies or denied access are reasons
to diagnose the sandbox, not to bypass it or broaden mounts automatically.
