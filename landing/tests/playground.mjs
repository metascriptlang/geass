import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { copyFileSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { chromium } from "playwright-core";
import { preview } from "vite";

const server = await preview({ preview: { host: "127.0.0.1", port: 0 } });
let browser;
try {
	browser = await chromium.launch({
		executablePath: process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
	});
	const page = await browser.newPage();
	await page.addInitScript(() => { delete WebAssembly.Suspending; });
	const errors = [];
	page.on("pageerror", error => errors.push(error.message));
	const sent = [];
	let reply = { success: true, stdout: "✓ alice deposits 400: ok\n    user 600 lamports\n", stderr: "", executionTimeMs: 5 };
	await page.route("**/run", route => {
		sent.push(JSON.parse(route.request().postData()));
		return route.fulfill({ json: reply, headers: { "access-control-allow-origin": "*" } });
	});
	const { port } = server.httpServer.address();
	await page.goto(`http://127.0.0.1:${port}/playground`, { waitUntil: "load" });
	const source = page.locator(".pg-editor textarea");
	await source.waitFor();
	assert.match(await source.inputValue(), /export enum HelloOp/);
	await page.waitForFunction(() => document.querySelectorAll(".pg-editor pre .line span[style]").length > 20);
	assert.equal(await page.locator("canvas").count(), 0, "the playground mounted the mech canvas");

	await page.getByText("Run", { exact: true }).click();
	const passed = page.getByText("✓ alice deposits 400: ok");
	await passed.waitFor();
	assert.equal(await passed.evaluate(line => getComputedStyle(line).color), "rgb(0, 255, 170)");
	assert.equal(sent[0].code, await source.inputValue(), "Run sends the source in the editor");
	assert.equal(sent[0].target, "c");

	for (const [tab, opens] of [["Vault", "export enum VaultOp"], ["Escrow", "export enum EscrowOp"], ["Counter", "export enum CounterOp"]]) {
		await page.getByText(tab, { exact: true }).click();
		await page.waitForFunction(([opens]) => document.querySelector(".pg-editor textarea").value.includes(opens), [opens]);
	}
	const named = await browser.newPage();
	await named.goto(`http://127.0.0.1:${port}/playground#escrow`, { waitUntil: "load" });
	await named.waitForFunction(() => document.querySelector(".pg-editor textarea")?.value.includes("export enum EscrowOp"));
	assert.equal(await named.getByRole("button", { name: "Escrow" }).evaluate(tab => getComputedStyle(tab).boxShadow.includes("inset")), true, "the named example's tab is not shown as picked");
	await named.close();
	reply = { success: false, stdout: "", stderr: "error: Type 'string' is not assignable\n  --> /tmp/x/main.ms:1:18\n", executionTimeMs: 3 };
	await source.press("ControlOrMeta+Enter");
	await page.getByText("did not build").waitFor();
	assert.match(await page.locator("body").innerText(), /-->\smain\.ms:1:18/);

	for (const width of [390, 1280]) {
		await page.setViewportSize({ width, height: 844 });
		await page.waitForFunction(() => document.documentElement.scrollWidth <= innerWidth, null, { timeout: 2000 })
			.catch(() => assert.fail(`horizontal overflow at ${width}px`));
	}

	const here = await browser.newPage();
	here.on("pageerror", error => errors.push(error.message));
	await here.route("**/run", route => route.abort());
	await here.goto(`http://127.0.0.1:${port}/playground`, { waitUntil: "load" });
	for (const [tab, name] of [["Hello", "hello"], ["Counter", "counter"], ["Vault", "vault"], ["Escrow", "escrow"]]) {
		const dir = mkdtempSync(join(tmpdir(), "geassHere-"));
		let printed;
		try {
			copyFileSync(new URL(`../src/playground/${name}.txt`, import.meta.url), join(dir, "main.ms"));
			execFileSync(process.env.MSC ?? "msc", ["build", "main.ms", "--no-color"], { cwd: dir, stdio: "pipe" });
			printed = execFileSync(join(dir, "out/debug/main"), [], { cwd: dir, encoding: "utf8" }).split("\n").map(line => line.trimEnd()).filter(line => line !== "");
		} finally {
			rmSync(dir, { recursive: true, force: true });
		}
		await here.getByRole("button", { name: tab, exact: true }).click();
		await here.getByText("Run", { exact: true }).click();
		await here.waitForFunction(() => /ran in \d+ ms|did not build/.test(document.body.innerText) && !document.body.innerText.includes("compiling and running"), null, { timeout: 60000 });
		await here.getByText(printed.at(-1).trim(), { exact: true }).last().waitFor({ timeout: 60000 })
			.catch(async () => assert.fail(`${name}: the in-page run did not print the C run's lines: ${await here.locator("body").innerText()}`));
		const shown = (await here.locator("body").innerText()).split("\n").map(line => line.replace(/ /g, " ").trimEnd());
		const at = shown.indexOf(printed[0]);
		assert.deepEqual(shown.slice(at, at + printed.length), printed, `${name}: the in-page run printed other lines than the C run`);
	}
	await here.close();

	assert.deepEqual(errors, []);
	console.log("PASS: playground edits, runs the four programs in the page with the C run's output, falls back to the runner contract without JSPI, shows refusals and build errors, no browser errors");
} finally {
	await browser?.close();
	await server.close();
}
