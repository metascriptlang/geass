import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { constAt, fingerprint, sourcesUnder } from "./sampleSource.mjs";

const landing = fileURLToPath(new URL("..", import.meta.url));
const target = path.join(landing, "src/ui/stageShapes.ms");
const PROGRAM_ID = "7PQcxszNYMSBRWWAxzCXHRPVnbiDLpiHMkMGs3sg8hcM";
const SYSTEM_PROGRAM = "11111111111111111111111111111111";
const SIZES = { bool: 1, u8: 1, i8: 1, u16: 2, i16: 2, u32: 4, i32: 4, u64: 8, i64: 8, pubkey: 32 };

function typeOf(type, where) {
	if (typeof type === "string" && SIZES[type] !== undefined) { return { name: type, size: SIZES[type] }; }
	if (type.array) {
		const item = typeOf(type.array[0], where);
		return { name: `[${item.name}; ${type.array[1]}]`, size: item.size * type.array[1] };
	}
	throw new Error(`${where}: no size for the IDL type ${JSON.stringify(type)}`);
}

function seedText(seed) {
	if (seed.kind === "account") { return seed.path; }
	if (seed.kind === "const" && seed.value.every(b => b >= 32 && b < 127)) {
		return JSON.stringify(String.fromCharCode(...seed.value));
	}
	return seed.value.map(b => b.toString(16).padStart(2, "0")).join("");
}

function checksOf(account) {
	const checks = [];
	if (account.signer) { checks.push("SIGNS"); }
	if (account.writable) { checks.push("WRITABLE"); }
	if (account.address === SYSTEM_PROGRAM) { checks.push("SYSTEM PROGRAM"); }
	else if (account.address) { checks.push(`AT ${account.address.slice(0, 4)}…`); }
	if (account.pda) { checks.push(`PDA ${account.pda.seeds.map(seedText).join(" ")}`); }
	return checks;
}

const hex = bytes => bytes.map(b => b.toString(16).padStart(2, "0")).join(" ");

const snake = name => name.replace(/(?<=[a-z0-9])([A-Z])/g, "_$1").toLowerCase();

function lineOf(program, pattern, where) {
	const at = program.split("\n").findIndex(line => pattern.test(line));
	if (at < 0) { throw new Error(`${where}: no line of the program matches ${pattern}`); }
	return at;
}

function shapeOf(idl, program, spec, where) {
	const holders = new Map([...spec.matchAll(/\b([A-Z]\w*): \[(\w+)/g)].map(m => [snake(m[1]), m[2]]));
	const errors = /\berrors: (\w+)/.exec(spec);
	if (!errors) { throw new Error(`${where}: the IDL spec names no errors enum`); }
	const accounts = idl.accounts.map(account => {
		const declared = idl.types.find(type => type.name === account.name);
		if (!declared) { throw new Error(`${where}: the IDL has no type for the account ${account.name}`); }
		const line = lineOf(program, new RegExp(`struct ${account.name}\\b`), where);
		const tagLine = lineOf(program, new RegExp(`function discriminator\\(this typeof ${account.name}\\)`), where);
		const fields = [{ name: "discriminator", type: "[u8; 8]", offset: 0, size: 8, line: tagLine }];
		let offset = 8;
		for (const [at, field] of declared.type.fields.entries()) {
			const type = typeOf(field.type, `${where}: ${account.name}.${field.name}`);
			const fieldLine = line + 1 + at;
			if (!new RegExp(`^\\s*${field.name}:`).test(program.split("\n")[fieldLine])) {
				throw new Error(`${where}: ${account.name}.${field.name} is not on line ${fieldLine + 1} of the program`);
			}
			fields.push({ name: field.name, type: type.name, offset, size: type.size, line: fieldLine });
			offset += type.size;
		}
		return { name: account.name, tag: hex(account.discriminator), size: offset, line, fields };
	});
	const instructions = idl.instructions.map(instruction => {
		const holder = holders.get(instruction.name);
		if (!holder) { throw new Error(`${where}: the IDL spec names no accounts struct for ${instruction.name}`); }
		return {
			name: instruction.name,
			tag: hex(instruction.discriminator),
			line: lineOf(program, new RegExp(`struct ${holder}\\b`), where),
			accounts: instruction.accounts.map(account => ({ name: account.name, checks: checksOf(account) })),
		};
	});
	return {
		accounts,
		instructions,
		errorsLine: lineOf(program, new RegExp(`enum ${errors[1]}\\b`), where),
		errors: idl.errors.map(error => ({ code: error.code, name: error.name })),
	};
}

function idlOf(program, spec, where) {
	const dir = fs.mkdtempSync(path.join(os.tmpdir(), "geass-stage-"));
	fs.mkdirSync(path.join(dir, "src"));
	fs.writeFileSync(path.join(dir, "build.ms"), "import { BuildConfig } from \"std/build\";\n\n" +
		`const config: BuildConfig = {\n\troot: "src/index.ms",\n\tdefines: { programId: "${PROGRAM_ID}" },\n};\n\n` +
		"export default config;\n");
	fs.writeFileSync(path.join(dir, "src/index.ms"), program);
	fs.writeFileSync(path.join(dir, "src/idl.ms"), spec);
	try {
		const out = execFileSync("msc", ["run", "--no-color", "src/idl.ms"],
			{ cwd: dir, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
		const line = out.split("\n").find(text => text.startsWith("{"));
		if (!line) { throw new Error(`${where}: msc run printed no IDL:\n${out}`); }
		return JSON.parse(line);
	} catch (error) {
		if (error.stderr === undefined) { throw error; }
		throw new Error(`${where}: the staged program does not build:\n${error.stderr}${error.stdout}`);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
}

const entries = [];
for (const { full, source } of sourcesUnder(path.join(landing, "src"), target)) {
	for (const use of source.matchAll(/<Staged code=\{(\w+)\} idl=\{(\w+)\}/g)) {
		const where = `${path.relative(landing, full)}:${source.slice(0, use.index).split("\n").length}`;
		const program = constAt(source, use[1], where);
		const spec = constAt(source, use[2], where);
		const shape = shapeOf(idlOf(program, spec, where), program, spec, where);
		entries.push(`\tshapes.set(${fingerprint(program)}, ${JSON.stringify(JSON.stringify(shape))});`);
	}
}
fs.writeFileSync(target, "export function stageShapes(): Map<int64, string> {\n" +
	"\tconst shapes = new Map<int64, string>();\n" + entries.join("\n") + "\n\treturn shapes;\n}\n");
console.log(`staged ${entries.length} programs into ${path.relative(landing, target)}`);
