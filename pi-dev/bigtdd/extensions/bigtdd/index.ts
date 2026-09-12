import * as path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import {
	bounded,
	formatState,
	isReviewStage,
	isWriterStage,
	nextStage,
	normalizeRepoPath,
	normalizeTestPaths,
	requiresPassingReport,
	roleForStage,
	slugify,
	timestampId,
} from "./core.ts";
import { loadConfig } from "./config.ts";
import {
	assertClean,
	changedFiles,
	clearPending,
	commitStage,
	createWorkflowBranch,
	currentBranch,
	fileHashes,
	hashDifferences,
	inspectGit,
	loadPending,
	loadStateFromRepo,
	savePending,
	writeArtifact,
} from "./git.ts";
import { buildTask, runAgent, runGate } from "./runner.ts";
import type {
	AgentReport,
	BigTddConfig,
	BigTddState,
	HumanCheckpoint,
	PendingRun,
	Stage,
} from "./types.ts";

const ACTIONS = ["status", "run_stage", "complete_stage", "checkpoint", "unlock_tests", "abort"] as const;
const DECISIONS = ["advance", "refine"] as const;
const APPROVAL_SOURCES = ["human", "main-agent", "independent-reviewer"] as const;

const ActionSchema = Type.Union([
	Type.Literal(ACTIONS[0]),
	Type.Literal(ACTIONS[1]),
	Type.Literal(ACTIONS[2]),
	Type.Literal(ACTIONS[3]),
	Type.Literal(ACTIONS[4]),
	Type.Literal(ACTIONS[5]),
]);
const DecisionSchema = Type.Union([Type.Literal(DECISIONS[0]), Type.Literal(DECISIONS[1])]);
const ApprovalSourceSchema = Type.Union([
	Type.Literal(APPROVAL_SOURCES[0]),
	Type.Literal(APPROVAL_SOURCES[1]),
	Type.Literal(APPROVAL_SOURCES[2]),
]);

const ControlParams = Type.Object({
	action: ActionSchema,
	focus: Type.Optional(Type.String({ description: "Targeted focus for a fresh stage agent" })),
	summary: Type.Optional(Type.String({ description: "Evidence-based summary recorded in the stage artifact" })),
	decision: Type.Optional(DecisionSchema),
	contract: Type.Optional(Type.String({ description: "Markdown acceptance contract for the contract stage" })),
	testPaths: Type.Optional(Type.Array(Type.String(), { description: "Complete repository-relative set of test files" })),
	testCommand: Type.Optional(Type.String({ description: "Narrow command for the new tests" })),
	fullCommand: Type.Optional(Type.String({ description: "Full repository verification command" })),
	redFailureMatchesContract: Type.Optional(
		Type.Boolean({ description: "Attest that RED failed because requested behavior is missing, not because setup is broken" }),
	),
	allowUnexpectedChanges: Type.Optional(
		Type.Boolean({ description: "Allow paths outside the expected stage scope; requires a human-approved checkpoint" }),
	),
	waiveRed: Type.Optional(Type.Boolean({ description: "Advance without reproducible RED; requires a human-approved checkpoint" })),
	question: Type.Optional(Type.String({ description: "Question for the human checkpoint" })),
	context: Type.Optional(Type.String({ description: "Concise evidence and choices shown to the human" })),
	recommendation: Type.Optional(Type.String({ description: "Recommended human choice" })),
	reason: Type.Optional(Type.String({ description: "Exact reason locked tests must be reopened or workflow aborted" })),
	approvalSource: Type.Optional(ApprovalSourceSchema),
	approvalEvidence: Type.Optional(Type.String({ description: "Human or independent-review evidence for test unlock" })),
});

function textResult(text: string, details: Record<string, unknown> = {}, isError = false) {
	return { content: [{ type: "text" as const, text }], details, ...(isError ? { isError: true } : {}) };
}

