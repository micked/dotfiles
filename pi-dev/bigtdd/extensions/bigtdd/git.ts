import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { commitSubject, normalizeRepoPath, timestampId } from "./core.ts";
import type { BigTddConfig, BigTddState, PendingRun, Stage } from "./types.ts";

export interface GitContext {
	repoRoot: string;
	branch: string;
	head: string;
}

async function checked(pi: ExtensionAPI, args: string[], cwd: string): Promise<string> {
	const result = await pi.exec("git", args, { cwd });
	if (result.code !== 0) throw new Error(result.stderr.trim() || `git ${args[0]} failed`);
	return result.stdout.trim();
}

export async function inspectGit(pi: ExtensionAPI, cwd: string): Promise<GitContext> {
	const repoRoot = await checked(pi, ["rev-parse", "--show-toplevel"], cwd);
	const branch = await checked(pi, ["symbolic-ref", "--quiet", "--short", "HEAD"], repoRoot);
	const head = await checked(pi, ["rev-parse", "HEAD"], repoRoot);
	return { repoRoot, branch, head };
}

export async function changedFiles(pi: ExtensionAPI, repoRoot: string): Promise<string[]> {
	const output = await checked(pi, ["status", "--porcelain=v1", "-z", "--untracked-files=all"], repoRoot);
	if (!output) return [];
	const fields = output.split("\0").filter(Boolean);
	const files: string[] = [];
	for (let i = 0; i < fields.length; i++) {
		const field = fields[i];
		const status = field.slice(0, 2);
		const file = field.slice(3);
		if (file) files.push(file);
		if ((status.startsWith("R") || status.startsWith("C")) && fields[i + 1]) files.push(fields[++i]);
	}
	return [...new Set(files)].sort();
}

export async function assertClean(pi: ExtensionAPI, repoRoot: string): Promise<void> {
	const files = await changedFiles(pi, repoRoot);
	if (files.length > 0) throw new Error(`BigTDD requires a clean worktree. Commit or stash first:\n${files.join("\n")}`);
}

export async function createWorkflowBranch(
	pi: ExtensionAPI,
	git: GitContext,
	config: BigTddConfig,
	requestSlug: string,
	clock = new Date(),
): Promise<string> {
	const base = `${config.branchPrefix}${requestSlug}-${timestampId(clock)}`;
	let branch = base;
	let suffix = 2;
	while ((await pi.exec("git", ["show-ref", "--verify", "--quiet", `refs/heads/${branch}`], { cwd: git.repoRoot })).code === 0) {
		branch = `${base}-${suffix++}`;
	}
	await checked(pi, ["switch", "-c", branch], git.repoRoot);
	return branch;
}

export function statePath(state: BigTddState): string {
	return path.join(state.repoRoot, state.artifactDir, "state.json");
}

export function writeState(state: BigTddState): void {
	state.updatedAt = new Date().toISOString();
	const target = statePath(state);
	fs.mkdirSync(path.dirname(target), { recursive: true });
	const temporary = `${target}.tmp`;
	fs.writeFileSync(temporary, `${JSON.stringify(state, null, 2)}\n`, { encoding: "utf8", mode: 0o600 });
	fs.renameSync(temporary, target);
}

export function writeArtifact(state: BigTddState, name: string, body: string): string {
	const safeName = name.replace(/[^a-zA-Z0-9_.-]+/g, "-");
	const relative = path.posix.join(state.artifactDir, safeName);
	const target = path.join(state.repoRoot, relative);
	fs.mkdirSync(path.dirname(target), { recursive: true });
	fs.writeFileSync(target, body.endsWith("\n") ? body : `${body}\n`, "utf8");
	return relative;
}

export async function commitStage(
	pi: ExtensionAPI,
	state: BigTddState,
	completedStage: Stage | "intake" | "test_unlock",
	_summary: string,
): Promise<string> {
	writeState(state);
	await checked(pi, ["add", "-A", "--", "."], state.repoRoot);
	await checked(pi, ["add", "-f", "--", state.artifactDir], state.repoRoot);
	const staged = await checked(pi, ["diff", "--cached", "--name-only"], state.repoRoot);
	if (!staged) throw new Error(`Nothing was staged for ${completedStage}; refusing an empty stage commit`);
	await checked(pi, ["commit", "-m", commitSubject(state, completedStage)], state.repoRoot);
	const commit = await checked(pi, ["rev-parse", "HEAD"], state.repoRoot);
	return commit;
}

export async function currentBranch(pi: ExtensionAPI, repoRoot: string): Promise<string> {
	return checked(pi, ["symbolic-ref", "--quiet", "--short", "HEAD"], repoRoot);
}

export async function fileHashes(
	pi: ExtensionAPI,
	repoRoot: string,
	paths: string[],
): Promise<Record<string, string>> {
	const hashes: Record<string, string> = {};
	for (const candidate of paths) {
		const relative = normalizeRepoPath(repoRoot, candidate);
		const absolute = path.join(repoRoot, relative);
		if (!fs.existsSync(absolute) || !fs.statSync(absolute).isFile()) {
			hashes[relative] = "<missing>";
			continue;
		}
		hashes[relative] = await checked(pi, ["hash-object", "--", relative], repoRoot);
	}
	return hashes;
}

export function hashDifferences(before: Record<string, string>, after: Record<string, string>): string[] {
	return [...new Set([...Object.keys(before), ...Object.keys(after)])]
		.filter((key) => before[key] !== after[key])
		.sort();
}

export async function pendingPath(pi: ExtensionAPI, state: BigTddState): Promise<string> {
	const gitPath = await checked(pi, ["rev-parse", "--git-path", "bigtdd"], state.repoRoot);
	const base = path.isAbsolute(gitPath) ? gitPath : path.join(state.repoRoot, gitPath);
	fs.mkdirSync(base, { recursive: true });
	return path.join(base, `pending-${state.id}.json`);
}

export async function savePending(pi: ExtensionAPI, state: BigTddState, pending: PendingRun): Promise<void> {
	fs.writeFileSync(await pendingPath(pi, state), `${JSON.stringify(pending, null, 2)}\n`, { mode: 0o600 });
}

export async function loadPending(pi: ExtensionAPI, state: BigTddState): Promise<PendingRun | undefined> {
	try {
		return JSON.parse(fs.readFileSync(await pendingPath(pi, state), "utf8")) as PendingRun;
	} catch {
		return undefined;
	}
}

export async function clearPending(pi: ExtensionAPI, state: BigTddState): Promise<void> {
	try {
		fs.unlinkSync(await pendingPath(pi, state));
	} catch {
		// No pending run is a valid state.
	}
}

export function loadStateFromRepo(repoRoot: string, artifactDirectory: string): BigTddState | undefined {
	const root = path.join(repoRoot, artifactDirectory);
	if (!fs.existsSync(root)) return undefined;
	const candidates = fs
		.readdirSync(root, { withFileTypes: true })
		.filter((entry) => entry.isDirectory())
		.map((entry) => path.join(root, entry.name, "state.json"))
		.filter((candidate) => fs.existsSync(candidate))
		.map((candidate) => {
			try {
				return JSON.parse(fs.readFileSync(candidate, "utf8")) as BigTddState;
			} catch {
				return undefined;
			}
		})
		.filter((state): state is BigTddState => Boolean(state))
		.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
	return candidates.find((state) => state.stage !== "done" && state.stage !== "aborted") ?? candidates[0];
}
