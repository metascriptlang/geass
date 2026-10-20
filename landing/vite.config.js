import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";
import metascript from "vite-plugin-metascript";

export const codeBlockAlias = {
	"metascript-grammar": fileURLToPath(new URL(
		"../../recompiler/tools/editor-plugin/vscode/syntaxes/metascript.tmLanguage.json",
		import.meta.url,
	)),
	"code-block-theme": fileURLToPath(new URL("src/ui/codeBlockTheme.js", import.meta.url)),
	"playground-editor": fileURLToPath(new URL("src/playground/editor.js", import.meta.url)),
};

function servePacked(request, response, next) {
	const kind = /^\/msc\/msc\.(wasm|data)$/.exec(request.url.split("?")[0]);
	if (kind === null) { return next(); }
	response.setHeader("content-type", kind[1] === "wasm" ? "application/wasm" : "application/octet-stream");
	response.setHeader("content-encoding", "br");
	response.end(readFileSync(new URL(`public${kind[0]}.br`, import.meta.url)));
}

const packedMsc = {
	name: "packed-msc",
	configureServer: (server) => { server.middlewares.use(servePacked); },
	configurePreviewServer: (server) => { server.middlewares.use(servePacked); },
};

export default defineConfig({
	plugins: [metascript({ entry: "src/main.ms", msc: process.env.MSC ?? "msc" }), packedMsc],
	resolve: { alias: codeBlockAlias },
});
