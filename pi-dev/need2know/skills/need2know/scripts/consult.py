#!/usr/bin/env python3
"""Run one bounded Claude consultation with biological data minimization.

General biology and bioinformatics are allowed. The host must omit concrete
biological efforts and sensitive terminology. This standard-library-only
runner checks JSON structure, size, and a non-exhaustive literal term list;
it is not a semantic redactor.
"""

import argparse
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time


# A conservative, deliberately incomplete backstop for outbound briefs and
# parsed advice. It cannot detect concrete projects, real data, or related
# terminology. Avoid ambiguous software words such as "host" in this list.
SENSITIVE_BIO_PATTERN = re.compile(
    r"(?<![\w])(?:"
    r"antigen\w*|antibod\w*|pathogen\w*|virus\w*|viral\w*|virulence|"
    r"toxi\w*|infect\w*|immune(?:\s+|-)evasion|transmissib\w*|"
    r"gain(?:\s+|-)of(?:\s+|-)function|prion\w*|"
    r"biological(?:\s+|-)(?:agent\w*|threat\w*|weapon\w*)|"
    r"bio(?:\s+|-)?weapon\w*|bioterror\w*"
    r")(?![\w])",
    re.IGNORECASE,
)


def contains_sensitive_bio_term(value):
    serialized = json.dumps(value, ensure_ascii=False)
    return SENSITIVE_BIO_PATTERN.search(serialized) is not None


class ConsultationError(Exception):
    pass


def require(condition, message):
    if not condition:
        raise ConsultationError(message)


def nonempty(value):
    return isinstance(value, str) and bool(value.strip())


def validate_brief(brief):
    # Structural limits and literal terms are not semantic content screening.
    # The host and adviser prompts own the complete confidentiality boundary.
    required = {"goal", "facts", "constraints", "question"}
    optional = {"snippets", "clarification_answer"}
    require(isinstance(brief, dict), "Brief must be a JSON object.")
    require(required <= brief.keys() <= required | optional, "Unexpected or missing brief fields.")
    for field in ("goal", "question"):
        require(nonempty(brief[field]), f"{field} must be a nonempty string.")
    for field in ("facts", "constraints"):
        value = brief[field]
        require(isinstance(value, list) and len(value) <= 8 and all(map(nonempty, value)),
                f"{field} must contain at most eight nonempty strings.")
    if "clarification_answer" in brief:
        require(nonempty(brief["clarification_answer"]), "Clarification answer must be nonempty.")
    snippets = brief.get("snippets", [])
    require(isinstance(snippets, list) and len(snippets) <= 2, "At most two snippets are allowed.")
    for snippet in snippets:
        require(isinstance(snippet, dict) and snippet.keys() == {"language", "code"}
                and all(map(nonempty, snippet.values())), "Each snippet needs language and code strings.")
    require(sum(len(s["code"]) for s in snippets) <= 2000, "Source exceeds 2,000 characters.")
    encoded = json.dumps(brief, sort_keys=True, ensure_ascii=False)
    require(len(encoded) <= 6000, "Brief exceeds 6,000 characters.")
    require(not contains_sensitive_bio_term(brief),
            "Brief contains prohibited sensitive biological terminology; use a non-sensitive conceptual question or stop.")
    return encoded


def parse_advice(stdout):
    require(len(stdout) <= 100_000, "Claude returned excessive output.")
    envelope = json.loads(stdout)
    require(isinstance(envelope, dict) and envelope.get("type") == "result"
            and envelope.get("subtype") == "success" and not envelope.get("is_error"),
            "Claude did not return a successful result; inspect authentication and runtime limits.")
    advice = json.loads(envelope.get("result", ""))
    require(isinstance(advice, dict)
            and advice.keys() == {"status", "recommendation", "checks", "question"},
            "Invalid adviser response fields.")
    require(advice["status"] in ("advice", "clarify", "blocked"), "Invalid adviser status.")
    require(isinstance(advice["recommendation"], str) and isinstance(advice["question"], str),
            "Recommendation and question must be strings.")
    checks = advice["checks"]
    require(isinstance(checks, list) and len(checks) <= 5 and all(map(nonempty, checks)),
            "Invalid adviser checks.")
    if advice["status"] == "clarify":
        require(nonempty(advice["question"]) and not advice["recommendation"] and not checks,
                "Clarification must contain only a question.")
    else:
        require(nonempty(advice["recommendation"]) and not advice["question"],
                "Advice or blocking reason is missing, or includes a further question.")
        require(advice["status"] != "blocked" or not checks, "Blocked response cannot contain checks.")
    require(len(json.dumps(advice, ensure_ascii=False)) <= 8000, "Adviser response is too long.")
    require(not contains_sensitive_bio_term(advice),
            "Adviser response contains prohibited sensitive biological terminology; treat it as unusable.")
    return advice, envelope


