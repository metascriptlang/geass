import hello from "./hello.txt?raw";
import counter from "./counter.txt?raw";
import vault from "./vault.txt?raw";
import escrow from "./escrow.txt?raw";

const EXAMPLES = [hello, counter, vault, escrow];
const NAMES = ["hello", "counter", "vault", "escrow"];
const LOCAL = ["localhost", "127.0.0.1"].includes(location.hostname);
const RUNNER = LOCAL ? "http://127.0.0.1:8787/run" : "https://run.metascriptlang.org/run";
const SHARED = "#code=";
const ANSI = /\u001b\[[0-9;]*m/g;

const STYLE = `
.pg-editor { position: relative; display: grid; min-width: max-content; min-height: 100%; font: 13.5px/21px 'Berkeley Mono', ui-monospace, 'SF Mono', Menlo, monospace; tab-size: 4; counter-reset: line; }
.pg-editor > * { grid-area: 1 / 1; margin: 0; padding: 16px 20px 40px 64px; font: inherit; tab-size: inherit; white-space: pre; }
.pg-editor pre { pointer-events: none; color: #abb2bf; }
.pg-editor pre code { font: inherit; }
.pg-editor pre .line::before { counter-increment: line; content: counter(line); position: absolute; left: 0; width: 44px; text-align: right; color: #4a4d57; }
.pg-editor textarea { border: 0; outline: 0; resize: none; overflow: hidden; background: transparent; color: transparent; caret-color: #f1f1ef; }
.pg-editor textarea::selection { background: rgba(240, 54, 58, 0.32); }
`;

function highlighter() {
	return (globalThis.geassHighlighter ??= Promise.all([
		import("shiki/core"), import("shiki/engine/javascript"), import("code-block-theme"), import("metascript-grammar"),
	]).then(([core, engine, colors, grammar]) => core.createHighlighterCore({
		themes: [colors.default],
		langs: [{ ...grammar.default, name: "metascript" }],
		engine: engine.createJavaScriptRegexEngine(),
	})));
}

function sharedCode() {
	if (!location.hash.startsWith(SHARED)) { return null; }
	try {
		return new TextDecoder().decode(Uint8Array.from(atob(location.hash.slice(SHARED.length)), (c) => c.charCodeAt(0)));
	} catch {
		return null;
	}
}

let area = null;
let paint = () => {};

export function mount(host, whenRun) {
	const style = document.createElement("style");
	style.textContent = STYLE;
	document.head.appendChild(style);
	const editor = document.createElement("div");
	editor.className = "pg-editor";
	const painted = document.createElement("pre");
	area = document.createElement("textarea");
	area.spellcheck = false;
	area.autocapitalize = "off";
	area.setAttribute("aria-label", "Program source");
	editor.append(painted, area);
	host.appendChild(editor);
	let turn = 0;
	paint = () => {
		const mine = ++turn;
		const text = area.value;
		painted.textContent = text;
		highlighter().then((shiki) => {
			if (mine !== turn) { return; }
			painted.innerHTML = shiki.codeToHtml(text + "\n", { lang: "metascript", theme: "nerdtools-night" })
				.replace(/^<pre[^>]*>/, "").replace(/<\/pre>$/, "");
		});
	};
	area.addEventListener("input", paint);
	area.addEventListener("keydown", (event) => {
		if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
			event.preventDefault();
			whenRun();
		} else if (event.key === "Tab") {
			event.preventDefault();
			area.setRangeText("\t", area.selectionStart, area.selectionEnd, "end");
			paint();
		}
	});
	const shared = sharedCode();
	const named = Math.max(NAMES.indexOf(location.hash.slice(1)), 0);
	setCode(shared ?? EXAMPLES[named]);
	return shared === null ? named : -1;
}

export function setCode(text) {
	area.value = text;
	area.scrollTop = 0;
	paint();
}

export function example(index) {
	setCode(EXAMPLES[index]);
}

export function share() {
	const bytes = new TextEncoder().encode(area.value);
	let text = "";
	for (const byte of bytes) { text += String.fromCharCode(byte); }
	history.replaceState(null, "", SHARED + btoa(text));
	return navigator.clipboard.writeText(location.href);
}

function lines(text) {
	return text.replace(ANSI, "").split("\n").map((line) => line.replace(/\s+$/, "").replace(/ /g, "\u00a0")).filter((line, at, all) => line !== "" || (at > 0 && at < all.length - 1));
}

export function run(done) {
	const started = performance.now();
	const report = (ok, out, problem) => done(JSON.stringify({
		ok, lines: out, problem, ms: Math.round(performance.now() - started),
	}));
	fetch(RUNNER, {
		method: "POST",
		headers: { "content-type": "application/json" },
		body: JSON.stringify({ code: area.value, target: "c" }),
	}).then((response) => response.json().then((reply) => {
		if (!response.ok) { report(false, [], [reply.error ?? `the runner answered ${response.status}`]); return; }
		const problem = lines((reply.stderr || reply.error || "the program failed").replace(/\S*\/main\.ms/g, "main.ms"));
		report(reply.success, lines(reply.stdout ?? ""), reply.success ? [] : problem);
	})).catch((error) => report(false, [], [`the runner at ${new URL(RUNNER).host} could not be reached: ${error.message}`]));
}
