import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import type { BigTddConfig } from "./types.ts";

const DEFAULTS: BigTddConfig = {
	branchPrefix: "bigtdd/",
	artifactDirectory: ".bigtdd",
	agentTimeoutMinutes: 30,
	humanCheckpoints: "agent-decides",
	requireHumanForTestUnlock: true,
	allowMainAgentTestUnlockWithoutUI: false,
	models: {},
	thinking: {},
};

function readJson(filePath: string): Record<string, unknown> | undefined {
	try {
		return JSON.parse(fs.readFileSync(filePath, "utf8")) as Record<string, unknown>;
	} catch {
		return undefined;
	}
}

function mergeConfig(base: BigTddConfig, raw?: Record<string, unknown>): BigTddConfig {
	if (!raw) return base;
	const models = typeof raw.models === "object" && raw.models ? raw.models : {};
	const thinking = typeof raw.thinking === "object" && raw.thinking ? raw.thinking : {};
	return {
		...base,
		...raw,
		models: { ...base.models, ...(models as BigTddConfig["models"]) },
		thinking: { ...base.thinking, ...(thinking as BigTddConfig["thinking"]) },
	} as BigTddConfig;
}

export function loadConfig(repoRoot: string): BigTddConfig {
	const packageRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
	let config = mergeConfig(DEFAULTS, readJson(path.join(packageRoot, "config.json")));
	config = mergeConfig(config, readJson(path.join(os.homedir(), ".pi", "agent", "bigtdd.json")));
	config = mergeConfig(config, readJson(path.join(repoRoot, ".pi", "bigtdd.json")));

	if (!config.branchPrefix || /\s/.test(config.branchPrefix)) throw new Error("Invalid BigTDD branchPrefix");
	if (!config.artifactDirectory || path.isAbsolute(config.artifactDirectory)) {
		throw new Error("BigTDD artifactDirectory must be repository-relative");
	}
	const artifactPath = path.resolve(repoRoot, config.artifactDirectory);
	const artifactRelative = path.relative(repoRoot, artifactPath);
	if (artifactRelative.startsWith("..") || path.isAbsolute(artifactRelative) || artifactRelative === "") {
		throw new Error("BigTDD artifactDirectory must be a directory inside the repository");
	}
	if (!Number.isFinite(config.agentTimeoutMinutes) || config.agentTimeoutMinutes <= 0) {
		throw new Error("BigTDD agentTimeoutMinutes must be positive");
	}
	if (config.models.testAuthor && config.models.testAuthor === config.models.testReviewer) {
		throw new Error("BigTDD testAuthor and testReviewer must use different models");
	}
	if (config.models.implementer && config.models.implementer === config.models.featureReviewer) {
		throw new Error("BigTDD implementer and featureReviewer must use different models");
	}
	return config;
}