function childMode(pi: ExtensionAPI): void {
	const lockedTests = (() => {
		try {
			return JSON.parse(process.env.BIGTDD_LOCKED_TESTS ?? "[]") as string[];
		} catch {
			return [];
		}
	})();
	const repoRoot = process.env.BIGTDD_REPO_ROOT ?? process.cwd();
	const role = process.env.BIGTDD_CHILD_ROLE ?? "unknown";
	const protectsTests = role === "implementer" || role === "featureRefiner";
	const lockedAbsolute = new Set(lockedTests.map((file) => path.resolve(repoRoot, file)));

	if (protectsTests && lockedAbsolute.size > 0) {
		pi.on("tool_call", (event) => {
			if (event.toolName === "edit" || event.toolName === "write") {
				const candidate = typeof event.input.path === "string" ? path.resolve(repoRoot, event.input.path) : "";
				if (lockedAbsolute.has(candidate)) {
					return { block: true, reason: `BigTDD test lock: ${path.relative(repoRoot, candidate)} is immutable` };
				}
			}
			if (event.toolName === "bash") {
				const command = String(event.input.command ?? "");
				const mentionsLockedTest = lockedTests.some((file) => command.includes(file));
				const looksMutating = /(?:^|[;&|\s])(rm|mv|cp|install|touch|truncate|tee|sed\s+-i|perl\s+-pi)(?:\s|$)|(?:^|[^<])>{1,2}/.test(
					command,
				);
				if (mentionsLockedTest && looksMutating) {
					return { block: true, reason: "BigTDD test lock: mutating locked tests through bash is not allowed" };
				}
			}
		});
	}

	pi.registerTool({
		name: "bigtdd_report",
		label: "BigTDD Report",
		description: "Return the final structured report for this BigTDD specialist assignment.",
		promptSnippet: "Finish the assignment with a structured BigTDD verdict",
		promptGuidelines: ["Call bigtdd_report exactly once as the final action. Do not respond after calling it."],
		parameters: Type.Object({
			verdict: Type.Union([Type.Literal("pass"), Type.Literal("fail"), Type.Literal("needs_human")]),
			summary: Type.String(),
			findings: Type.Array(Type.String()),
			changedFiles: Type.Array(Type.String()),
			testPaths: Type.Array(Type.String()),
			testCommand: Type.Optional(Type.String()),
			fullCommand: Type.Optional(Type.String()),
			humanQuestion: Type.Optional(Type.String()),
		}),
		async execute(_toolCallId, params) {
			return {
				content: [{ type: "text", text: `BigTDD report recorded: ${params.verdict}` }],
				details: params,
				terminate: true,
			};
		},
	});
}

function checkpointApproved(state: BigTddState): boolean {
	return state.latestCheckpoint?.stage === state.stage && state.latestCheckpoint.outcome === "approved";
}

function checkpointResolved(state: BigTddState): boolean {
	return (
		state.latestCheckpoint?.stage === state.stage &&
		(state.latestCheckpoint.outcome === "approved" || state.latestCheckpoint.outcome === "feedback")
	);
}

function stageArtifact(state: BigTddState, stage: Stage | "test_unlock", body: string): string {
	const sequence = String(state.stageSequence).padStart(2, "0");
	return writeArtifact(state, `${sequence}-${stage.replaceAll("_", "-")}.md`, body);
}

function reportMarkdown(report: AgentReport | undefined): string {
	if (!report) return "No structured report was returned.";
	return [
		`Verdict: **${report.verdict}**`,
		"",
		report.summary,
		"",
		"## Findings",
		"",
		...(report.findings.length > 0 ? report.findings.map((finding) => `- ${finding}`) : ["- None"]),
		"",
		"## Reported changes",
		"",
		...(report.changedFiles.length > 0 ? report.changedFiles.map((file) => `- \`${file}\``) : ["- None"]),
	].join("\n");
}

