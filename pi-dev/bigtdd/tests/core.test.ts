import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { spawnSync } from "node:child_process";
import { afterEach, describe, it } from "node:test";
import { commitSubject, nextStage, normalizeRepoPath, normalizeTestPaths, slugify, timestampId } from "../extensions/bigtdd/core.ts";
import { assertClean, commitStage, createWorkflowBranch, inspectGit, writeArtifact } from "../extensions/bigtdd/git.ts";
import { runGate } from "../extensions/bigtdd/runner.ts";
import type { BigTddConfig, BigTddState } from "../extensions/bigtdd/types.ts";

const temporaryDirectories: string[] = [];

afterEach(() => {
	for (const directory of temporaryDirectories.splice(0)) fs.rmSync(directory, { recursive: true, force: true });
});

function tempRepo(): string {
	const directory = fs.mkdtempSync(path.join(os.tmpdir(), "bigtdd-test-"));
	temporaryDirectories.push(directory);
	for (const args of [
		["init", "-b", "main"],
		["config", "user.name", "BigTDD Test"],
		["config", "user.email", "bigtdd@example.invalid"],
	]) {
		const result = spawnSync("git", args, { cwd: directory, encoding: "utf8" });
		assert.equal(result.status, 0, result.stderr);
	}
	fs.writeFileSync(path.join(directory, "README.md"), "fixture\n");
	spawnSync("git", ["add", "README.md"], { cwd: directory });
	spawnSync("git", ["commit", "-m", "fixture"], { cwd: directory });
	return directory;
}

const mockPi = {
	exec(command: string, args: string[], options?: { cwd?: string }) {
		const result = spawnSync(command, args, { cwd: options?.cwd, encoding: "utf8" });
		return Promise.resolve({
			stdout: result.stdout ?? "",
			stderr: result.stderr ?? "",
			code: result.status ?? 1,
			killed: Boolean(result.signal),
		});
	},
} as any;

describe("workflow transitions", () => {
	it("follows the complete happy path", () => {
		let stage = "recon" as const;
		stage = nextStage(stage, "advance") as never;
		assert.equal(stage, "contract");
		assert.equal(nextStage("contract", "advance"), "tests");
		assert.equal(nextStage("tests", "advance"), "test_review");
		assert.equal(nextStage("test_review", "advance"), "red");
		assert.equal(nextStage("red", "advance"), "implementation");
		assert.equal(nextStage("implementation", "advance"), "feature_review");
		assert.equal(nextStage("feature_review", "advance"), "verification");
		assert.equal(nextStage("verification", "advance"), "done");
	});

	it("routes failed reviews and verification through fresh refiners", () => {
		assert.equal(nextStage("test_review", "refine"), "test_refinement");
		assert.equal(nextStage("red", "refine"), "test_refinement");
		assert.equal(nextStage("feature_review", "refine"), "feature_refinement");
		assert.equal(nextStage("verification", "refine"), "feature_refinement");
	});
});

describe("safe names and paths", () => {
	it("creates bounded branch slugs and stable local timestamps", () => {
		assert.equal(slugify(" Add OAuth 2.0 / OIDC support! "), "add-oauth-2-0-oidc-support");
		assert.equal(timestampId(new Date(2026, 8, 3, 9, 7, 5)), "20260903-090705");
	});

	it("normalizes and deduplicates repository-relative test paths", () => {
		const root = path.resolve("/tmp/example");
		assert.deepEqual(normalizeTestPaths(root, ["tests/a.ts", "./tests/a.ts", "tests/b.ts"]), ["tests/a.ts", "tests/b.ts"]);
		assert.throws(() => normalizeRepoPath(root, "../outside.ts"), /inside the repository/);
		assert.throws(() => normalizeRepoPath(root, "."), /inside the repository/);
	});
});

