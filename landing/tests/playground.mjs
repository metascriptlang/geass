import assert from "node:assert/strict";
import { chromium } from "playwright-core";
import { preview } from "vite";

const server = await preview({ preview: { host: "127.0.0.1", port: 0 } });
let browser;
try {
	browser = await chromium.launch({
		executablePath: process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
	});
	const page = await browser.newPage();
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
	reply = { success: false, stdout: "", stderr: "error: Type 'string' is not assignable\n  --> /tmp/x/main.ms:1:18\n", executionTimeMs: 3 };
	await source.press("ControlOrMeta+Enter");
	await page.getByText("did not build").waitFor();
	assert.match(await page.locator("body").innerText(), /-->\smain\.ms:1:18/);

	for (const width of [390, 1280]) {
		await page.setViewportSize({ width, height: 844 });
		await page.waitForFunction(() => document.documentElement.scrollWidth <= innerWidth, null, { timeout: 2000 })
			.catch(() => assert.fail(`horizontal overflow at ${width}px`));
	}
	assert.deepEqual(errors, []);
	console.log("PASS: playground edits, runs through the runner contract, shows refusals and build errors, no browser errors");
} finally {
	await browser?.close();
	await server.close();
}
