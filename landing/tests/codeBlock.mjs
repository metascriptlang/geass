import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright-core";
import { build, preview } from "vite";

const configFile = fileURLToPath(new URL("./codeBlock/vite.config.js", import.meta.url));
await build({ configFile, logLevel: "warn" });
const server = await preview({ configFile, preview: { host: "127.0.0.1", port: 0 } });
let browser;
try {
	browser = await chromium.launch({
		executablePath: process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
	});
	const page = await browser.newPage();
	const errors = [];
	page.on("pageerror", error => errors.push(error.message));
	page.on("console", message => { if (message.type() === "error") errors.push(message.text()); });
	const { port } = server.httpServer.address();
	await page.goto(`http://127.0.0.1:${port}`, { waitUntil: "networkidle" });
	await page.waitForFunction(() => new Set([...document.querySelectorAll("span")].map(span => span.style.color)).size > 3);
	if (process.env.CODE_BLOCK_SHOT) await page.screenshot({ path: process.env.CODE_BLOCK_SHOT });
	const text = await page.evaluate(() => document.body.textContent.replaceAll(" ", " "));
	assert.match(text, /export function deposit\(vault: Account, amount: uint64\): void \{/);
	assert.match(text, /\} {4}vault\.lamports \+= amount;/);
	assert.deepEqual(errors, []);
	console.log("PASS: MetaScript source painted by Shiki through Neon nodes, indentation kept, no browser errors");
} finally {
	await browser?.close();
	await new Promise(done => server.httpServer.close(done));
}
