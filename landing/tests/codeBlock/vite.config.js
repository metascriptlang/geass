import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";
import metascript from "vite-plugin-metascript";
import { codeBlockAlias } from "../../vite.config.js";

const here = fileURLToPath(new URL(".", import.meta.url));

export default defineConfig({
	root: here,
	plugins: [metascript({
		entry: fileURLToPath(new URL("./probe.ms", import.meta.url)),
		msc: process.env.MSC ?? "msc",
		outDir: fileURLToPath(new URL("../../node_modules/.metascript-codeBlock", import.meta.url)),
	})],
	resolve: { alias: codeBlockAlias },
	build: { outDir: fileURLToPath(new URL("../../node_modules/.codeBlockProbe", import.meta.url)), emptyOutDir: true },
});
