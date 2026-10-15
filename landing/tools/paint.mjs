import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createHighlighterCoreSync } from "shiki/core";
import { createJavaScriptRegexEngine } from "shiki/engine/javascript";
import theme from "../src/ui/codeBlockTheme.js";

const landing = fileURLToPath(new URL("..", import.meta.url));
const root = path.resolve(process.argv[2] ?? path.join(landing, "src"));
const target = path.resolve(process.argv[3] ?? path.join(landing, "src/ui/codePaint.ms"));
const grammar = JSON.parse(fs.readFileSync(path.join(landing,
	"../../recompiler/tools/editor-plugin/vscode/syntaxes/metascript.tmLanguage.json"), "utf8"));

const STRING = /"((?:[^"\\]|\\.)*)"/y;

function stringAt(source, at, where) {
	STRING.lastIndex = at;
	const found = STRING.exec(source);
	if (!found) { throw new Error(`${where} is not built from string literals alone`); }
	const body = found[1].replace(/\n/g, "\\n").replace(/\t/g, "\\t");
	return { text: JSON.parse(`"${body}"`), end: STRING.lastIndex };
}

function constAt(source, name, where) {
	const head = new RegExp(`const ${name}(?::\\s*string)?\\s*=\\s*`, "g").exec(source);
	if (!head) { throw new Error(`${where}: ${name} is not a const string in this file`); }
	let text = "";
	let at = head.index + head[0].length;
	for (;;) {
		const part = stringAt(source, at, `${where}: ${name}`);
		text += part.text;
		const next = /\s*([+;])\s*/y;
		next.lastIndex = part.end;
		const joint = next.exec(source);
		if (!joint) { throw new Error(`${where}: ${name} is not built from string literals alone`); }
		if (joint[1] === ";") { return text; }
		at = next.lastIndex;
	}
}

const samples = new Set();
for (const file of fs.readdirSync(root, { recursive: true })) {
	const full = path.join(root, file);
	if (!file.endsWith(".ms") || full === target) { continue; }
	const source = fs.readFileSync(full, "utf8");
	for (const use of source.matchAll(/code=(\{([^}]*)\}|")/g)) {
		const where = `${path.relative(landing, full)}:${source.slice(0, use.index).split("\n").length}`;
		if (use[1] === "\"") { samples.add(stringAt(source, use.index + 5, where).text); continue; }
		if (use[2] === "props.code") { continue; }
		if (!/^[A-Za-z_]\w*$/.test(use[2])) {
			throw new Error(`${where}: code={${use[2]}} is not a const string the build can paint`);
		}
		samples.add(constAt(source, use[2], where));
	}
}

const shiki = createHighlighterCoreSync({
	themes: [theme],
	langs: [{ ...grammar, name: "metascript" }],
	engine: createJavaScriptRegexEngine(),
});
const colors = [];
const colorOf = token => {
	const color = token.color ?? "";
	const at = colors.indexOf(color);
	return at >= 0 ? at : colors.push(color) - 1;
};
const fingerprint = code => {
	let hash = 0x811c9dc5;
	for (const byte of Buffer.from(code, "utf8")) { hash = Math.imul(hash ^ byte, 16777619) >>> 0; }
	return hash;
};
const owners = new Map();
for (const code of samples) {
	const owner = owners.get(fingerprint(code));
	if (owner !== undefined) {
		throw new Error(`two samples share fingerprint ${fingerprint(code)}: ${JSON.stringify(owner.slice(0, 40))} ` +
			`and ${JSON.stringify(code.slice(0, 40))}`);
	}
	owners.set(fingerprint(code), code);
}
const entries = [...samples].map(code => {
	const texts = code.split("\n");
	const lines = shiki.codeToTokens(code, { lang: "metascript", theme: theme.name }).tokens;
	if (lines.length !== texts.length || lines.some((line, i) => line.map(t => t.content).join("") !== texts[i])) {
		throw new Error(`shiki's lines do not rebuild the sample starting ${JSON.stringify(code.slice(0, 40))}`);
	}
	const runs = lines.map(line => ({ runs: line.flatMap(token => [colorOf(token), token.content.length]) }));
	return `\tpaints.set(${fingerprint(code)}, ${JSON.stringify(JSON.stringify({ lines: runs }))});`;
});
fs.writeFileSync(target, "export function codeColors(): string[] {\n" +
	`\treturn ${JSON.stringify(colors)};\n}\n\n` +
	"export function codePaints(): Map<int64, string> {\n" +
	"\tconst paints = new Map<int64, string>();\n" + entries.join("\n") + "\n\treturn paints;\n}\n");
console.log(`painted ${entries.length} code samples into ${path.relative(landing, target)}`);
