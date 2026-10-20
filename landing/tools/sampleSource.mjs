import fs from "node:fs";
import path from "node:path";

const STRING = /"((?:[^"\\]|\\.)*)"/y;

export function stringAt(source, at, where) {
	STRING.lastIndex = at;
	const found = STRING.exec(source);
	if (!found) { throw new Error(`${where} is not built from string literals alone`); }
	const body = found[1].replace(/\n/g, "\\n").replace(/\t/g, "\\t");
	return { text: JSON.parse(`"${body}"`), end: STRING.lastIndex };
}

export function constAt(source, name, where) {
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

export function fingerprint(code) {
	let hash = 0x811c9dc5;
	for (const byte of Buffer.from(code, "utf8")) { hash = Math.imul(hash ^ byte, 16777619) >>> 0; }
	return hash;
}

export function* sourcesUnder(root, skip) {
	for (const file of fs.readdirSync(root, { recursive: true })) {
		const full = path.join(root, file);
		if (!file.endsWith(".ms") || full === skip) { continue; }
		yield { full, source: fs.readFileSync(full, "utf8") };
	}
}
