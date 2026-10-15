// Open OpenCode-created Git worktrees as Herdr worktree workspaces so they show
// up in Herdr's sidebar without a manual `herdr worktree open`.
//
// Herdr already enumerates every Git worktree of a repository; it only keeps a
// worktree out of the sidebar until it is opened. On each `worktree.updated`
// event this reconciles Herdr's inventory for the changed repository and opens
// the linked worktrees that are not open yet.
//
// Auto-loaded from the global plugins directory. Dependency-free: the documented
// `Plugin.define({ id, setup })` is an identity helper, so a plain object with
// the same shape is equivalent (see @opencode/plugin's plugin.d.ts).

import { execFile } from "node:child_process";

const SOURCE = "opencode:herdr-worktree-open";
const HERDR_TIMEOUT_MS = 5_000;
const RECONCILE_DEBOUNCE_MS = 500;
// The service may be started with a PATH that lacks the package manager's bin
// directory, so fall back to the usual Herdr install locations: Homebrew on
// macOS, and the herdr.dev installer's ~/.local/bin target that install.sh's
// apt path uses on Linux.
const HERDR_FALLBACK_PATHS = [
	"/opt/homebrew/bin/herdr",
	"/usr/local/bin/herdr",
	`${process.env.HOME ?? ""}/.local/bin/herdr`,
];

// Run a command, resolving undefined instead of throwing. Failures here are
// expected (missing binary, non-repository directory) and simply skip work.
function run(command, args) {
	return new Promise((resolve) => {
		execFile(
			command,
			args,
			{ timeout: HERDR_TIMEOUT_MS, maxBuffer: 8 * 1024 * 1024 },
			(error, stdout) => resolve(error ? undefined : stdout),
		);
	});
}

let herdrBinary;
async function resolveHerdr() {
	if (herdrBinary) {
		return herdrBinary;
	}
	if (await run("herdr", ["--version"])) {
		return (herdrBinary = "herdr");
	}
	for (const candidate of HERDR_FALLBACK_PATHS) {
		if (await run(candidate, ["--version"])) {
			return (herdrBinary = candidate);
		}
	}
	return undefined;
}

// The main checkout is the first entry `git worktree list` reports; the rest
// are linked worktrees.
async function repoWorktrees(directory) {
	const raw = await run("git", ["-C", directory, "worktree", "list", "--porcelain"]);
	if (!raw) {
		return undefined;
	}
	const paths = [];
	for (const line of raw.split("\n")) {
		if (line.startsWith("worktree ")) {
			paths.push(line.slice("worktree ".length).trim());
		}
	}
	if (paths.length === 0) {
		return undefined;
	}
	return { root: paths[0], worktrees: paths.slice(1) };
}

// Herdr reports the open worktrees with an `open_workspace_id`; only the closed
// linked ones need opening.
function closedWorktrees(listing) {
	let parsed;
	try {
		parsed = JSON.parse(listing);
	} catch {
		return [];
	}
	const worktrees = parsed?.result?.worktrees;
	if (!Array.isArray(worktrees)) {
		return [];
	}
	return worktrees
		.filter((wt) => wt && wt.is_linked_worktree && !wt.is_prunable && !wt.open_workspace_id && wt.path)
		.map((wt) => wt.path);
}

// Serialize reconciles so overlapping events cannot race the same repository.
function createReconciler() {
	let queue = Promise.resolve();
	return (directory) => {
		queue = queue
			.then(async () => {
				const herdr = await resolveHerdr();
				if (!herdr) {
					return;
				}
				const repo = await repoWorktrees(directory);
				if (!repo) {
					return;
				}
				const listing = await run(herdr, ["worktree", "list", "--cwd", repo.root]);
				if (!listing) {
					return;
				}
				for (const path of closedWorktrees(listing)) {
					await run(herdr, ["worktree", "open", "--cwd", repo.root, "--path", path, "--no-focus"]);
				}
			})
			.catch(() => {});
	};
}

export default {
	id: SOURCE,
	async setup(ctx) {
		const controller = new AbortController();
		const reconcile = createReconciler();
		let timer;

		const trigger = (directory) => {
			if (!directory) {
				return;
			}
			clearTimeout(timer);
			timer = setTimeout(() => reconcile(directory), RECONCILE_DEBOUNCE_MS);
			timer.unref?.();
		};

		const fallbackDirectory = () => ctx.location?.project?.canonical ?? ctx.location?.directory;

		// Catch worktrees created before this plugin loaded.
		trigger(fallbackDirectory());

		void (async () => {
			try {
				for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
					if (event?.type === "worktree.updated") {
						trigger(event.location?.directory ?? fallbackDirectory());
					}
				}
			} catch {
				// The stream ends when the plugin unloads or the signal aborts.
			}
		})();

		return () => {
			controller.abort();
			clearTimeout(timer);
		};
	},
};