function pendingMarkdown(pending: PendingRun | undefined): string {
	if (!pending) return "No delegated run was required for this stage.";
	if (pending.kind === "gate") {
		const gate = pending.gate;
		return [
			`Command: \`${gate.command}\``,
			`Exit code: ${gate.exitCode}`,
			`Gate result: **${gate.passed ? "pass" : "fail"}**`,
			"",
			"## Standard output",
			"",
			"```text",
			bounded(gate.stdout, 32 * 1024),
			"```",
			"",
			"## Standard error",
			"",
			"```text",
			bounded(gate.stderr, 32 * 1024),
			"```",
		].join("\n");
	}
	return pending.attempts
		.map((attempt, index) =>
			[
				`## Attempt ${index + 1}: ${attempt.role}`,
				"",
				`Model: ${attempt.model ?? "inherited"}`,
				`Exit code: ${attempt.exitCode}`,
				`Actual changed files: ${attempt.changedFiles.join(", ") || "none"}`,
				attempt.testLockViolations.length > 0
					? `Test lock violations: ${attempt.testLockViolations.join(", ")}`
					: "Test lock violations: none",
				"",
				reportMarkdown(attempt.report),
				attempt.output ? `\n## Additional output\n\n${bounded(attempt.output, 16 * 1024)}` : "",
				attempt.stderr ? `\n## Diagnostics\n\n\`\`\`text\n${bounded(attempt.stderr, 8 * 1024)}\n\`\`\`` : "",
			].join("\n"),
		)
		.join("\n\n---\n\n");
}

function orchestrationMessage(state: BigTddState): string {
	return `[BIGTDD ACTIVE]\n${formatState(state)}\n\nAct as the strong parent orchestrator. Use the bigtdd tool for every workflow action and do not edit files or make Git commits yourself. Follow the bigtdd skill. Run the current stage, inspect evidence, ask a human checkpoint when ambiguity or reviewer disagreement could cause rework, then complete or refine the stage. Do not skip RED, independent reviews, the test lock, or full verification.`;
}

