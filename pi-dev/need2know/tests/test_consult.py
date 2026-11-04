"""Exercise the subprocess handoff and task limits without network/model calls."""

import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "skills/need2know/scripts/consult.py"
ADVICE = {"status": "advice", "recommendation": "Use an idempotency key at the side-effect boundary.",
          "checks": ["Deliver the same event concurrently."], "question": ""}
CLARIFY = {"status": "clarify", "recommendation": "", "checks": [],
           "question": "Does the remote service support an idempotency key?"}
BRIEF = {"goal": "Make event delivery safe to repeat.",
         "facts": ["Workers can receive duplicate events concurrently."],
         "constraints": ["Preserve the current API."],
         "question": "Where should duplicate suppression happen?"}


class ConsultationTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="need2know-test-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.repo = self.root / "private-repo"
        self.repo.mkdir()
        (self.repo / "CLAUDE.md").write_text("PRIVATE CONTEXT MUST NOT BE AUTO-LOADED")
        (self.repo / "private.py").write_text("PRIVATE SOURCE OUTSIDE THE SELECTED SNIPPET")
        self.brief_path = self.root / "brief.json"
        self.state_path = self.root / "consultation.json"
        self.trace_path = self.root / "trace.jsonl"
        self.fake = self.root / "claude"
        self.fake.write_text(f"#!{sys.executable}\n" + '''
import json
import os
from pathlib import Path
import sys
import time

brief = sys.stdin.read()
trace = {
    "argv": sys.argv[1:],
    "stdin": brief,
    "cwd": os.getcwd(),
    "files": os.listdir("."),
    "max_tokens": os.environ.get("CLAUDE_CODE_MAX_OUTPUT_TOKENS"),
    "max_retries": os.environ.get("CLAUDE_CODE_MAX_RETRIES"),
}
with open(os.environ["MOCK_TRACE"], "a") as handle:
    handle.write(json.dumps(trace) + "\\n")
time.sleep(float(os.environ.get("MOCK_DELAY", "0")))
if "MOCK_RAW_OUTPUT" in os.environ:
    print(os.environ["MOCK_RAW_OUTPUT"])
else:
    print(json.dumps({"type": "result", "subtype": "success", "is_error": False,
                      "result": os.environ["MOCK_ADVICE"],
                      "usage": {"input_tokens": 700, "output_tokens": 90},
                      "total_cost_usd": 0.003}))
sys.exit(int(os.environ.get("MOCK_EXIT", "0")))
''')
        self.fake.chmod(0o700)

    def run_consult(self, brief=None, advice=None, env=None, extra=None):
        self.brief_path.write_text(json.dumps(BRIEF if brief is None else brief))
        environment = dict(os.environ)
        environment.update(MOCK_TRACE=str(self.trace_path),
                           MOCK_ADVICE=json.dumps(ADVICE if advice is None else advice))
        environment.update(env or {})
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--brief", str(self.brief_path),
             "--state", str(self.state_path), "--claude", str(self.fake), *(extra or [])],
            cwd=self.repo, env=environment, text=True, capture_output=True, timeout=10)

    def traces(self):
        return [json.loads(line) for line in self.trace_path.read_text().splitlines()]

    def record(self):
        return json.loads(self.state_path.read_text())

    def test_only_selected_brief_crosses_subprocess_boundary(self):
        brief = dict(BRIEF, snippets=[{"language": "python", "code": "send(event_alias)"}])
        result = self.run_consult(brief=brief)
        self.assertEqual(result.returncode, 0, result.stderr)
        trace, = self.traces()
        self.assertEqual(json.loads(trace["stdin"]), brief)
        self.assertEqual(trace["files"], [])
        self.assertNotEqual(trace["cwd"], str(self.repo))
        self.assertNotIn("PRIVATE", json.dumps(trace))
        self.assertNotIn(str(self.repo), json.dumps(trace))
        self.assertIn("--bare", trace["argv"])
        self.assertEqual(trace["argv"][trace["argv"].index("--tools") + 1], "")
        self.assertIn("--strict-mcp-config", trace["argv"])
        self.assertEqual(json.loads(trace["argv"][trace["argv"].index("--mcp-config") + 1]), {"mcpServers": {}})
        self.assertIn("--no-session-persistence", trace["argv"])
        self.assertEqual(trace["max_tokens"], "2000")
        self.assertEqual(trace["max_retries"], "0")
        output = json.loads(result.stdout)
        self.assertEqual(output["status"], "advice")
        self.assertEqual(output["usage"]["input_tokens"], 700)
        self.assertEqual(output["total_cost_usd"], 0.003)
        self.assertEqual(self.record()["calls"][0]["brief"], brief)
        self.assertEqual(self.state_path.stat().st_mode & 0o777, 0o600)
        self.assertFalse(Path(trace["cwd"]).exists())

    def test_advice_closes_consultation_and_resume_does_not_call_again(self):
        self.assertEqual(self.run_consult().returncode, 0)
        result = self.run_consult(brief=dict(BRIEF, question="A differently worded question"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("closed", result.stderr)
        self.assertEqual(len(self.traces()), 1)
        self.assertEqual(len(self.record()["calls"]), 1)

    def test_one_clarification_then_advice_exhausts_allowance(self):
        first = self.run_consult(advice=CLARIFY)
        self.assertEqual(json.loads(first.stdout)["calls_remaining"], 1)
        second = self.run_consult(brief=dict(BRIEF, clarification_answer="Yes, for one day."))
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(json.loads(second.stdout)["calls_used"], 2)
        third = self.run_consult(brief=dict(BRIEF, clarification_answer="A third fact"))
        self.assertEqual(third.returncode, 1)
        self.assertIn("limit reached", third.stderr)
        self.assertEqual(len(self.traces()), 2)

    def test_second_clarification_stops_instead_of_looping(self):
        self.run_consult(advice=CLARIFY)
        second = self.run_consult(brief=dict(BRIEF, clarification_answer="Unknown."), advice=CLARIFY)
        self.assertEqual(second.returncode, 2, second.stderr)
        self.assertEqual(json.loads(second.stdout)["status"], "blocked")
        self.assertEqual(self.record()["calls"][-1]["status"], "blocked")
        self.assertEqual(json.loads(second.stdout)["calls_remaining"], 0)

    def test_identical_brief_is_not_sent_twice(self):
        self.run_consult(advice=CLARIFY)
        result = self.run_consult(advice=CLARIFY)
        self.assertEqual(result.returncode, 1)
        self.assertIn("Identical brief", result.stderr)
        self.assertEqual(len(self.traces()), 1)

    def test_explicit_blocking_response_stops(self):
        blocked = {"status": "blocked", "recommendation": "This needs more source than allowed.",
                   "checks": [], "question": ""}
        result = self.run_consult(advice=blocked)
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(self.record()["calls"][0]["status"], "blocked")
        self.assertEqual(self.run_consult().returncode, 1)
        self.assertEqual(len(self.traces()), 1)

    def test_invalid_response_consumes_attempt_without_auto_repair(self):
        result = self.run_consult(env={"MOCK_RAW_OUTPUT": "not json"})
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.record()["calls"][0]["status"], "error")
        self.assertEqual(self.run_consult().returncode, 1)
        self.assertEqual(len(self.traces()), 1)

    def test_nonzero_exit_and_timeout_stop_without_retry(self):
        for env, extra in [({"MOCK_EXIT": "3"}, []),
                           ({"MOCK_DELAY": "2"}, ["--timeout", "0.2"])]:
            with self.subTest(env=env):
                self.state_path = self.root / ("state-" + next(iter(env)) + ".json")
                result = self.run_consult(env=env, extra=extra)
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertEqual(self.record()["calls"][0]["status"], "error")
                self.assertEqual(len(self.record()["calls"]), 1)

    def test_pending_crashed_attempt_is_not_automatically_retried(self):
        self.run_consult(advice=CLARIFY)
        record = self.record()
        record["calls"][0]["status"] = "pending"
        self.state_path.write_text(json.dumps(record))
        result = self.run_consult(brief=dict(BRIEF, clarification_answer="A new fact."))
        self.assertEqual(result.returncode, 1)
        self.assertIn("closed", result.stderr)
        self.assertEqual(len(self.traces()), 1)

    def test_concurrent_task_call_is_rejected(self):
        with self.state_path.open("w+") as handle:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = self.run_consult()
            self.assertEqual(result.returncode, 1)
            self.assertIn("Another consultation", result.stderr)
            self.assertFalse(self.trace_path.exists())

    def test_disclosure_limits_and_field_allowlist_checked_before_launch(self):
        invalid = [dict(BRIEF, raw_conversation="Do not forward arbitrary fields"),
                   dict(BRIEF, snippets=[{"language": "python", "code": "x" * 2001}]),
                   dict(BRIEF, snippets=[{"language": "python", "code": "x"}] * 3),
                   dict(BRIEF, goal="x" * 6000),
                   dict(BRIEF, clarification_answer="Unsolicited follow-up"),
                   dict(BRIEF, facts="Not an array")]
        for brief in invalid:
            with self.subTest(brief_keys=list(brief)):
                result = self.run_consult(brief=brief)
                self.assertEqual(result.returncode, 1)
                self.assertFalse(self.trace_path.exists())

    def test_unsuccessful_cli_envelope_is_not_treated_as_advice(self):
        envelope = {"type": "result", "subtype": "error_max_turns", "is_error": True,
                    "result": json.dumps(ADVICE)}
        result = self.run_consult(env={"MOCK_RAW_OUTPUT": json.dumps(envelope)})
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.record()["calls"][0]["status"], "error")


if __name__ == "__main__":
    unittest.main()
