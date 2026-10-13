import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
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
	await page.goto(`http://127.0.0.1:${port}`, { waitUntil: "networkidle" });
	assert.match(await page.title(), /Geass/);
	assert.match(await page.locator("h1").innerText(), /Build on Solana/);
	await page.waitForFunction(() => window.Module?.calledRun === true);
	await page.waitForTimeout(1500);
	const drawingWidth = await page.locator("canvas#canvas").evaluate(canvas => canvas.width);
	assert.ok(drawingWidth > 300, "the Void canvas was not sized by its driver");
	for (const width of [390, 1280]) {
		await page.setViewportSize({ width, height: 844 });
		assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true, `horizontal overflow at ${width}px`);
	}
	const said = (file, pattern) => readFileSync(new URL(file, import.meta.url), "utf8").match(pattern)?.[1];
	const mechFile = "../../mech3d/mechView.ms";
	assert.equal(said(mechFile, /DAYLIGHT_FROM: float64 = ([\d.]+)/), said("../src/home.ms", /DAYLIGHT_FROM = ([\d.]+)/));
	assert.equal(Number(said(mechFile, /SKETCH_MS: float64 = ([\d.]+)/)), 900);
	assert.match(readFileSync(new URL("../src/home.ms", import.meta.url), "utf8"), /background-color 0\.9s ease/);
	const inks = async (share) => {
		await page.evaluate(to => scrollTo(0, (document.documentElement.scrollHeight - innerHeight) * to), share);
		await page.waitForTimeout(2500);
		const shot = await page.screenshot({ clip: await page.locator("canvas#canvas").boundingBox() });
		return page.evaluate(async (png) => {
			const bitmap = await createImageBitmap(await (await fetch("data:image/png;base64," + png)).blob());
			const sheet = new OffscreenCanvas(bitmap.width, bitmap.height).getContext("2d");
			sheet.drawImage(bitmap, 0, 0);
			const pixels = sheet.getImageData(0, 0, bitmap.width, bitmap.height).data;
			let red = 0, dark = 0;
			for (let at = 0; at < pixels.length; at += 4) {
				if (pixels[at] - pixels[at + 1] > 80) red++;
				else if (pixels[at] < 150) dark++;
			}
			return { red: red / (pixels.length / 4), dark: dark / (pixels.length / 4) };
		}, shot.toString("base64"));
	};
	const lit = await inks(0.7);
	const sketched = await inks(1);
	assert.ok(lit.red > 0.005, `the lit mech shows its red parts, measured ${lit.red}`);
	assert.ok(sketched.red < 0.0005, `the line drawing keeps no material colour, measured ${sketched.red}`);
	assert.ok(sketched.dark > 0.01 && sketched.dark < 0.1, `the line drawing is thin lines on the page, measured ${sketched.dark}`);
	assert.deepEqual(errors, []);
	console.log("PASS: production render, live mech canvas, line drawing in daylight, mobile/desktop width, no browser errors");
} finally {
	await browser?.close();
	await new Promise(resolve => server.httpServer.close(resolve));
}