describe("Git stage checkpoints", () => {
	it("creates a workflow branch and a non-empty commit for a read-only stage", async () => {
		const repo = tempRepo();
		const git = await inspectGit(mockPi, repo);
		await assertClean(mockPi, repo);
		const config: BigTddConfig = {
			branchPrefix: "bigtdd/",
			artifactDirectory: ".bigtdd",
			agentTimeoutMinutes: 30,
			humanCheckpoints: "agent-decides",
			requireHumanForTestUnlock: true,
			allowMainAgentTestUnlockWithoutUI: false,
			models: {},
			thinking: {},
		};
		const branch = await createWorkflowBranch(mockPi, git, config, "demo", new Date(2026, 8, 3, 9, 7, 5));
		assert.equal(branch, "bigtdd/demo-20260903-090705");
		const now = new Date().toISOString();
		const state: BigTddState = {
			version: 1,
			id: "run",
			request: "Demo feature",
			repoRoot: repo,
			baseBranch: "main",
			baseCommit: git.head,
			branch,
			artifactDir: ".bigtdd/run",
			stage: "contract",
			stageSequence: 2,
			testPaths: [],
			lockedTestHashes: {},
			testUnlocks: 0,
			testRefinements: 0,
			featureRefinements: 0,
			implementationCommitted: false,
			history: [{ stage: "recon", summary: "Found the relevant code", at: now }],
			createdAt: now,
			updatedAt: now,
		};
		writeArtifact(state, "02-recon.md", "# Recon\n\nEvidence only.\n");
		const commit = await commitStage(mockPi, state, "recon", "Found the relevant code");
		assert.match(commit, /^[0-9a-f]{40}$/);
		const subject = spawnSync("git", ["show", "-s", "--format=%s", "HEAD"], { cwd: repo, encoding: "utf8" }).stdout.trim();
		assert.equal(subject, commitSubject(state, "recon"));
		assert.equal(spawnSync("git", ["status", "--porcelain"], { cwd: repo, encoding: "utf8" }).stdout, "");
	});

	it("re-establishes RED at the original base after implementation exists", async () => {
		const repo = tempRepo();
		const git = await inspectGit(mockPi, repo);
		fs.writeFileSync(path.join(repo, "feature.test.sh"), "#!/bin/sh\ntest -f feature.txt\n");
		spawnSync("git", ["add", "feature.test.sh"], { cwd: repo });
		spawnSync("git", ["commit", "-m", "tests"], { cwd: repo });
		fs.writeFileSync(path.join(repo, "feature.txt"), "implemented\n");
		spawnSync("git", ["add", "feature.txt"], { cwd: repo });
		spawnSync("git", ["commit", "-m", "implementation"], { cwd: repo });
		const now = new Date().toISOString();
		const state = {
			version: 1,
			id: "red-run",
			request: "Add feature",
			repoRoot: repo,
			baseBranch: "main",
			baseCommit: git.head,
			branch: "main",
			artifactDir: ".bigtdd/red-run",
			stage: "red",
			stageSequence: 5,
			testPaths: ["feature.test.sh"],
			testCommand: "sh feature.test.sh",
			fullCommand: "sh feature.test.sh",
			lockedTestHashes: {},
			testUnlocks: 1,
			testRefinements: 1,
			featureRefinements: 0,
			implementationCommitted: true,
			history: [],
			createdAt: now,
			updatedAt: now,
		} satisfies BigTddState;
		const gate = await runGate(mockPi, state, "red", state.testCommand);
		assert.equal(gate.exitCode, 1);
		assert.equal(gate.passed, true);
		assert.notEqual(gate.cwd, repo);
		assert.equal(fs.existsSync(gate.cwd), false, "temporary baseline worktree is removed");
	});

	it("reports files created by a verification command", async () => {
		const repo = tempRepo();
		const git = await inspectGit(mockPi, repo);
		const now = new Date().toISOString();
		const state = {
			version: 1,
			id: "verify-run",
			request: "Verify feature",
			repoRoot: repo,
			baseBranch: "main",
			baseCommit: git.head,
			branch: "main",
			artifactDir: ".bigtdd/verify-run",
			stage: "verification",
			stageSequence: 8,
			testPaths: [],
			testCommand: "true",
			fullCommand: "touch generated.txt",
			lockedTestHashes: {},
			testUnlocks: 0,
			testRefinements: 0,
			featureRefinements: 0,
			implementationCommitted: true,
			history: [],
			createdAt: now,
			updatedAt: now,
		} satisfies BigTddState;
		const gate = await runGate(mockPi, state, "verification", state.fullCommand);
		assert.equal(gate.passed, true);
		assert.deepEqual(gate.changedFiles, ["generated.txt"]);
	});
});
