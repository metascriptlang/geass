// Local stand-in for run.metascriptlang.org: same POST /run contract, no sandbox. Never expose it.
import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";

const PORT = 8787;
const HEADERS = {
	"content-type": "application/json",
	"access-control-allow-origin": "*",
	"access-control-allow-methods": "POST, OPTIONS",
	"access-control-allow-headers": "content-type",
};

function executed(file, args, cwd) {
	return new Promise((resolve) => {
		execFile(file, args, { cwd, timeout: 30000 }, (error, stdout, stderr) => resolve({ failed: error !== null, stdout, stderr }));
	});
}

createServer(async (request, response) => {
	if (request.method === "OPTIONS") { response.writeHead(204, HEADERS).end(); return; }
	if (request.method !== "POST" || request.url !== "/run") { response.writeHead(404, HEADERS).end("{}"); return; }
	let body = "";
	for await (const chunk of request) { body += chunk; }
	const started = performance.now();
	const dir = await mkdtemp(join(tmpdir(), "geassRun-"));
	await writeFile(join(dir, "main.ms"), JSON.parse(body).code);
	const built = await executed(process.env.MSC ?? "msc", ["build", "main.ms", "--no-color"], dir);
	const ran = built.failed ? built : await executed(join(dir, "out/debug/main"), [], dir);
	await rm(dir, { recursive: true, force: true });
	response.writeHead(200, HEADERS).end(JSON.stringify({
		success: !ran.failed,
		stdout: built.failed ? "" : ran.stdout,
		stderr: built.failed ? built.stdout + built.stderr : ran.stderr,
		executionTimeMs: Math.round(performance.now() - started),
	}));
}).listen(PORT, "127.0.0.1", () => console.log(`dev runner on http://127.0.0.1:${PORT}/run`));
