import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";
import metascript from "vite-plugin-metascript";
import { relay } from "./relay.js";

export const codeBlockAlias = {
	"metascript-grammar": fileURLToPath(new URL(
		"../../recompiler/tools/editor-plugin/vscode/syntaxes/metascript.tmLanguage.json",
		import.meta.url,
	)),
	"code-block-theme": fileURLToPath(new URL("src/ui/codeBlockTheme.js", import.meta.url)),
	"playground-editor": fileURLToPath(new URL("src/playground/editor.js", import.meta.url)),
	"devnet-relay": fileURLToPath(new URL("relay.js", import.meta.url)),
};

function servePacked(request, response, next) {
	const kind = /^\/msc\/msc\.(wasm|data)$/.exec(request.url.split("?")[0]);
	if (kind === null) { return next(); }
	response.setHeader("content-type", kind[1] === "wasm" ? "application/wasm" : "application/octet-stream");
	response.setHeader("content-encoding", "br");
	response.end(readFileSync(new URL(`public${kind[0]}.br`, import.meta.url)));
}

function devVars() {
	const text = readFileSync(new URL(".dev.vars", import.meta.url), "utf8");
	return Object.fromEntries(text.split("\n").filter(line => line.includes("=")).map(line => {
		const at = line.indexOf("=");
		return [line.slice(0, at), JSON.parse(line.slice(at + 1))];
	}));
}

async function serveRelay(request, response, next) {
	if (!request.url.startsWith("/api/")) { return next(); }
	const body = [];
	for await (const chunk of request) { body.push(chunk); }
	const env = { ...devVars(), CALLS: { limit: async () => ({ success: true }) } };
	const answer = await relay(new Request(new URL(request.url, "http://localhost"), {
		method: request.method,
		body: request.method === "POST" ? Buffer.concat(body) : undefined,
	}), env);
	response.statusCode = answer.status;
	response.setHeader("content-type", "application/json");
	response.end(await answer.text());
}

const packedMsc = {
	name: "packed-msc",
	configureServer: (server) => { server.middlewares.use(servePacked); server.middlewares.use(serveRelay); },
	configurePreviewServer: (server) => {
		server.middlewares.use(servePacked);
		server.middlewares.use(serveRelay);
	},
};

export default defineConfig({
	plugins: [metascript({ entry: "src/main.ms", msc: process.env.MSC ?? "msc" }), packedMsc],
	resolve: { alias: codeBlockAlias },
});
