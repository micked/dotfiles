#!/usr/bin/env python3
"""Summarize Pi ``--mode json`` event logs (JSONL) without loading transcripts.

This tool never asks a model to read a transcript and never emits tool output
bodies or thinking text. It streams each log line by line and returns compact
JSON.

Trust rules (important):

* A process exit code and the final assistant text are reported as raw,
  factual observations only. This tool does NOT infer that the run "passed",
  "failed", "is DONE", produced an acceptable result, or that any check was
  verified. Those judgments require the caller's own criteria.
* Usage is summed only from ``message_end`` events with an assistant role.
  ``agent_end`` may repeat full messages, so counting it would double-count.
* Missing usage is reported as unavailable, never inferred as zero. If some
  assistant messages lack a usage field, the total is flagged incomplete.
* ``cost.total`` is included only when the provider/model explicitly reported
  it; it is never estimated.

Usage:
    pi_report.py LOG.jsonl [LOG2.jsonl ...] [--exit-code N]

``--exit-code`` supplies the separate process exit status for a single log
only. Without it, process exit status is reported as unknown.
"""

from __future__ import annotations

import argparse
import json
import sys
from typing import Any

FINAL_TEXT_CAP = 2000

# field name -> path inside a message's ``usage`` object.
USAGE_FIELDS: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("input", ("input",)),
    ("output", ("output",)),
    ("cacheRead", ("cacheRead",)),
    ("cacheWrite", ("cacheWrite",)),
    ("reasoning", ("reasoning",)),
    ("totalTokens", ("totalTokens",)),
    ("costTotal", ("cost", "total")),
)

ERROR_STOP_REASONS = {"error", "aborted"}


def _dig(obj: Any, path: tuple[str, ...]) -> Any:
    for key in path:
        if not isinstance(obj, dict) or key not in obj:
            return None
        obj = obj[key]
    return obj


def _extract_text(content: Any) -> str:
    if not isinstance(content, list):
        return ""
    parts = []
    for block in content:
        if isinstance(block, dict) and block.get("type") == "text":
            text = block.get("text")
            if isinstance(text, str):
                parts.append(text)
    return "".join(parts)