export default function bigTddExtension(pi: ExtensionAPI): void {
	if (process.env.BIGTDD_CHILD === "1") {
		childMode(pi);
		return;
	}

	let state: BigTddState | undefined;
	let config: BigTddConfig | undefined;

	async function recover(cwd: string): Promise<BigTddState | undefined> {
		if (state) {
			const relative = path.relative(state.repoRoot, cwd);
			if (relative === "" || (!relative.startsWith("..") && !path.isAbsolute(relative))) return state;
		}
		try {
			const git = await inspectGit(pi, cwd);
			config = loadConfig(git.repoRoot);
			const candidate = loadStateFromRepo(git.repoRoot, config.artifactDirectory);
			if (candidate && candidate.branch === git.branch) state = candidate;
			return state;
		} catch {
			return undefined;
		}
	}

	async function ensureBranch(active: BigTddState): Promise<void> {
		const branch = await currentBranch(pi, active.repoRoot);
		if (branch !== active.branch) throw new Error(`BigTDD run belongs to ${active.branch}, but current branch is ${branch}`);
	}

	async function selectOrchestratorModel(ctx: ExtensionContext): Promise<void> {
		const reference = config?.models.orchestrator;
		if (!reference) return;
		const slash = reference.indexOf("/");
		if (slash < 1) {
			ctx.ui.notify(`Invalid BigTDD orchestrator model: ${reference}`, "warning");
			return;
		}
		const model = ctx.modelRegistry.find(reference.slice(0, slash), reference.slice(slash + 1));
		if (!model || !(await pi.setModel(model))) {
			ctx.ui.notify(`BigTDD could not select ${reference}; continuing with the active model`, "warning");
		}
	}

	async function initialize(request: string, ctx: ExtensionContext): Promise<BigTddState> {
		const git = await inspectGit(pi, ctx.cwd);
		await assertClean(pi, git.repoRoot);
		config = loadConfig(git.repoRoot);
		const now = new Date();
		const requestSlug = slugify(request);
		const id = `${timestampId(now)}-${requestSlug}`;
		const branch = await createWorkflowBranch(pi, git, config, requestSlug, now);
		const createdAt = now.toISOString();
		const active: BigTddState = {
			version: 1,
			id,
			request,
			repoRoot: git.repoRoot,
			baseBranch: git.branch,
			baseCommit: git.head,
			branch,
			artifactDir: path.posix.join(config.artifactDirectory, id),
			stage: "recon",
			stageSequence: 1,
			testPaths: [],
			lockedTestHashes: {},
			testUnlocks: 0,
			testRefinements: 0,
			featureRefinements: 0,
			implementationCommitted: false,
			history: [{ stage: "intake", summary: `Started from ${git.branch}@${git.head}`, at: createdAt }],
			createdAt,
			updatedAt: createdAt,
		};
		writeArtifact(active, "00-request.md", `# Original request\n\n${request}\n`);
		writeArtifact(
			active,
			"01-intake.md",
			`# BigTDD intake\n\n- Base branch: \`${git.branch}\`\n- Base commit: \`${git.head}\`\n- Workflow branch: \`${branch}\`\n- Started: ${createdAt}\n`,
		);
		await commitStage(pi, active, "intake", active.history[0].summary);
		state = active;
		pi.appendEntry("bigtdd-state", active);
		await selectOrchestratorModel(ctx);
		return active;
	}

	pi.on("session_start", async (_event, ctx) => {
		const active = await recover(ctx.cwd);
		if (active && active.stage !== "done" && active.stage !== "aborted") {
			ctx.ui.setStatus("bigtdd", ctx.ui.theme.fg("accent", `BigTDD: ${active.stage}`));
		}
	});

	pi.on("before_agent_start", async (_event, ctx) => {
		const active = await recover(ctx.cwd);
		if (!active || active.stage === "done" || active.stage === "aborted") return;
		return {
			message: { customType: "bigtdd-context", content: orchestrationMessage(active), display: false },
		};
	});

	pi.on("tool_call", async (event, ctx) => {
		const active = await recover(ctx.cwd);
		if (!active || active.stage === "done" || active.stage === "aborted") return;
		if (event.toolName === "edit" || event.toolName === "write") {
			return {
				block: true,
				reason: `BigTDD is active at ${active.stage}. The parent orchestrates; use bigtdd run_stage to delegate edits.`,
			};
		}
		if (event.toolName === "bash") {
			const command = String(event.input.command ?? "");
			if (/(?:^|[;&|\s])(git\s+(?:add|commit|switch|checkout|reset|restore|clean)|rm|mv|cp|touch|truncate|tee|sed\s+-i)(?:\s|$)|(?:^|[^<])>{1,2}/.test(command)) {
				return {
					block: true,
					reason: `BigTDD is active at ${active.stage}. Mutations and Git checkpoints belong to the workflow extension.`,
				};
			}
		}
	});

	pi.registerCommand("bigtdd", {
		description: "Start, resume, inspect, or abort a commit-per-stage multi-agent TDD workflow",
		handler: async (rawArgs, ctx) => {
			const args = rawArgs.trim();
			if (args === "status") {
				const active = await recover(ctx.cwd);
				ctx.ui.notify(active ? formatState(active) : "No BigTDD run found on this branch", "info");
				return;
			}
			if (args === "resume") {
				const active = await recover(ctx.cwd);
				if (!active || active.stage === "done" || active.stage === "aborted") {
					ctx.ui.notify("No active BigTDD run found on this branch", "warning");
					return;
				}
				await selectOrchestratorModel(ctx);
				pi.sendUserMessage("/skill:bigtdd", { expandPromptTemplates: true });
				return;
			}
			if (args === "abort") {
				const active = await recover(ctx.cwd);
				if (!active) {
					ctx.ui.notify("No BigTDD run found", "warning");
					return;
				}
				await ensureBranch(active);
				const reason = ctx.hasUI ? await ctx.ui.input("Abort BigTDD", "Reason (required)") : undefined;
				if (!reason?.trim()) {
					ctx.ui.notify("Abort cancelled; a reason is required", "info");
					return;
				}
				active.stage = "aborted";
				active.stageSequence++;
				active.history.push({ stage: "aborted", summary: reason.trim(), at: new Date().toISOString() });
				stageArtifact(active, "aborted", `# Workflow aborted\n\n${reason.trim()}\n`);
				await commitStage(pi, active, "aborted", reason.trim());
				ctx.ui.setStatus("bigtdd", undefined);
				return;
			}
			if (!args) {
				ctx.ui.notify("Usage: /bigtdd <request> | status | resume | abort", "info");
				return;
			}
			const existing = await recover(ctx.cwd);
			if (existing && existing.stage !== "done" && existing.stage !== "aborted") {
				ctx.ui.notify(`BigTDD ${existing.id} is already active at ${existing.stage}`, "warning");
				return;
			}
			try {
				const active = await initialize(args, ctx);
				ctx.ui.setStatus("bigtdd", ctx.ui.theme.fg("accent", `BigTDD: ${active.stage}`));
				pi.setSessionName(`BigTDD: ${slugify(args, 28)}`);
				pi.sendUserMessage("/skill:bigtdd", { expandPromptTemplates: true });
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
			}
		},
	});

	pi.registerTool({
		name: "bigtdd",
		label: "BigTDD",
		description:
			"Control the active BigTDD state machine: run the current specialist/gate, record a stage, ask a human, reopen locked tests with approval, or inspect status.",
		promptSnippet: "Advance an active branch-per-task, commit-per-stage TDD workflow",
		promptGuidelines: [
			"When [BIGTDD ACTIVE] is present, use bigtdd for all workflow stages and do not edit or commit from the parent session.",
			"Lean toward action=checkpoint when ambiguity, disagreement, test validity, compatibility, or scope would benefit from human feedback.",
		],
		parameters: ControlParams,
		executionMode: "sequential",
		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			try {
				const active = await recover(ctx.cwd);
				if (!active) return textResult("No BigTDD run is active. Start one with /bigtdd <request>.", {}, true);
				await ensureBranch(active);
				config ??= loadConfig(active.repoRoot);

				if (params.action === "status") {
					const pending = await loadPending(pi, active);
					return textResult(`${formatState(active)}\nPending evidence: ${pending ? pending.kind : "none"}`, {
						state: active,
						pending,
					});
				}

				if (params.action === "run_stage") {
					if (active.stage === "done" || active.stage === "aborted") {
						return textResult(`Workflow is ${active.stage}; no stage can be run.`, { state: active }, true);
					}
					if (active.stage === "contract") {
						return textResult(
							"The parent orchestrator owns the contract stage. Draft the Markdown contract, ask a checkpoint if needed, then call complete_stage with contract and summary.",
							{ state: active },
						);
					}
					await assertClean(pi, active.repoRoot);
					if (active.stage === "red" || active.stage === "verification") {
						const kind = active.stage;
						const command = kind === "red" ? active.testCommand : active.fullCommand;
						if (!command) return textResult(`No command is configured for ${kind}.`, { state: active }, true);
						const gate = await runGate(pi, active, kind, command, signal);
						const pending: PendingRun = { stage: active.stage, kind: "gate", gate };
						await savePending(pi, active, pending);
						return textResult(
							`${kind.toUpperCase()} gate ${gate.passed ? "passed" : "failed"} (exit ${gate.exitCode}).\n\n${bounded(gate.stdout || gate.stderr, 12_000)}`,
							{ state: active, pending },
							!gate.passed,
						);
					}
					const role = roleForStage(active.stage);
					if (!role) return textResult(`Stage ${active.stage} has no runnable specialist.`, { state: active }, true);
					const existing = await loadPending(pi, active);
					if (existing?.stage === active.stage && existing.kind === "agent") {
						const dirtyAttempt = existing.attempts.find((attempt) => attempt.changedFiles.length > 0);
						if (dirtyAttempt) {
							return textResult(
								`The ${role} stage already has uncommitted changes. Complete the stage before launching another agent.`,
								{ state: active, pending: existing },
								true,
							);
						}
					}
					const run = await runAgent(pi, active, config, role, buildTask(active, role, params.focus), signal, onUpdate);
					const attempts = existing?.stage === active.stage && existing.kind === "agent" ? [...existing.attempts, run] : [run];
					const pending: PendingRun = { stage: active.stage, kind: "agent", attempts };
					await savePending(pi, active, pending);
					const problems = [
						run.exitCode !== 0 ? `child exited ${run.exitCode}` : "",
						!run.report ? "no structured report" : "",
						run.testLockViolations.length > 0 ? `locked tests changed: ${run.testLockViolations.join(", ")}` : "",
					]
						.filter(Boolean)
						.join("; ");
					return textResult(
						`${role} ${problems ? `needs attention (${problems})` : `reported ${run.report?.verdict}`}.\n\n${run.report?.summary ?? run.output ?? run.stderr}`,
						{ state: active, pending },
						Boolean(problems),
					);
				}

				if (params.action === "checkpoint") {
					if (!params.question?.trim() || !params.recommendation?.trim()) {
						return textResult("checkpoint requires question and recommendation", { state: active }, true);
					}
					if (!ctx.hasUI) {
						return textResult(
							`Human feedback required at ${active.stage}, but this session has no interactive UI. Pause and ask externally.\n\n${params.question}`,
							{ state: active },
							true,
						);
					}
					const detail = [params.context?.trim(), `Recommendation: ${params.recommendation.trim()}`].filter(Boolean).join("\n\n");
					if (detail) ctx.ui.notify(detail, "info");
					const choice = await ctx.ui.select(params.question.trim(), [
						`Approve recommendation: ${params.recommendation.trim()}`,
						"Provide feedback",
						"Pause here",
					]);
					let checkpoint: HumanCheckpoint;
					if (choice?.startsWith("Approve")) {
						checkpoint = {
							stage: active.stage,
							question: params.question.trim(),
							recommendation: params.recommendation.trim(),
							outcome: "approved",
							at: new Date().toISOString(),
						};
					} else if (choice === "Provide feedback") {
						const feedback = await ctx.ui.editor(params.question.trim(), "");
						checkpoint = {
							stage: active.stage,
							question: params.question.trim(),
							recommendation: params.recommendation.trim(),
							outcome: "feedback",
							feedback: feedback?.trim() || "No feedback entered",
							at: new Date().toISOString(),
						};
					} else {
						checkpoint = {
							stage: active.stage,
							question: params.question.trim(),
							recommendation: params.recommendation.trim(),
							outcome: "paused",
							at: new Date().toISOString(),
						};
					}
					active.latestCheckpoint = checkpoint;
					pi.appendEntry("bigtdd-checkpoint", checkpoint);
					return textResult(
						checkpoint.outcome === "feedback"
							? `Human feedback:\n${checkpoint.feedback}`
							: `Human checkpoint: ${checkpoint.outcome}`,
						{ state: active, checkpoint },
					);
				}

				if (params.action === "unlock_tests") {
					if (active.testPaths.length === 0 || Object.keys(active.lockedTestHashes).length === 0) {
						return textResult("Tests are not locked yet.", { state: active }, true);
					}
					if (!["implementation", "feature_review", "feature_refinement", "verification"].includes(active.stage)) {
						return textResult(`Tests cannot be reopened from ${active.stage}.`, { state: active }, true);
					}
					if (!params.reason?.trim() || !params.approvalSource) {
						return textResult("unlock_tests requires reason and approvalSource", { state: active }, true);
					}
					await assertClean(pi, active.repoRoot);
					let approved = false;
					if (ctx.hasUI && config.requireHumanForTestUnlock) {
						approved = await ctx.ui.confirm(
							"Reopen locked tests?",
							`Stage: ${active.stage}\nReason: ${params.reason.trim()}\nProposed by: ${params.approvalSource}\nEvidence: ${params.approvalEvidence ?? "none"}\n\nThis starts a fresh test-refinement → review → RED cycle.`,
						);
					} else if (params.approvalSource === "independent-reviewer" && params.approvalEvidence?.trim()) {
						approved = true;
					} else if (params.approvalSource === "main-agent" && config.allowMainAgentTestUnlockWithoutUI) {
						approved = true;
					} else if (params.approvalSource === "human") {
						approved = checkpointApproved(active);
					}
					if (!approved) return textResult("Test unlock was not approved. Locked tests remain immutable.", { state: active }, true);
					await clearPending(pi, active);
					active.stage = "test_refinement";
					active.testUnlocks++;
					active.stageSequence++;
					const summary = `${params.reason.trim()} (approved by ${params.approvalSource})`;
					active.history.push({ stage: "test_unlock", summary, at: new Date().toISOString() });
					stageArtifact(
						active,
						"test_unlock",
						`# Test lock reopened\n\n- Prior stage: ${active.history.at(-2)?.stage ?? "unknown"}\n- Approval source: ${params.approvalSource}\n- Reason: ${params.reason.trim()}\n\n## Evidence\n\n${params.approvalEvidence?.trim() || "Human confirmation in Pi UI."}\n`,
					);
					const commit = await commitStage(pi, active, "test_unlock", summary);
					pi.appendEntry("bigtdd-state", active);
					ctx.ui.setStatus("bigtdd", ctx.ui.theme.fg("accent", `BigTDD: ${active.stage}`));
					return textResult(`Locked tests reopened in ${commit.slice(0, 10)}. Run a fresh test-refinement stage.`, {
						state: active,
					});
				}

				if (params.action === "abort") {
					if (!params.reason?.trim()) return textResult("abort requires a reason", { state: active }, true);
					active.stage = "aborted";
					active.stageSequence++;
					active.history.push({ stage: "aborted", summary: params.reason.trim(), at: new Date().toISOString() });
					stageArtifact(active, "aborted", `# Workflow aborted\n\n${params.reason.trim()}\n`);
					await commitStage(pi, active, "aborted", params.reason.trim());
					await clearPending(pi, active);
					ctx.ui.setStatus("bigtdd", undefined);
					return textResult("BigTDD workflow aborted. The branch and stage history were preserved.", { state: active });
				}

				if (params.action === "complete_stage") {
					if (!params.summary?.trim() || !params.decision) {
						return textResult("complete_stage requires summary and decision", { state: active }, true);
					}
					const completedStage = active.stage;
					if (completedStage === "done" || completedStage === "aborted") {
						return textResult(`Workflow is already ${completedStage}.`, { state: active }, true);
					}
					const pending = await loadPending(pi, active);
					if (completedStage !== "contract" && (!pending || pending.stage !== completedStage)) {
						return textResult(`Run the ${completedStage} stage before completing it.`, { state: active }, true);
					}

					const lastAttempt = pending?.kind === "agent" ? pending.attempts.at(-1) : undefined;
					const report = lastAttempt?.report;
					if (pending?.kind === "agent" && (lastAttempt?.exitCode !== 0 || !report) && !checkpointResolved(active)) {
						return textResult("The latest specialist did not finish successfully with a structured report.", { state: active, pending }, true);
					}
					if (lastAttempt?.testLockViolations.length) {
						return textResult(
							`Locked tests changed: ${lastAttempt.testLockViolations.join(", ")}. Restore them before completing this stage; use unlock_tests only from a clean committed stage.`,
							{ state: active, pending },
							true,
						);
					}
					if (
						report?.verdict === "needs_human" &&
						(params.decision === "advance" ? !checkpointApproved(active) : !checkpointResolved(active))
					) {
						return textResult("The specialist requested human input. Resolve it with checkpoint before completing.", { state: active, pending }, true);
					}
					if (requiresPassingReport(completedStage) && params.decision === "advance" && report?.verdict !== "pass" && !checkpointApproved(active)) {
						return textResult(`The ${completedStage} reviewer did not pass. Refine or obtain explicit human approval.`, { state: active, pending }, true);
					}

					if (completedStage === "contract") {
						if (!params.contract?.trim()) return textResult("contract stage requires contract Markdown", { state: active }, true);
						if (config.humanCheckpoints === "always-contract" && !checkpointApproved(active)) {
							return textResult("Configuration requires a human-approved contract checkpoint.", { state: active }, true);
						}
					}

					const actualChanges = await changedFiles(pi, active.repoRoot);
					if (
						pending?.kind === "gate" &&
						pending.gate.changedFiles.length > 0 &&
						!(params.allowUnexpectedChanges && checkpointApproved(active))
					) {
						return textResult(
							`The gate command modified the worktree: ${pending.gate.changedFiles.join(", ")}. Restore the generated changes or obtain human approval before committing them.`,
							{ state: active, pending },
							true,
						);
					}
					let testPaths = params.testPaths ?? report?.testPaths ?? active.testPaths;
					if (completedStage === "tests" || completedStage === "test_refinement") {
						testPaths = normalizeTestPaths(active.repoRoot, testPaths);
						if (testPaths.length === 0) return textResult("A test-writing stage must declare at least one test path.", { state: active }, true);
						const allowed = new Set(testPaths);
						const unexpected = actualChanges.filter((file) => !allowed.has(normalizeRepoPath(active.repoRoot, file)));
						if (unexpected.length > 0 && !(params.allowUnexpectedChanges && checkpointApproved(active))) {
							return textResult(
								`Test stage changed non-test paths: ${unexpected.join(", ")}. Revert them or obtain a human checkpoint and set allowUnexpectedChanges.`,
								{ state: active, pending },
								true,
							);
						}
						const testCommand = params.testCommand?.trim() || report?.testCommand?.trim() || active.testCommand;
						const fullCommand = params.fullCommand?.trim() || report?.fullCommand?.trim() || active.fullCommand;
						if (!testCommand || !fullCommand) {
							return textResult("Test stage must establish both testCommand and fullCommand.", { state: active, pending }, true);
						}
						active.testPaths = testPaths;
						active.testCommand = testCommand;
						active.fullCommand = fullCommand;
					}

					if (isReviewStage(completedStage) && actualChanges.length > 0) {
						return textResult(`Read-only reviewer changed files: ${actualChanges.join(", ")}`, { state: active, pending }, true);
					}
					if (isWriterStage(completedStage) && completedStage !== "tests" && completedStage !== "test_refinement") {
						const currentHashes = await fileHashes(pi, active.repoRoot, active.testPaths);
						const violations = hashDifferences(active.lockedTestHashes, currentHashes);
						if (violations.length > 0) {
							return textResult(`Locked tests changed: ${violations.join(", ")}`, { state: active, pending }, true);
						}
					}

					if (completedStage === "red") {
						if (pending?.kind !== "gate") return textResult("RED requires gate evidence.", { state: active }, true);
						const validRed = pending.gate.passed && params.redFailureMatchesContract === true;
						if (!validRed && !(params.waiveRed && checkpointApproved(active))) {
							return textResult(
								"RED is not established. The command must fail for the intended missing behavior, or a human must explicitly approve a recorded waiver.",
								{ state: active, pending },
								true,
							);
						}
						active.lockedTestHashes = await fileHashes(pi, active.repoRoot, active.testPaths);
					}

					if (completedStage === "verification") {
						if (params.decision === "advance") {
							if (pending?.kind !== "gate" || !pending.gate.passed) {
								return textResult("Full verification must pass before completion.", { state: active, pending }, true);
							}
							const currentHashes = await fileHashes(pi, active.repoRoot, active.testPaths);
							const violations = hashDifferences(active.lockedTestHashes, currentHashes);
							if (violations.length > 0) {
								return textResult(`Verification found changed locked tests: ${violations.join(", ")}`, { state: active, pending }, true);
							}
						}
					}

					const next = nextStage(completedStage, params.decision);
					if (completedStage === "test_refinement") active.testRefinements++;
					if (completedStage === "feature_refinement") active.featureRefinements++;
					if (completedStage === "implementation") active.implementationCommitted = true;
					active.stage = next;
					active.stageSequence++;
					const summary = params.summary.trim();
					active.history.push({ stage: completedStage, summary, at: new Date().toISOString() });
					const contractSection = completedStage === "contract" ? `\n\n## Accepted contract\n\n${params.contract!.trim()}` : "";
					const checkpointSection = active.latestCheckpoint?.stage === completedStage
						? `\n\n## Human checkpoint\n\n${JSON.stringify(active.latestCheckpoint, null, 2)}`
						: "";
					stageArtifact(
						active,
						completedStage,
						`# BigTDD stage: ${completedStage}\n\nDecision: **${params.decision}**\n\n## Orchestrator summary\n\n${summary}${contractSection}${checkpointSection}\n\n## Evidence\n\n${pendingMarkdown(pending)}\n`,
					);
					const commit = await commitStage(pi, active, completedStage, summary);
					await clearPending(pi, active);
					active.latestCheckpoint = undefined;
					pi.appendEntry("bigtdd-state", active);
					if (next === "done") ctx.ui.setStatus("bigtdd", undefined);
					else ctx.ui.setStatus("bigtdd", ctx.ui.theme.fg("accent", `BigTDD: ${next}`));
					return textResult(
						next === "done"
							? `BigTDD complete on ${active.branch}. Verification evidence committed as ${commit.slice(0, 10)}.`
							: `Committed ${completedStage} as ${commit.slice(0, 10)}. Next stage: ${next}.`,
						{ state: active, commit },
					);
				}

				return textResult(`Unsupported action: ${params.action}`, { state: active }, true);
			} catch (error) {
				return textResult(error instanceof Error ? error.message : String(error), { state }, true);
			}
		},
	});
}
