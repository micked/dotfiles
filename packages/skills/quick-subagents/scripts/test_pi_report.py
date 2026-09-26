#!/usr/bin/env python3
"""Focused tests for pi_report.py. Run: python3 -m unittest test_pi_report -v"""

import json
import os
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pi_report  # noqa: E402


def write_log(lines):
    fd, path = tempfile.mkstemp(suffix=".jsonl")
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(lines)
    return path


def asst_message(text, usage=None, stop_reason="stop"):
    message = {
        "role": "assistant",
        "content": [{"type": "text", "text": text}],
        "stopReason": stop_reason,
    }
    if usage is not None:
        message["usage"] = usage
    return json.dumps({"type": "message_end", "message": message})


USAGE = {
    "input": 10,
    "output": 5,
    "cacheRead": 2,
    "cacheWrite": 1,
    "reasoning": 3,
    "totalTokens": 21,
    "cost": {"total": 0.25},
}


class PiReportTests(unittest.TestCase):
    def test_timeout_after_tool_request_has_no_final_or_complete_usage(self):
        path = write_log(asst_message("Next I will run tests", USAGE, "toolUse") + "\n")
        report = pi_report.summarize(path, 124)
        self.assertIsNone(report["finalAssistantText"])
        self.assertFalse(report["usageComplete"])
        self.assertEqual(report["usage"]["input"]["sum"], 10)
        os.unlink(path)

    def test_interrupted_new_turn_does_not_reuse_prior_final(self):
        lines = [asst_message("Earlier answer", USAGE),
                 json.dumps({"type": "message_start", "message": {"role": "assistant"}})]
        path = write_log("\n".join(lines) + "\n")
        report = pi_report.summarize(path)
        self.assertIsNone(report["finalAssistantText"])
        self.assertTrue(report["assistantInProgress"])
        self.assertFalse(report["usageComplete"])
        os.unlink(path)

    def test_valid_final_line_without_newline_is_not_truncated(self):
        path = write_log(asst_message("answer", USAGE))
        report = pi_report.summarize(path)
        self.assertFalse(report["truncatedFinalLine"])
        self.assertTrue(report["unterminatedFinalLine"])
        os.unlink(path)

    def test_ordinary_multi_turn_with_tool_and_agent_end(self):
        lines = [
            json.dumps({"type": "session", "version": 3, "id": "x"}),
            json.dumps({"type": "turn_start"}),
            asst_message("hello", USAGE),
            json.dumps({"type": "tool_execution_end", "toolName": "bash", "isError": False, "result": "big body"}),
            asst_message("done", USAGE),
            json.dumps({"type": "agent_end", "messages": []}),
        ]
        path = write_log("\n".join(lines) + "\n")
        report = pi_report.summarize(path)
        self.assertEqual(report["assistantMessages"], 2)
        self.assertEqual(report["toolErrors"], 0)
        self.assertEqual(report["usage"]["input"]["sum"], 20)
        self.assertEqual(report["usage"]["costTotal"]["sum"], 0.5)
        self.assertTrue(report["agentEndObserved"])
        self.assertEqual(report["finalAssistantText"], "done")
        self.assertFalse(report["finalTextTruncated"])
        self.assertNotIn("big body", json.dumps(report))
        self.assertEqual(report["processExitStatus"], "unknown")
        os.unlink(path)

    def test_agent_end_repeated_messages_do_not_double_totals(self):
        msg = asst_message("answer", USAGE)
        lines = [
            msg,
            json.dumps({"type": "agent_end", "messages": [json.loads(msg)["message"]]}),
            json.dumps({"type": "agent_end", "messages": [json.loads(msg)["message"]]}),
        ]
        path = write_log("\n".join(lines) + "\n")
        report = pi_report.summarize(path)
        self.assertEqual(report["assistantMessages"], 1)
        self.assertEqual(report["usage"]["input"]["sum"], 10)
        self.assertEqual(report["usage"]["output"]["sum"], 5)
        self.assertTrue(report["agentEndObserved"])
        self.assertEqual(report["agentEndCount"], 2)
        os.unlink(path)

    def test_provider_error_and_aborted_partial_with_truncated_tail(self):
        partial = '{"type":"message_end","message":{"role":"assistant","content":[{"type":"text","text":"cut'
        lines = [
            asst_message("bad", {"input": 4, "output": 1}, stop_reason="error"),
            asst_message("", {"input": 2}, stop_reason="aborted"),
            partial,
        ]
        # No trailing newline: the final line is truncated mid-record.
        path = write_log("\n".join(lines))
        report = pi_report.summarize(path)
        self.assertEqual(report["assistantMessages"], 2)
        self.assertEqual(report["malformedLines"], 1)
        self.assertTrue(report["providerErrorOrAborted"])
        self.assertEqual(report["stopReasons"]["error"], 1)
        self.assertEqual(report["stopReasons"]["aborted"], 1)
        self.assertEqual(report["usage"]["input"]["sum"], 6)
        self.assertFalse(report["usageComplete"])
        self.assertTrue(report["truncatedFinalLine"])
        os.unlink(path)

    def test_missing_usage_is_unavailable_not_zero(self):
        lines = [asst_message("no usage here")]
        path = write_log("\n".join(lines) + "\n")
        report = pi_report.summarize(path)
        self.assertIsNone(report["usage"]["input"]["sum"])
        self.assertEqual(report["usage"]["input"]["reported"], 0)
        self.assertFalse(report["usageComplete"])
        self.assertTrue(any("unavailable" in c for c in report["usageCaveats"]))
        os.unlink(path)

    def test_text_cap_marks_truncation(self):
        long_text = "x" * (pi_report.FINAL_TEXT_CAP + 50)
        path = write_log(asst_message(long_text) + "\n")
        report = pi_report.summarize(path)
        self.assertTrue(report["finalTextTruncated"])
        self.assertEqual(len(report["finalAssistantText"]), pi_report.FINAL_TEXT_CAP)
        self.assertEqual(report["finalTextLength"], pi_report.FINAL_TEXT_CAP + 50)
        os.unlink(path)

    def test_cli_exit_code_and_single_log_enforcement(self):
        path = write_log(asst_message("ok", USAGE) + "\n")
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pi_report.py")
        proc = subprocess.run(
            [sys.executable, script, path, "--exit-code", "3"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 0)
        payload = json.loads(proc.stdout)
        self.assertEqual(payload["logs"][0]["processExitCode"], 3)
        self.assertEqual(payload["logs"][0]["processExitStatus"], "provided")

        proc2 = subprocess.run(
            [sys.executable, script, path, path, "--exit-code", "1"],
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc2.returncode, 2)
        os.unlink(path)


if __name__ == "__main__":
    unittest.main()
