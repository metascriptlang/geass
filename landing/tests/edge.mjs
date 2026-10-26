import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const { answer } = await import("../out/server.js");
const template = readFileSync(new URL("../index.html", import.meta.url), "utf8");
const AGENT = { 390: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Mobile/15E148", 1440: "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0)" };
const served = (path, width) => answer(path, AGENT[width], template);
const page = async (path, width) => (await served(path, width)).body;

const program = await page("/docs/program", 1440);
const pdas = await page("/docs/pdas", 1440);
assert.match(program, /<h1[^>]*>Program structure</, "the program page was not served");
assert.match(pdas, /<h1[^>]*>PDAs</, "a second request served the first page again");
assert.equal((await served("/docs/nope", 1440)).status, 404, "an unknown docs path was served");
const slashed = await served("/docs/pdas/", 1440);
assert.deepEqual([slashed.status, slashed.location], [308, "/docs/pdas"], "a docs path ending in a slash was not redirected");
const mentions = (html) => html.split("Instructions and dispatch").length - 1;
assert.equal(mentions(await page("/docs/program", 1440)), 2, "the desktop render lost the open section list");
assert.equal(mentions(await page("/docs/program", 390)), 1, "the phone render kept the desktop section list");
const [phone, desktop] = await Promise.all([page("/docs/program", 390), page("/docs/program", 1440)]);
assert.deepEqual([mentions(phone), mentions(desktop)], [1, 2], "two requests rendered at once took each other's width");
assert.deepEqual([phone, desktop].map(html => html.match(/data-width="(\d+)"/)[1]), ["390", "1440"], "the served root does not name the width it was rendered at");

assert.match(await page("/", 1440), /<h1[^>]*>Write TypeScript\./, "the home page was not served");
assert.match(await page("/nope", 1440), /<h1[^>]*>404</, "the not-found page was not served");
assert.ok((await served("/docs/program", 1440)).body.includes(".neon-view"), "the page came without its rules");
assert.match((await served("/docs/program", 1440)).body, /<title[^>]*>Program structure · Geass docs</, "the docs page came without its own title");
assert.match((await served("/docs/pdas", 1440)).body, /rel="canonical" href="https:\/\/geass\.metascriptlang\.org\/docs\/pdas"/);
assert.match((await served("/playground", 1440)).body, /<title[^>]*>Playground · Geass</, "the playground came without a title");
assert.match((await served("/playground", 1440)).body, /SIMULATOR/, "the playground was not rendered on the server");
assert.match((await served("/nope", 1440)).body, /name="robots" content="noindex"/, "the not-found page can be indexed");
const counter = readFileSync(new URL("../src/playground/counter.txt", import.meta.url), "utf8").split("\n").map(line => line.trim());
for (const [, name, sample] of readFileSync(new URL("../src/features.ms", import.meta.url), "utf8").matchAll(/const (\w+_CODE) = "([^"]*)";/g)) {
	if (sample.startsWith("$")) { continue; }
	let from = 0;
	for (const line of sample.split("\n").map(line => line.trim())) {
		from = counter.indexOf(line, from) + 1;
		assert.notEqual(from, 0, `${name} on the home page shows a line the counter program in the Playground does not have: ${line}`);
	}
}

console.log("PASS: the home page, docs pages and the not-found page render on the server per request, with no browser globals");
