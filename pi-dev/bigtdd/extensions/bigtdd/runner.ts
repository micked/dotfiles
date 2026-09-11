import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import type { AgentToolResult, ThinkingLevel } from "@earendil-works/pi-agent-core";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { bounded } from "./core.ts";
import { changedFiles, fileHashes, hashDifferences } from "./git.ts";
import type { AgentReport, AgentRole, AgentRun, BigTddConfig, BigTddState, GateRun } from "./types.ts";

type Update = (result: AgentToolResult<unknown>) => void;

const ROLE_FILE: Record<AgentRole, string> = {
	scout: "scout.md",
	testAuthor: "test-author.md",
	testReviewer: "test-reviewer.md",
	testRefiner: "test-refiner.md",
	implementer: "implementer.md",
	featureReviewer: "feature-reviewer.md",
	featureRefiner: "feature-refiner.md",
};

function packageRoot(): string {
	return path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
}

function extensionPath(): string {
	return fileURLToPath(import.meta.url).replace(/runner\.ts$/, "index.ts");
}

function getPiInvocation(args: string[]): { command: string; args: string[] } {
	const currentScript = process.argv[1];
	const bunVirtual = currentScript?.startsWith("/$bunfs/root/");
	if (currentScript && !bunVirtual && fs.existsSync(currentScript)) {
		return { command: process.execPath, args: [currentScript, ...args] };
	}
	const executable = path.basename(process.execPath).toLowerCase();
	return /^(node|bun)(\.exe)?$/.test(executable) ? { command: "pi", args } : { command: process.execPath, args };
}

function reportFromMessage(message: any): AgentReport | undefined {
	if (message?.role !== "assistant" || !Array.isArray(message.content)) return undefined;
	for (const part of message.content) {
		if (part?.type !== "toolCall" || part.name !== "bigtdd_report") continue;
		const value = part.arguments as Partial<AgentReport> | undefined;
		if (
			!value ||
			(value.verdict !== "pass" && value.verdict !== "fail" && value.verdict !== "needs_human") ||
			typeof value.summary !== "string" ||
			!Array.isArray(value.findings) ||
			!value.findings.every((item) => typeof item === "string") ||
			!Array.isArray(value.changedFiles) ||
			!value.changedFiles.every((item) => typeof item === "string") ||
			!Array.isArray(value.testPaths) ||
			!value.testPaths.every((item) => typeof item === "string")
		) {
			continue;
		}
		return value as AgentReport;
	}
	return undefined;
}

function textFromMessage(message: any): string {
	if (message?.role !== "assistant" || !Array.isArray(message.content)) return "";
	return message.content
		.filter((part: any) => part?.type === "text")
		.map((part: any) => part.text)
		.join("\n");
}

export async function runAgent(
	pi: ExtensionAPI,
	state: BigTddState,
	config: BigTddConfig,
	role: AgentRole,
	task: string,
	signal?: AbortSignal,
	onUpdate?: Update,
): Promise<AgentRun> {
	const startedAt = new Date().toISOString();
	const beforeFiles = await changedFiles(pi, state.repoRoot);
	if (beforeFiles.length > 0) throw new Error(`Cannot launch ${role} with a dirty worktree:\n${beforeFiles.join("\n")}`);
	const beforeHashes = await fileHashes(pi, state.repoRoot, state.testPaths);
	const prompt = fs.readFileSync(path.join(packageRoot(), "agents", ROLE_FILE[role]), "utf8");
	const promptDir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-bigtdd-"));
	const promptPath = path.join(promptDir, `${role}.md`);
	fs.writeFileSync(promptPath, prompt, { encoding: "utf8", mode: 0o600 });

	const args = [
		"--mode",
		"json",
		"-p",
		"--no-session",
		"--no-extensions",
		"--extension",
		extensionPath(),
		"--no-skills",
		"--no-prompt-templates",
		"--append-system-prompt",
		promptPath,
	];
	const model = config.models[role];
	if (model) args.push("--model", model);
	const thinking = config.thinking[role] as ThinkingLevel | undefined;
	if (thinking) args.push("--thinking", thinking);
	const readOnly = role === "scout" || role === "testReviewer" || role === "featureReviewer";
	args.push("--tools", readOnly ? "read,grep,find,ls,bigtdd_report" : "read,bash,edit,write,grep,find,ls,bigtdd_report");
	args.push(`Task: ${task}`);

	let output = "";
	let stderr = "";
	let report: AgentReport | undefined;
	let timedOut = false;
	try {
		const invocation = getPiInvocation(args);
		const exitCode = await new Promise<number>((resolve) => {
			const child = spawn(invocation.command, invocation.args, {
				cwd: state.repoRoot,
				shell: false,
				stdio: ["ignore", "pipe", "pipe"],
				env: {
					...process.env,
					BIGTDD_CHILD: "1",
					BIGTDD_CHILD_ROLE: role,
					BIGTDD_REPO_ROOT: state.repoRoot,
					BIGTDD_LOCKED_TESTS: JSON.stringify(state.testPaths),
				},
			});
			let buffer = "";
			const processLine = (line: string) => {
				if (!line.trim()) return;
				try {
					const event = JSON.parse(line);
					if (event.type === "message_end" && event.message) {
						const text = textFromMessage(event.message);
						if (text) output = `${output}\n${text}`.trim();
						report = reportFromMessage(event.message) ?? report;
						onUpdate?.({
							content: [
								{ type: "text", text: report?.summary ?? (bounded(output, 4_000) || `${role} is working…`) },
							],
							details: { role, model },
						});
					}
				} catch {
					// Pi's JSON mode may coexist with diagnostics. stderr captures actionable errors.
				}
			};
			child.stdout.on("data", (data) => {
				buffer += data.toString();
				const lines = buffer.split("\n");
				buffer = lines.pop() ?? "";
				for (const line of lines) processLine(line);
			});
			child.stderr.on("data", (data) => (stderr += data.toString()));
			child.on("error", (error) => {
				stderr += `\n${error.message}`;
				resolve(1);
			});
			child.on("close", (code) => {
				if (buffer.trim()) processLine(buffer);
				resolve(code ?? 1);
			});
			const timeout = setTimeout(() => {
				timedOut = true;
				child.kill("SIGTERM");
				setTimeout(() => child.kill("SIGKILL"), 5_000).unref();
			}, config.agentTimeoutMinutes * 60_000);
			timeout.unref();
			const abort = () => child.kill("SIGTERM");
			if (signal?.aborted) abort();
			else signal?.addEventListener("abort", abort, { once: true });
			child.on("close", () => {
				clearTimeout(timeout);
				signal?.removeEventListener("abort", abort);
			});
		});

		const afterHashes = await fileHashes(pi, state.repoRoot, state.testPaths);
		return {
			role,
			model,
			exitCode: timedOut ? 124 : exitCode,
			output: bounded(output),
			stderr: bounded(stderr),
			report,
			changedFiles: await changedFiles(pi, state.repoRoot),
			testLockViolations: hashDifferences(beforeHashes, afterHashes),
			startedAt,
			finishedAt: new Date().toISOString(),
		};
	} finally {
		try {
			fs.unlinkSync(promptPath);
			fs.rmdirSync(promptDir);
		} catch {
			// Temporary cleanup is best-effort.
		}
	}
}

