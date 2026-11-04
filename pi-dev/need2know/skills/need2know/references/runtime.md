# Runtime choices

This is a behavioral experiment: Pi selects the outbound information and
agrees to consult before editing. General biological and bioinformatics
questions are allowed. Every brief, clarification, snippet, and consultation
summary must omit concrete biological efforts, real biological data, and
sensitive biological threat terminology as specified in `SKILL.md` and
`references/adviser.md`. The purpose is confidentiality and data minimization
for non-ZDR or otherwise unapproved endpoints, not a prohibition on biological
domains.

The Python runner controls its own Claude invocation and consultation record.
It also checks outbound briefs and parsed adviser responses against a small,
non-exhaustive set of sensitive biological terms. That literal check is only a
backstop: it cannot recognize confidential project context, real biological
data, related terminology, or every sensitive phrase. The runner is not a
sandbox, semantic redactor, or safety classifier, and Pi can technically bypass
it. JSON validation, character limits, renamed identifiers, and fresh sessions
provide no assurance that a brief is appropriate. The host must enforce the
complete confidentiality boundary before every call and review the response.
If the decision requires excluded details, the consultation is unsuitable.
Provider safeguards continue to apply.

Claude is run outside the repository. `--bare` avoids automatic loading of
CLAUDE.md, memory, hooks, skills, plugins, and MCP servers. `--tools ""` removes
built-in tools; a strict empty MCP configuration removes MCP tools separately.
A replacement system prompt keeps the adviser role small. Each call receives
only that prompt and the current brief through standard input, with no history
or source attachments. Ordinary runtime metadata can still be sent by Claude
Code. There is no assertion that its network request consists solely of those
two strings.

The runner preserves the environment for CLI authentication/provider routing.
Use an ordinary credential/configuration environment without embedded private
project context. Bare mode skips saved subscription credentials and keychain
lookups: supply an API key or supported cloud credentials. Do not remove bare
mode to fix authentication, because normal print-mode startup can load local
context and run hooks. Unsupported flags, missing credentials, and malformed
responses stop the task instead of triggering automatic repair calls.

The two-call record limit and timeout bound exchanges, not total workflow
tokens. Brief characters are not token counts, and Claude's maximum output
setting and estimated spend cap depend on its runtime and selected model.
The record preserves usage and estimated cost when the CLI reports them so
actual overhead can be measured. A stopped task may have no useful result.

For the initial experiment, Pi uses its current model and may disclose short
sanitized snippets containing general software or computational-biology logic
without real biological data or project-revealing details. No compliant
server, approved model endpoint, ZDR agreement, or production isolation is
configured by installing this package. For a later
private deployment, every code-visible model path, provider, relay, log, and
local artifact must match the intended data-handling requirements. ZDR concerns
retention; it does not mean the inference provider does not process the code.

Current upstream references (checked 2026-11-04):

- [Pi skills and explicit invocation](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/skills.md).
- [Claude Code bare mode and authentication](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode).
- [Claude CLI flags, tools, MCP configuration, turns and estimated spend](https://code.claude.com/docs/en/cli-reference).
- [Output-token and retry environment settings](https://code.claude.com/docs/en/env-vars).
- [Claude Code ZDR scope](https://code.claude.com/docs/en/zero-data-retention).
