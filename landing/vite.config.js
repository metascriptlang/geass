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

export default defineConfig({
	plugins: [metascript({ entry: "src/main.ms", msc: process.env.MSC ?? "msc" })],
	resolve: { alias: codeBlockAlias },
});
