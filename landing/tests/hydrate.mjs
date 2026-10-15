import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { chromium } from "playwright-core";

const PORT = 8817;
const base = `http://127.0.0.1:${PORT}`;
const PHONE = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Mobile/15E148";
const worker = spawn("npx", ["--yes", "wrangler@4", "dev", "--port", String(PORT), "--ip", "127.0.0.1"], { stdio: "ignore" });
let browser;
try {
	for (let tries = 0; ; tries++) {
		if (await fetch(base).then(reply => reply.ok, () => false)) { break; }
		assert.ok(tries < 120, "the Worker did not start");
		await new Promise(resolve => setTimeout(resolve, 500));
	}
	assert.equal((await fetch(`${base}/docs/nope`)).status, 404, "an unknown docs path was not answered with 404");
	assert.equal((await fetch(`${base}/assets/nope.js`)).status, 404, "a missing asset was answered with a page");
	assert.equal((await fetch(`${base}/playground`)).status, 200);
	assert.match(await (await fetch(`${base}/docs/pdas`)).text(), /<title[^>]*>PDAs · Geass docs</, "the served head lacks the page's title");
	const painted = (await (await fetch(`${base}/docs/pdas`)).text()).match(/<span style="color:#[0-9A-F]+;">/g) ?? [];
	assert.ok(new Set(painted).size > 3, "the served docs page carries its code without colours");

	browser = await chromium.launch({
		executablePath: process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
	});
	const errors = [];
	const open = async (path, width, userAgent, kept = "h1") => {
		const context = await browser.newContext({ viewport: { width, height: 900 }, userAgent });
		const page = await context.newPage();
		page.on("pageerror", error => errors.push(`${path} at ${width}: ${error.message}`));
		page.on("console", message => {
			if (message.type() === "error" && !/status of 404/.test(message.text())) { errors.push(`${path} at ${width}: ${message.text()}`); }
		});
		await page.addInitScript(() => document.addEventListener("readystatechange", () => {
			if (document.readyState === "interactive") { for (const node of document.querySelectorAll("#served *")) { node.served = true; } }
		}));
		await page.goto(base + path, { waitUntil: "networkidle" });
		assert.equal(await page.locator(kept).first().evaluate(node => node.served), true, `${path} at ${width}: the served page was rebuilt`);
		assert.equal(await page.locator("title").count(), 1, `${path} at ${width}: the head holds more than one title`);
		return page;
	};

	for (const [width, userAgent] of [[1440], [390, PHONE], [800], [1200, PHONE]]) {
		const home = await open("/", width, userAgent);
		assert.equal(await home.getByText("METASCRIPT FOR SOLANA").count(), width >= 900 ? 1 : 0, `home at ${width}: the layout did not follow the real width`);
		assert.equal(await home.title(), "Geass — MetaScript for Solana");
		await home.waitForFunction(() => window.Module?.calledRun === true);
		assert.equal(await home.locator("canvas#canvas").evaluate(canvas => canvas.served), true, "the mech drew into a canvas that was not the served one");
		if (width === 1440) {
			await home.evaluate(() => scrollTo(0, (document.documentElement.scrollHeight - innerHeight) * 0.55));
			await home.getByText("04 / 06").waitFor();
		}
		await home.context().close();

		const docs = await open("/docs/program", width, userAgent);
		assert.equal(await docs.title(), "Program structure · Geass docs");
		await docs.waitForFunction(() => new Set([...document.querySelectorAll("span")].map(span => span.style.color)).size > 3);
		assert.equal(await docs.locator("span", { hasText: /^export$/ }).first().evaluate(span => span.served), true, "hydrate rebuilt the served code");
		await docs.getByLabel("Copy", { exact: true }).first().click();
		await docs.getByLabel("Copied", { exact: true }).waitFor();
		await docs.context().close();

		const play = await open("/playground", width, userAgent, 'a[href="/"]');
		assert.equal(await play.title(), "Playground · Geass");
		await play.locator("textarea").waitFor({ state: "attached" });
		assert.match(await play.locator("textarea").inputValue(), /std\/solana/, "the editor did not load its first example into the served page");
		await play.getByRole("button", { name: "Counter" }).click();
		await play.waitForFunction(() => document.querySelector("textarea").value.includes("CounterOp"));
		await play.context().close();

		const lost = await open("/nope", width, userAgent);
		assert.equal(await lost.locator("h1").innerText(), "404");
		assert.equal(await lost.locator('meta[name="robots"]').getAttribute("content"), "noindex");
		await lost.context().close();
	}

	const docs = await open("/docs/accounts", 1440);
	const leaf = docs.getByRole("link", { name: "Accounts your program owns" });
	await leaf.click();
	await docs.waitForFunction(link => getComputedStyle(link).color === "rgb(255, 168, 40)", await leaf.elementHandle());

	await docs.evaluate(() => { window.sameDocument = true; scrollTo(0, 600); });
	await docs.getByRole("link", { name: "PDAS", exact: true }).click();
	await docs.waitForURL("**/docs/pdas");
	assert.equal(await docs.evaluate(() => window.sameDocument), true, "a docs link reloaded the page");
	assert.equal(await docs.locator("h1").innerText(), "PDAs");
	assert.equal(await docs.title(), "PDAs · Geass docs");
	assert.equal(await docs.locator("title").count(), 1, "the head holds more than one title after a docs link");
	assert.equal(await docs.locator('link[rel="canonical"]').getAttribute("href"), "https://geass.metascriptlang.org/docs/pdas");
	assert.equal(await docs.evaluate(() => scrollY), 0, "a docs link kept the old scroll position");
	assert.equal(await docs.getByRole("link", { name: "GEASS", exact: true }).evaluate(brand => brand.served), true, "a docs link rebuilt the served header");
	await docs.waitForFunction(() => new Set([...document.querySelectorAll("span")].map(span => span.style.color)).size > 3);

	await docs.goBack();
	await docs.waitForURL("**/docs/accounts#*");
	assert.equal(await docs.evaluate(() => window.sameDocument), true, "going back reloaded the page");
	assert.equal(await docs.locator("h1").innerText(), "Accounts");
	assert.equal(await docs.title(), "Accounts · Geass docs");
	await docs.waitForFunction(() => [...document.querySelectorAll("a")].some(link => link.innerText === "Accounts your program owns" && getComputedStyle(link).color === "rgb(255, 168, 40)"));

	const anchor = "creating";
	await docs.evaluate(anchor => document.querySelector('a[href="/docs/pdas"]').setAttribute("href", `/docs/pdas#${anchor}`), anchor);
	await docs.getByRole("link", { name: "PDAS", exact: true }).click();
	await docs.waitForURL(`**/docs/pdas#${anchor}`);
	assert.equal(await docs.evaluate(() => window.sameDocument), true, "a docs link with a fragment reloaded the page");
	assert.equal(await docs.locator("h1").innerText(), "PDAs");
	assert.ok(await docs.evaluate(anchor => Math.abs(document.getElementById(anchor).getBoundingClientRect().top) < innerHeight, anchor), "a docs link with a fragment did not scroll to its target");

	await docs.getByRole("link", { name: "HOME", exact: true }).click();
	await docs.waitForURL(base + "/");
	await docs.locator("canvas#canvas").waitFor({ state: "attached" });
	assert.equal(await docs.evaluate(() => window.sameDocument), undefined, "the home link did not load the home page as a new document");

	assert.deepEqual(errors, []);
	console.log("PASS: the Worker's home, docs and 404 pages are attached to in Chrome at served and other widths, docs links move without a reload, no browser errors");
} finally {
	await browser?.close();
	worker.kill();
}
