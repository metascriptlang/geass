import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { copyFileSync, mkdtempSync, readdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const home = fileURLToPath(new URL("../src/playground/", import.meta.url));
const programs = readdirSync(home).filter(name => name.endsWith(".txt"));
assert.ok(programs.length >= 3, "the playground programs were not found");
for (const name of programs) {
	const dir = mkdtempSync(join(tmpdir(), "geassExample-"));
	try {
		copyFileSync(join(home, name), join(dir, "main.ms"));
		execFileSync(process.env.MSC ?? "msc", ["build", "main.ms", "--no-color"], { cwd: dir, stdio: "pipe" });
		const printed = execFileSync(join(dir, "out/debug/main"), [], { cwd: dir, encoding: "utf8" });
		assert.match(printed, /^✓ /m, `${name} ran without a passing instruction`);
		assert.match(printed, /^✗ .*refused by the program/m, `${name} ran without a refused instruction`);
	} catch (error) {
		assert.fail(`${name}: ${error.stdout ?? ""}${error.stderr ?? ""}${error.message}`);
	} finally {
		rmSync(dir, { recursive: true, force: true });
	}
}

console.log(`PASS: ${programs.length} playground programs build with msc and run in the host simulator`);