def summarize(path: str, exit_code: int | None = None) -> dict[str, Any]:
    """Stream one JSONL log file and return a faithful summary dict."""
    assistant_messages = 0
    tool_errors = 0
    agent_end_count = 0
    malformed_lines = 0
    stop_reasons: dict[str, int] = {}
    usage_state = {name: {"sum": None, "reported": 0} for name, _ in USAGE_FIELDS}
    final_text: str | None = None
    final_length: int | None = None
    last_line_terminated = True
    malformed_tail = False
    assistant_in_progress = False
    last_stop_reason = None

    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            last_line_terminated = raw.endswith("\n")
            malformed_tail = False
            line = raw.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except (json.JSONDecodeError, ValueError):
                malformed_lines += 1
                malformed_tail = True
                continue
            if not isinstance(event, dict):
                malformed_lines += 1
                continue

            etype = event.get("type")
            if etype == "message_start" and event.get("message", {}).get("role") == "assistant":
                assistant_in_progress = True
                final_text = None
                final_length = None
                last_stop_reason = None
            elif etype == "message_end":
                message = event.get("message")
                if not isinstance(message, dict):
                    continue
                if message.get("role") != "assistant":
                    continue
                assistant_messages += 1
                assistant_in_progress = False

                stop_reason = message.get("stopReason")
                last_stop_reason = stop_reason
                if isinstance(stop_reason, str):
                    stop_reasons[stop_reason] = stop_reasons.get(stop_reason, 0) + 1

                usage = message.get("usage")
                if isinstance(usage, dict):
                    for name, field_path in USAGE_FIELDS:
                        value = _dig(usage, field_path)
                        if isinstance(value, (int, float)) and not isinstance(value, bool):
                            state = usage_state[name]
                            state["sum"] = (state["sum"] or 0) + value
                            state["reported"] += 1

                # Tool requests, errors, and length-limited output are not a
                # completed final answer, even when they contain prose.
                final_text = (
                    _extract_text(message.get("content"))
                    if stop_reason == "stop"
                    else None
                )
                final_length = len(final_text) if final_text is not None else None

            elif etype == "tool_execution_end":
                if event.get("isError") is True:
                    tool_errors += 1

            elif etype == "agent_end":
                agent_end_count += 1

    usage: dict[str, Any] = {}
    incomplete: list[str] = []
    unavailable: list[str] = []
    for name, _ in USAGE_FIELDS:
        state = usage_state[name]
        if state["reported"] == 0:
            usage[name] = {"sum": None, "reported": 0}
            unavailable.append(name)
        else:
            usage[name] = {"sum": state["sum"], "reported": state["reported"]}
            if state["reported"] < assistant_messages:
                incomplete.append(name)

    caveats: list[str] = []
    stream_incomplete = (
        agent_end_count == 0 or assistant_in_progress or malformed_lines > 0
        or exit_code not in (None, 0)
        or any(reason in ERROR_STOP_REASONS for reason in stop_reasons)
    )
    if stream_incomplete:
        caveats.append(
            "run may be incomplete; totals cover completed message_end events only; "
            "unfinished generation usage is unavailable"
        )
    if assistant_messages == 0:
        caveats.append("no assistant message_end events; usage unavailable")
    if incomplete:
        caveats.append(
            "incomplete usage totals (some assistant messages omitted these fields): "
            + ", ".join(incomplete)
        )
    if unavailable and assistant_messages > 0:
        caveats.append("usage fields never reported (unavailable, not zero): " + ", ".join(unavailable))

    if final_text is None:
        final_text_out = None
        truncated = False
    elif len(final_text) > FINAL_TEXT_CAP:
        final_text_out = final_text[:FINAL_TEXT_CAP]
        truncated = True
    else:
        final_text_out = final_text
        truncated = False

    error_stops = sorted(r for r in stop_reasons if r in ERROR_STOP_REASONS)

    return {
        "path": path,
        "assistantMessages": assistant_messages,
        "usage": usage,
        "usageComplete": bool(
            assistant_messages > 0 and not incomplete and not unavailable
            and not stream_incomplete
        ),
        "usageCaveats": caveats,
        "finalAssistantText": final_text_out,
        "finalTextLength": final_length,
        "finalTextTruncated": truncated,
        "finalTextCap": FINAL_TEXT_CAP,
        "agentEndObserved": agent_end_count > 0,
        "agentEndCount": agent_end_count,
        "assistantInProgress": assistant_in_progress,
        "lastAssistantStopReason": last_stop_reason,
        "processExitCode": exit_code,
        "processExitStatus": "unknown" if exit_code is None else "provided",
        "processExitNote": (
            "process exit status not supplied; do not infer run outcome"
            if exit_code is None
            else "process exit code is a raw observation only"
        ),
        "stopReasons": stop_reasons,
        "providerErrorOrAborted": bool(error_stops),
        "providerErrorStopReasons": error_stops,
        "toolErrors": tool_errors,
        "malformedLines": malformed_lines,
        "truncatedFinalLine": not last_line_terminated and malformed_tail,
        "unterminatedFinalLine": not last_line_terminated,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Summarize Pi --mode json JSONL logs as compact JSON (read-only, no model calls)."
    )
    parser.add_argument("logs", nargs="+", help="JSONL log path(s)")
    parser.add_argument(
        "--exit-code",
        type=int,
        default=None,
        help="explicit process exit code for a single log (separate from agent_end)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.exit_code is not None and len(args.logs) != 1:
        sys.stderr.write("--exit-code requires exactly one log path\n")
        return 2

    reports = []
    for index, path in enumerate(args.logs):
        code = args.exit_code if index == 0 else None
        reports.append(summarize(path, code))

    json.dump({"logs": reports}, sys.stdout, separators=(",", ":"))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
