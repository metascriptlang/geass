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
	page.on("console", message => { if (message.type() === "error") errors.push(message.text()); });
	const { port } = server.httpServer.address();
	await page.goto(`http://127.0.0.1:${port}/docs`, { waitUntil: "networkidle" });
	assert.equal(await page.locator("h1").innerText(), "Getting started");
	assert.equal(await page.locator("canvas").count(), 0, "the docs page mounted the mech canvas");
	await page.waitForFunction(() => new Set([...document.querySelectorAll("span")].map(span => span.style.color)).size > 3);
	assert.match(await page.locator("body").innerText(), /std\/solana/);
	const described = async title => {
		const about = await page.evaluate(() => [...document.querySelectorAll('meta[name="description"]')].map(meta => meta.content));
		assert.equal(about.length, 1, `${title} has one description`);
		assert.equal(about[0], await page.locator("h1 + p").innerText(), `${title} is described by its lede`);
		return about[0];
	};
	const abouts = new Set([await described("Getting started")]);
	for (const [link, path, title] of [
		["SOLANA IN FIVE MINUTES", "solana-basics", "Solana in five minutes"],
		["COMING FROM ANCHOR", "from-anchor", "Coming from Anchor"],
		["PROGRAM STRUCTURE", "program", "Program structure"],
		["ACCOUNT VALIDATION", "validation", "Account validation"],
		["PDAS", "pdas", "PDAs"],
		["CROSS-PROGRAM CALLS", "cpi", "Cross-program calls"],
		["TOKENS", "tokens", "Tokens"],
		["MAGICBLOCK ROLLUPS", "rollups", "MagicBlock rollups"],
		["MAGICBLOCK VRF", "randomness", "MagicBlock VRF"],
		["MAGICBLOCK CRANKS", "cranks", "MagicBlock cranks"],
		["ACCOUNT DATA", "data", "Account data"],
		["ERRORS AND EVENTS", "errors-events", "Errors and events"],
		["TESTING", "testing", "Testing"],
		["CLIENTS AND IDL", "clients", "Clients and IDL"],
		["DEPLOYING", "deploying", "Deploying"],
		["SECURITY", "security", "Security"],
		["PERFORMANCE", "performance", "Performance"],
		["ACCOUNTS", "accounts", "Accounts"],
	]) {
		await page.getByRole("link", { name: link, exact: true }).click();
		await page.waitForURL(`**/docs/${path}`);
		assert.equal(await page.locator("h1").innerText(), title);
		abouts.add(await described(title));
	}
	assert.equal(abouts.size, 19, "every docs page has its own description");
	assert.match(await page.locator("body").innerText(), /WritableSigner\s+#\[account\(mut\)\] Signer/);
	const tone = "rgb(255, 168, 40)";
	const leaf = page.getByRole("link", { name: "Accounts your program owns" });
	await leaf.click();
	await page.waitForFunction(([link, tone]) => getComputedStyle(link).color === tone, [await leaf.elementHandle(), tone]);
	assert.equal(await page.getByRole("link", { name: "Proof types" }).evaluate(link => getComputedStyle(link).color), "rgb(147, 144, 141)");
	await page.getByRole("link", { name: "Proof types" }).click();
	const fork = await page.getByRole("link", { name: "Proof types" }).elementHandle();
	await page.waitForFunction(([link, tone]) => getComputedStyle(link).color === tone, [fork, tone]);
	const whole = await page.evaluate(([link, tone]) => [...link.parentElement.children]
		.filter(part => getComputedStyle(part).backgroundColor === tone)
		.map(part => part.getBoundingClientRect().height), [fork, tone]);
	assert.deepEqual(whole, [1, 100], "the picked group lights its tick and a bar down its whole tree");
	assert.equal(await page.getByRole("link", { name: "Signers and plain accounts" }).evaluate(link => getComputedStyle(link).color), "rgb(213, 211, 209)");
	assert.equal(await page.getByRole("link", { name: "Reading the data" }).evaluate(link => getComputedStyle(link).color), "rgb(147, 144, 141)");
	await leaf.click();
	await page.waitForTimeout(300);
	assert.ok(await page.locator("#program-accounts").evaluate(anchor => anchor.parentElement.getBoundingClientRect().top > 72), "the picked heading sits under the header");
	for (const width of [390, 1280]) {
		await page.setViewportSize({ width, height: 844 });
		await page.waitForFunction(() => document.documentElement.scrollWidth <= innerWidth, null, { timeout: 2000 })
			.catch(() => assert.fail(`horizontal overflow at ${width}px`));
	}
	assert.equal(await page.getByRole("link", { name: "PLAYGROUND", exact: true }).getAttribute("href"), "/playground");
	await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
	const copy = page.locator('[aria-label="Copy"], [aria-label="Copied"]');
	assert.ok(await copy.count() > 0, "the samples have a Copy button");
	assert.equal(await page.getByText("PLAY", { exact: false }).filter({ hasText: /^▸ PLAY$/ }).count(), 0, "no sample has a Play button");
	const byHand = await copy.evaluateAll(buttons => buttons.map(button => {
		const texts = document.createTreeWalker(button.parentElement.firstElementChild, NodeFilter.SHOW_TEXT);
		const written = [];
		while (texts.nextNode()) { if (texts.currentNode.length > 0) { written.push(texts.currentNode); } }
		getSelection().setBaseAndExtent(written[0], 0, written.at(-1), written.at(-1).length);
		return getSelection().toString();
	}));
	for (const [at, selected] of byHand.entries()) {
		await copy.nth(at).click();
		await page.waitForFunction(button => button.ariaLabel === "Copied", await copy.nth(at).elementHandle());
		const copied = await page.evaluate(() => navigator.clipboard.readText());
		assert.equal(selected, copied, "selecting a sample by hand copies what Copy copies");
	}
	await page.waitForFunction(() => !document.querySelector('[aria-label="Copied"]'));
	if (process.env.DOCS_SHOT) {
		for (const [name, path, width, height] of [["start", "/docs", 1672, 941], ["anchor", "/docs/from-anchor", 1672, 941], ["accounts", "/docs/accounts#proof-types", 1672, 941], ["validation", "/docs/validation", 1672, 941], ["testing", "/docs/testing#asserting", 1672, 941], ["clients", "/docs/clients#codama", 1672, 941], ["deploying", "/docs/deploying", 1672, 941], ["tokens", "/docs/tokens#checks", 1672, 941], ["tokensPhone", "/docs/tokens", 390, 844], ["rollups", "/docs/rollups#delegated", 1672, 941], ["randomness", "/docs/randomness", 1672, 941], ["cranks", "/docs/cranks#creating", 1672, 941], ["security", "/docs/security#always-on", 1672, 941], ["performance", "/docs/performance", 1672, 941], ["performancePhone", "/docs/performance", 390, 844], ["phone", "/docs/accounts", 390, 844]]) {
			await page.setViewportSize({ width, height });
			await page.goto(`http://127.0.0.1:${port}${path}`, { waitUntil: "networkidle" });
			await page.waitForTimeout(800);
			await page.screenshot({ path: `${process.env.DOCS_SHOT}_${name}.png` });
		}
	}
	assert.deepEqual(errors, []);
	console.log("PASS: docs pages render, sidebar switches page and highlights the picked item, Copy copies a sample, no mech canvas, mobile/desktop width, no browser errors");
} finally {
	await browser?.close();
	await new Promise(resolve => server.httpServer.close(resolve));
}
