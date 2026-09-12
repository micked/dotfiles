import * as path from "node:path";
import type { AgentRole, BigTddState, Stage } from "./types.ts";

const ROLE_BY_STAGE: Partial<Record<Stage, AgentRole>> = {
	recon: "scout",
	tests: "testAuthor",
	test_review: "testReviewer",
	test_refinement: "testRefiner",
	implementation: "implementer",
	feature_review: "featureReviewer",
	feature_refinement: "featureRefiner",
};

export function roleForStage(stage: Stage): AgentRole | undefined {
	return ROLE_BY_STAGE[stage];
}

export function nextStage(stage: Stage, decision: "advance" | "refine"): Stage {
	if (decision === "refine") {
		if (stage === "tests" || stage === "test_review" || stage === "test_refinement" || stage === "red") {
			return "test_refinement";
		}
		if (
			stage === "implementation" ||
			stage === "feature_review" ||
			stage === "feature_refinement" ||
			stage === "verification"
		) {
			return "feature_refinement";
		}
		throw new Error(`Stage ${stage} cannot be refined`);
	}

	switch (stage) {
		case "recon":
			return "contract";
		case "contract":
			return "tests";
		case "tests":
		case "test_refinement":
			return "test_review";
		case "test_review":
			return "red";
		case "red":
			return "implementation";
		case "implementation":
			return "feature_review";
		case "feature_refinement":
			return "feature_review";
		case "feature_review":
			return "verification";
		case "verification":
			return "done";
		default:
			throw new Error(`Stage ${stage} cannot advance`);
	}
}

export function slugify(value: string, maxLength = 36): string {
	const slug = value
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-+|-+$/g, "")
		.slice(0, maxLength)
		.replace(/-+$/g, "");
	return slug || "change";
}

export function timestampId(date = new Date()): string {
	const pad = (n: number) => String(n).padStart(2, "0");
	return [
		date.getFullYear(),
		pad(date.getMonth() + 1),
		pad(date.getDate()),
		"-",
		pad(date.getHours()),
		pad(date.getMinutes()),
		pad(date.getSeconds()),
	].join("");
}

export function normalizeRepoPath(repoRoot: string, candidate: string): string {
	if (!candidate.trim()) throw new Error("Path cannot be empty");
	const absolute = path.resolve(repoRoot, candidate);
	const relative = path.relative(repoRoot, absolute);
	if (relative === "" || relative.startsWith("..") || path.isAbsolute(relative)) {
		throw new Error(`Path must name a file inside the repository: ${candidate}`);
	}
	return relative.split(path.sep).join("/");
}

export function normalizeTestPaths(repoRoot: string, candidates: string[]): string[] {
	return [...new Set(candidates.map((candidate) => normalizeRepoPath(repoRoot, candidate)))].sort();
}

export function stageLabel(stage: Stage | "intake" | "test_unlock"): string {
	return stage.replaceAll("_", "-");
}

export function commitSubject(state: BigTddState, completedStage: Stage | "intake" | "test_unlock"): string {
	const subject = slugify(state.request, 52).replaceAll("-", " ");
	if (completedStage === "tests" || completedStage === "test_refinement") {
		return `test(bigtdd): ${stageLabel(completedStage)} for ${subject}`;
	}
	if (completedStage === "implementation" || completedStage === "feature_refinement") {
		return `feat(bigtdd): ${stageLabel(completedStage)} for ${subject}`;
	}
	return `bigtdd(${stageLabel(completedStage)}): ${subject}`;
}

export function isReviewStage(stage: Stage): boolean {
	return stage === "test_review" || stage === "feature_review";
}

export function isWriterStage(stage: Stage): boolean {
	return ["tests", "test_refinement", "implementation", "feature_refinement"].includes(stage);
}

export function requiresPassingReport(stage: Stage): boolean {
	return stage === "test_review" || stage === "feature_review";
}

export function formatState(state: BigTddState): string {
	const tests = state.testPaths.length > 0 ? state.testPaths.join(", ") : "not locked yet";
	return [
		`BigTDD ${state.id}`,
		`Stage: ${state.stage}`,
		`Branch: ${state.branch} (from ${state.baseBranch}@${state.baseCommit.slice(0, 10)})`,
		`Stage commits: ${state.history.length}`,
		`Tests: ${tests}`,
		`Test command: ${state.testCommand ?? "not set"}`,
		`Full verification: ${state.fullCommand ?? "not set"}`,
	].join("\n");
}

export function bounded(text: string, maxBytes = 64 * 1024): string {
	const source = text || "";
	if (Buffer.byteLength(source, "utf8") <= maxBytes) return source;
	let result = source.slice(0, maxBytes);
	while (Buffer.byteLength(result, "utf8") > maxBytes) result = result.slice(0, -1);
	return `${result}\n\n[truncated by BigTDD]`;
}