export async function runGate(
	pi: ExtensionAPI,
	state: BigTddState,
	kind: "red" | "verification",
	command: string,
	signal?: AbortSignal,
): Promise<GateRun> {
	const startedAt = new Date().toISOString();
	let cwd = state.repoRoot;
	let cleanup: (() => Promise<void>) | undefined;
	let preparationError: { code: number; stdout: string; stderr: string; killed: boolean } | undefined;

	if (kind === "red" && state.implementationCommitted) {
		const container = fs.mkdtempSync(path.join(os.tmpdir(), "pi-bigtdd-red-"));
		const worktree = path.join(container, "baseline");
		const patchPath = path.join(container, "tests.patch");
		cleanup = async () => {
			await pi.exec("git", ["worktree", "remove", "--force", worktree], { cwd: state.repoRoot });
			fs.rmSync(container, { recursive: true, force: true });
		};
		const add = await pi.exec("git", ["worktree", "add", "--detach", worktree, state.baseCommit], {
			cwd: state.repoRoot,
			signal,
			timeout: 2 * 60_000,
		});
		if (add.code !== 0) {
			preparationError = add;
		} else {
			const diff = await pi.exec("git", ["diff", "--binary", state.baseCommit, "HEAD", "--", ...state.testPaths], {
				cwd: state.repoRoot,
				signal,
				timeout: 2 * 60_000,
			});
			if (diff.code !== 0) {
				preparationError = diff;
			} else {
				fs.writeFileSync(patchPath, diff.stdout, "utf8");
				const apply = await pi.exec("git", ["apply", "--whitespace=nowarn", patchPath], {
					cwd: worktree,
					signal,
					timeout: 2 * 60_000,
				});
				if (apply.code !== 0) preparationError = apply;
				else cwd = worktree;
			}
		}
	}

	const result = preparationError ?? (await pi.exec("sh", ["-lc", command], { cwd, signal, timeout: 30 * 60_000 }));
	await cleanup?.();
	return {
		kind,
		command,
		cwd,
		exitCode: result.code,
		stdout: bounded(result.stdout),
		stderr: bounded(result.stderr),
		timedOut: result.killed,
		passed:
			!preparationError && (kind === "red" ? result.code !== 0 && !result.killed : result.code === 0 && !result.killed),
		changedFiles: await changedFiles(pi, state.repoRoot),
		startedAt,
		finishedAt: new Date().toISOString(),
	};
}

export function buildTask(state: BigTddState, role: AgentRole, focus?: string): string {
	const common = [
		`Original request:\n${state.request}`,
		`Repository: ${state.repoRoot}`,
		`Workflow evidence: ${state.artifactDir}`,
		`Current stage: ${state.stage}`,
		focus ? `Additional focus from the orchestrator:\n${focus}` : "",
	]
		.filter(Boolean)
		.join("\n\n");
	const tasks: Record<AgentRole, string> = {
		scout: "Inspect the relevant implementation and tests. Return a compressed, evidence-based brief for a stronger orchestrator. Do not modify anything.",
		testAuthor:
			"Read the accepted contract and recon artifacts. Add tests only, before production code. Determine the narrow test command and the full verification command. Do not change production code.",
		testReviewer:
			"Independently audit the tests against the original request and accepted contract. Look for missing behavior, tautologies, overfitting, mocks that bypass real behavior, and accidental API invention. Do not edit files.",
		testRefiner:
			"Make only the approved test corrections. Preserve valid coverage and do not touch production code. This is a fresh refinement pass, not permission to make the feature easier.",
		implementer:
			"Implement the accepted contract against the locked tests. Do not edit, delete, rename, bypass, or weaken locked tests. Keep the change scoped and run relevant checks.",
		featureReviewer:
			"Independently review the implementation against the original request, contract, locked tests, and complete branch diff. Check regressions, security, edge cases, and unnecessary complexity. Do not edit files.",
		featureRefiner:
			"Apply only accepted feature-review findings. Do not modify locked tests. Keep changes minimal and run relevant checks.",
	};
	return `${common}\n\nAssignment:\n${tasks[role]}`;
}
