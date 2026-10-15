import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const paint = fileURLToPath(new URL("../tools/paint.mjs", import.meta.url));
const run = files => {
	const root = fs.mkdtempSync(path.join(os.tmpdir(), "paint-"));
	for (const [name, source] of Object.entries(files)) { fs.writeFileSync(path.join(root, name), source); }
	const out = path.join(root, "codePaint.ms");
	const done = spawnSync(process.execPath, [paint, root, out], { encoding: "utf8" });
	return { ...done, painted: done.status === 0 ? fs.readFileSync(out, "utf8") : "" };
};

const good = run({ "page.ms": "const DEPOSIT = \"export function deposit(amount: uint64): void {\" +\n" +
	"\t\"\\n  vault.lamports += amount;\\n}\";\n<Sample code={DEPOSIT} />\n<Sample code={props.code} />\n" });
assert.equal(good.status, 0, good.stderr);
const fingerprint = text => {
	let hash = 0x811c9dc5;
	for (const byte of Buffer.from(text, "utf8")) { hash = Math.imul(hash ^ byte, 16777619) >>> 0; }
	return hash;
};
assert.equal(fingerprint("hello"), 1335831723, "the test's FNV-1a is not std/hash fingerprint");
assert.ok(good.painted.includes(`paints.set(${fingerprint(
	"export function deposit(amount: uint64): void {\n  vault.lamports += amount;\n}")}, `),
	"the joined const was not painted under the fingerprint of its full text");
assert.ok(JSON.parse(good.painted.match(/return (\[.*\]);/)[1]).length > 3, "the sample got fewer than four colours");

const computed = run({ "page.ms": "const A = \"x\";\n<Sample code={A} />\n<Sample code={make()} />\n" });
assert.notEqual(computed.status, 0, "a computed code= was painted");
assert.match(computed.stderr, /page\.ms:3: code=\{make\(\)\} is not a const string the build can paint/);

const missing = run({ "page.ms": "<Sample code={ELSEWHERE} />\n" });
assert.notEqual(missing.status, 0, "a const from another file was painted");
assert.match(missing.stderr, /page\.ms:1: ELSEWHERE is not a const string in this file/);

const joined = run({ "page.ms": "const B = \"a\" + OTHER;\n<Sample code={B} />\n" });
assert.notEqual(joined.status, 0, "a const joined with a name was painted");
assert.match(joined.stderr, /page\.ms:2: B is not built from string literals alone/);

const twins = run({ "page.ms": "const A = \"costarring\";\nconst B = \"liquid\";\n<Sample code={A} />\n<Sample code={B} />\n" });
assert.notEqual(twins.status, 0, "two samples with one fingerprint were painted");
assert.match(twins.stderr, /two samples share fingerprint 1582148253: "costarring" and "liquid"/);
console.log("PASS: the build paints every const code sample under its fingerprint and stops on a code= it cannot resolve or a shared fingerprint");
