import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const { notFoundPage, page: served } = await import("../out/server.js");
const page = (path, width) => served(path, width).html;

const program = page("/docs/program", 1440);
const pdas = page("/docs/pdas", 1440);
assert.match(program, /<h1[^>]*>Program structure</, "the program page was not served");
assert.match(pdas, /<h1[^>]*>PDAs</, "a second request served the first page again");
assert.equal(page("/docs/nope", 1440), "", "an unknown docs path was served");
const mentions = (html) => html.split("Instructions and dispatch").length - 1;
assert.equal(mentions(page("/docs/program", 1440)), 2, "the desktop render lost the open section list");
assert.equal(mentions(page("/docs/program", 390)), 1, "the phone render kept the desktop section list");

assert.match(page("", 1440), /<h1[^>]*>Write TypeScript\./, "the home page was not served");
assert.match(notFoundPage().html, /<h1[^>]*>404</, "the not-found page was not served");
assert.ok(served("/docs/program", 1440).css.includes(".neon-view"), "the page came without its rules");
assert.match(served("/docs/program", 1440).head, /<title[^>]*>Program structure · Geass docs</, "the docs page came without its own title");
assert.match(served("/docs/pdas", 1440).head, /rel="canonical" href="https:\/\/geass\.metascriptlang\.org\/docs\/pdas"/);
assert.match(served("/playground", 1440).head, /<title[^>]*>Playground · Geass</, "the playground came without a title");
assert.match(served("/playground", 1440).html, /SIMULATOR/, "the playground was not rendered on the server");
assert.match(notFoundPage().head, /name="robots" content="noindex"/, "the not-found page can be indexed");
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
