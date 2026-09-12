export const STAGES = [
	"recon",
	"contract",
	"tests",
	"test_review",
	"red",
	"implementation",
	"feature_review",
	"test_refinement",
	"feature_refinement",
	"verification",
	"done",
	"aborted",
] as const;

export type Stage = (typeof STAGES)[number];

export const AGENT_ROLES = [
	"scout",
	"testAuthor",
	"testReviewer",
	"testRefiner",
	"implementer",
	"featureReviewer",
	"featureRefiner",
] as const;

export type AgentRole = (typeof AGENT_ROLES)[number];

export type Verdict = "pass" | "fail" | "needs_human";

export interface AgentReport {
	verdict: Verdict;
	summary: string;
	findings: string[];
	changedFiles: string[];
	testPaths: string[];
	testCommand?: string;
	fullCommand?: string;
	humanQuestion?: string;
}

export interface AgentRun {
	role: AgentRole;
	model?: string;
	exitCode: number;
	output: string;
	stderr: string;
	report?: AgentReport;
	changedFiles: string[];
	testLockViolations: string[];
	startedAt: string;
	finishedAt: string;
}

export interface GateRun {
	kind: "red" | "verification";
	command: string;
	cwd: string;
	exitCode: number;
	stdout: string;
	stderr: string;
	timedOut: boolean;
	passed: boolean;
	changedFiles: string[];
	startedAt: string;
	finishedAt: string;
}

export interface HumanCheckpoint {
	stage: Stage;
	question: string;
	recommendation: string;
	outcome: "approved" | "feedback" | "paused";
	feedback?: string;
	at: string;
}

export interface StageHistory {
	stage: Stage | "intake" | "test_unlock";
	summary: string;
	at: string;
}

export interface BigTddState {
	version: 1;
	id: string;
	request: string;
	repoRoot: string;
	baseBranch: string;
	baseCommit: string;
	branch: string;
	artifactDir: string;
	stage: Stage;
	stageSequence: number;
	testPaths: string[];
	testCommand?: string;
	fullCommand?: string;
	lockedTestHashes: Record<string, string>;
	testUnlocks: number;
	testRefinements: number;
	featureRefinements: number;
	implementationCommitted: boolean;
	latestCheckpoint?: HumanCheckpoint;
	history: StageHistory[];
	createdAt: string;
	updatedAt: string;
}

export interface ModelConfig {
	orchestrator?: string;
	scout?: string;
	testAuthor?: string;
	testReviewer?: string;
	testRefiner?: string;
	implementer?: string;
	featureReviewer?: string;
	featureRefiner?: string;
}

export interface BigTddConfig {
	branchPrefix: string;
	artifactDirectory: string;
	agentTimeoutMinutes: number;
	humanCheckpoints: "agent-decides" | "always-contract";
	requireHumanForTestUnlock: boolean;
	allowMainAgentTestUnlockWithoutUI: boolean;
	models: ModelConfig;
	thinking: Partial<Record<AgentRole, string>>;
}

export type PendingRun =
	| { stage: Stage; kind: "agent"; attempts: AgentRun[] }
	| { stage: Stage; kind: "gate"; gate: GateRun };