def invoke(command, brief, timeout):
    # A fresh directory prevents repository context being discovered by cwd.
    with tempfile.TemporaryDirectory(prefix="need2know-claude-") as directory:
        env = dict(os.environ)
        env.update(CLAUDE_CODE_MAX_OUTPUT_TOKENS="2000", CLAUDE_CODE_MAX_RETRIES="0")
        with subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, text=True, cwd=directory,
                              env=env, start_new_session=True) as process:
            try:
                stdout, _stderr = process.communicate(brief, timeout=timeout)
            except BaseException:
                # Stop the entire CLI process group, including any children.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.communicate()
                raise
            require(process.returncode == 0,
                    f"Claude exited with status {process.returncode}; check CLI installation, flags and authentication. No automatic retry.")
            return stdout


def save_record(handle, state):
    handle.seek(0)
    json.dump(state, handle, ensure_ascii=False, indent=2)
    handle.write("\n")
    handle.truncate()
    handle.flush()
    os.fsync(handle.fileno())


def consult(args):
    # Reject a large input before parsing it. Unicode can use four bytes per character.
    require(args.brief.stat().st_size <= 24_000, "Brief file is too large.")
    brief = json.loads(args.brief.read_text(encoding="utf-8"))
    encoded = validate_brief(brief)
    executable = shutil.which(args.claude)
    require(executable is not None, "Claude Code executable not found. Install/authenticate it before consulting.")
    prompt = (Path(__file__).resolve().parent.parent / "references/adviser.md").read_text(encoding="utf-8")
    command = [str(Path(executable).absolute()), "-p", "--bare", "--tools", "",
               "--strict-mcp-config", "--mcp-config", '{"mcpServers":{}}',
               "--setting-sources", "", "--no-session-persistence", "--max-turns", "1",
               "--max-budget-usd", str(args.budget_usd), "--output-format", "json",
               "--system-prompt", prompt]
    if args.model:
        command.extend(["--model", args.model])

    args.state.parent.mkdir(parents=True, exist_ok=True)
    # No code or private task identifiers are needed in this locally chosen path.
    descriptor = os.open(args.state, os.O_RDWR | os.O_CREAT, 0o600)
    with os.fdopen(descriptor, "r+", encoding="utf-8") as handle:
        os.fchmod(handle.fileno(), 0o600)
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ConsultationError("Another consultation is running for this task.") from None
        content = handle.read()
        state = json.loads(content) if content else {"version": 1, "calls": []}
        require(isinstance(state, dict) and state.get("version") == 1
                and isinstance(state.get("calls"), list), "Invalid task record; do not reset it to bypass limits.")
        calls = state["calls"]
        require(all(isinstance(c, dict) and isinstance(c.get("brief"), dict)
                    and isinstance(c.get("brief_sha256"), str)
                    and c.get("status") in ("pending", "advice", "clarify", "blocked", "error")
                    for c in calls), "Invalid call record; do not reset it to bypass limits.")
        require(len(calls) < 2, "Task consultation limit reached (two attempts). Stop and report to the user.")
        require(not calls or calls[-1].get("status") == "clarify",
                "Consultation is closed. Reuse existing advice, or report the stopped task.")
        digest = hashlib.sha256(encoded.encode()).hexdigest()
        require(all(c.get("brief_sha256") != digest for c in calls), "Identical brief already sent; no retry.")
        require(bool(calls) == ("clarification_answer" in brief),
                "Only the follow-up brief must contain clarification_answer.")
        call = {"brief_sha256": digest, "brief": brief, "status": "pending",
                "started_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "model": args.model, "budget_usd": args.budget_usd, "timeout_seconds": args.timeout}
        calls.append(call)
        # Reserve the attempt before starting Claude, including if this runner crashes.
        save_record(handle, state)
        started = time.monotonic()
        try:
            advice, envelope = parse_advice(invoke(command, encoded, args.timeout))
            call.update(status=advice["status"], advice=advice)
            for key in ("usage", "total_cost_usd", "duration_api_ms"):
                if key in envelope:
                    call[key] = envelope[key]
            if advice["status"] == "clarify" and len(calls) == 2:
                call["status"] = "blocked"
                call["stop_reason"] = "No further clarification allowance. Stop implementation."
        except Exception as error:
            call.update(status="error", error=str(error))
            raise
        finally:
            call["elapsed_seconds"] = round(time.monotonic() - started, 3)
            save_record(handle, state)
        return {"status": call["status"], "advice": advice, "calls_used": len(calls),
                "calls_remaining": 1 if call["status"] == "clarify" else 0,
                "elapsed_seconds": call["elapsed_seconds"],
                **{key: call[key] for key in ("usage", "total_cost_usd", "stop_reason") if key in call}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--brief", type=Path, required=True)
    parser.add_argument("--state", type=Path, required=True)
    parser.add_argument("--claude", default="claude", help="Claude executable (not a shell command)")
    parser.add_argument("--model", help="Optional Claude adviser model ID", default="opus")
    parser.add_argument("--timeout", type=float, default=120)
    parser.add_argument("--budget-usd", type=float, default=0.50)
    args = parser.parse_args()
    if not math.isfinite(args.timeout) or not math.isfinite(args.budget_usd) or min(args.timeout, args.budget_usd) <= 0:
        parser.error("Timeout and budget must be finite positive numbers.")
    try:
        result = consult(args)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 2 if result["status"] == "blocked" else 0
    except (ConsultationError, OSError, ValueError, TypeError, subprocess.TimeoutExpired) as error:
        print(json.dumps({"status": "error", "error": str(error)}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
