import { chromium } from "playwright-core";
const [base, out] = [process.argv[2] ?? "http://127.0.0.1:8787", new URL("../public/og.jpg", import.meta.url).pathname];
const browser = await chromium.launch({ executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", args: ["--use-angle=metal", "--ignore-gpu-blocklist"] });
const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });
const loaded = page.waitForEvent("console", { predicate: (m) => m.text() === "mech view: detailed core loaded", timeout: 60000 });
await page.goto(base + "/?gl", { waitUntil: "networkidle" });
await loaded;
await page.evaluate(() => {
	const brand = [...document.querySelectorAll("a")].find((a) => a.textContent === "GEASS").parentElement;
	const kept = [document.querySelector("canvas"), ...[...document.querySelectorAll("body *")].filter((e) => {
		const s = getComputedStyle(e);
		return s.position === "fixed" && s.backgroundImage !== "none" || s.backgroundImage.startsWith("linear-gradient(to right top");
	})];
	const style = document.createElement("style");
	style.textContent = "body * { visibility: hidden !important } [data-og], [data-brand], [data-brand] * { visibility: visible !important }";
	document.head.append(style);
	for (const e of kept) { e.dataset.og = ""; }
	for (const part of [...brand.children].slice(0, 3)) { part.dataset.brand = ""; }
	brand.style.cssText += ";position:fixed;left:64px;top:275px;transform:scale(1.9);transform-origin:left center";
	document.querySelector("canvas").style.cssText += ";transform:scale(0.86);transform-origin:70% 75%";
});
await page.waitForTimeout(500);
await page.screenshot({ path: out, type: "jpeg", quality: 88 });
await browser.close();
