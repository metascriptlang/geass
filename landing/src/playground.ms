import { createSignal } from "../../../neon/src/core/signal";
import { For, Show } from "../../../neon/src/macros/ui/flow";
import { createStyles, styleOf } from "../../../neon/src/macros/ui/style";
import { Pressable, View } from "../../../neon/src/components/primitives";
import { useWindowDimensions } from "../../../neon/src/render/environment";
import { HostNode } from "../../../neon/src/render/hostTypes";
import { NeonNode } from "../../../neon/src/render/node";
import { theme } from "./theme";
import { GitHubLink } from "./ui/decor";
import { PageHead, PageTitle } from "./ui/pageHead";

extern class HTMLElement {
	id: string;
}

extern function loadBench(host: HTMLElement, whenRun: () => void, done: (shown: int32) => void): void
	from "((host, whenRun, done) => import('playground-editor').then((bench) => { globalThis.geassBench = bench; done(bench.mount(host, whenRun)); }))(#, #, #)";

extern function showExample(index: int32): void from "globalThis.geassBench.example(#)";

extern function runProgram(done: (reply: string) => void): void from "globalThis.geassBench.run(#)";

extern function shareProgram(done: () => void): void from "globalThis.geassBench.share().then(#)";

struct RunReply {
	ok: boolean;
	lines: string[];
	problem: string[];
	ms: int32;
}

struct Example {
	name: string;
	at: int32;
}

const EXAMPLES: Example[] = [
	{ name: "Hello", at: 0 },
	{ name: "Counter", at: 1 },
	{ name: "Vault", at: 2 },
	{ name: "Escrow", at: 3 },
];
const PASSED = "#00ffaa";
const IDLE: RunReply = { ok: true, lines: [], problem: [], ms: -1 };

const [ready, setReady] = createSignal(false);
const [running, setRunning] = createSignal(false);
const [shown, setShown] = createSignal<int32>(0);
const [copied, setCopied] = createSignal(false);
const [reply, setReply] = createSignal<RunReply>(IDLE);

export function atPlayground(path: string): boolean {
	return path === "/playground";
}

const p = createStyles({
	page: {
		position: "fixed",
		top: 0,
		left: 0,
		right: 0,
		bottom: 0,
		backgroundColor: "#0b0c0e",
		color: theme.ink,
		fontFamily: theme.sans,
	},
	bar: {
		flexDirection: "row",
		alignItems: "center",
		gap: 20,
		height: 60,
		paddingLeft: 24,
		paddingRight: 24,
	},
	logo: { fontSize: 20, fontWeight: "700", letterSpacing: 6, color: theme.white, textDecorationLine: "none" },
	section: { fontFamily: theme.mono, fontSize: 12, letterSpacing: 2, color: theme.muted },
	fill: { flex: 1 },
	rule: { height: 1, backgroundColor: theme.line },
	navLink: { fontSize: 14, color: theme.ink, textDecorationLine: "none" },
	tools: {
		flexDirection: "row",
		alignItems: "center",
		gap: 8,
		height: 52,
		paddingLeft: 24,
		paddingRight: 24,
		backgroundColor: "#0e0f12",
	},
	tabs: { flex: 1, minWidth: 0, flexDirection: "row", gap: 8, overflow: "scroll" },
	tab: {
		paddingLeft: 14,
		paddingRight: 14,
		height: 52,
		justifyContent: "center",
		fontFamily: theme.mono,
		fontSize: 13,
		color: theme.muted,
		cursor: "pointer",
		variants: { state: { shown: { color: theme.white, boxShadow: "inset 0 -2px 0 " + theme.signal } } },
	},
	hint: { fontFamily: theme.mono, fontSize: 12, color: "#5d626b" },
	share: {
		height: 34,
		paddingLeft: 14,
		paddingRight: 14,
		justifyContent: "center",
		borderWidth: 1,
		borderColor: theme.line,
		fontSize: 13,
		cursor: "pointer",
	},
	run: {
		height: 34,
		paddingLeft: 20,
		paddingRight: 20,
		justifyContent: "center",
		backgroundColor: theme.red,
		color: theme.white,
		fontSize: 13,
		fontWeight: "600",
		letterSpacing: 0.5,
		cursor: "pointer",
		transition: "opacity 0.2s ease",
		variants: { state: { busy: { opacity: 0.5 } } },
	},
	bench: {
		flex: 1,
		minHeight: 0,
		flexDirection: "row",
		variants: { layout: { narrow: { flexDirection: "column" } } },
	},
	source: {
		flex: 3,
		minWidth: 0,
		minHeight: 0,
		overflow: "scroll",
		backgroundColor: "#0b0c0e",
	},
	result: {
		flex: 2,
		minWidth: 0,
		minHeight: 0,
		backgroundColor: "#08090b",
		boxShadow: "inset 1px 1px 0 " + theme.line,
	},
	resultHead: {
		flexDirection: "row",
		alignItems: "center",
		gap: 12,
		height: 44,
		paddingLeft: 20,
		paddingRight: 20,
	},
	status: {
		fontFamily: theme.mono,
		fontSize: 12,
		color: theme.muted,
		variants: { state: { passed: { color: PASSED }, failed: { color: theme.signal } } },
	},
	output: {
		flex: 1,
		minHeight: 0,
		overflow: "scroll",
		paddingTop: 16,
		paddingBottom: 24,
		paddingLeft: 20,
		paddingRight: 20,
		fontFamily: "'Berkeley Mono', " + theme.mono,
		fontSize: 13,
		lineHeight: 22,
	},
	line: {
		minHeight: 22,
		color: "#c9ccd1",
		variants: {
			tone: {
				passed: { color: PASSED },
				refused: { color: theme.signal },
				detail: { color: theme.muted },
				problem: { color: "#ff8f8f" },
			},
		},
	},
	empty: { maxWidth: 360, fontSize: 14, lineHeight: 22, color: theme.muted },
	note: {
		paddingTop: 10,
		paddingBottom: 10,
		paddingLeft: 20,
		paddingRight: 20,
		fontSize: 12,
		lineHeight: 18,
		color: "#6b7079",
	},
});

function execute(): void {
	if (!ready() || running()) { return; }
	setRunning(true);
	runProgram((answer: string): void => {
		const parsed: Result<RunReply, string> = JSON.parse<RunReply>(answer);
		setRunning(false);
		if (!parsed.ok) { console.error(`playground: ${parsed.error}`); return; }
		setReply(parsed.value);
	});
}

function startBench(node: HostNode): void {
	loadBench(node as unknown as HTMLElement, execute, (at: int32): void => { setShown(at); setReady(true); });
}

function toneOf(line: string): "" | "passed" | "refused" | "detail" {
	if (line.startsWith("✓")) { return "passed"; }
	if (line.startsWith("✗")) { return "refused"; }
	return line.startsWith(" ") ? "detail" : "";
}

function statusText(): string {
	if (running()) { return "compiling and running…"; }
	if (reply().ms < 0) { return "ready"; }
	return reply().ok ? `ran in ${reply().ms} ms` : "did not build";
}

function statusState(): "" | "passed" | "failed" {
	if (running() || reply().ms < 0) { return ""; }
	return reply().ok ? "passed" : "failed";
}

export function Playground(): NeonNode {
	const viewport = useWindowDimensions();
	const layout = (): "" | "narrow" => viewport().width >= 900 ? "" : "narrow";
	return <View style={p.page}>
		<PageTitle title="Playground · Geass" />
		<PageHead
			about="Write a Solana program in the browser, build it with msc and run it."
			path="/playground"
		/>
		<View style={p.bar}>
			<a style={p.logo} href="/">GEASS</a>
			<span style={p.section}>PLAYGROUND</span>
			<View style={p.fill} />
			<a style={p.navLink} href="/docs">Docs</a>
			<GitHubLink />
		</View>
		<View style={p.rule} />
		<View style={p.tools}>
			<View style={p.tabs}>
				<For each={EXAMPLES}>
					{(example: Example): NeonNode =>
						<Pressable
							style={p.tab({ state: shown() === example.at ? "shown" : "" })}
							onPress={(): void => { if (ready()) { setShown(example.at); showExample(example.at); } }}
						>
							<span>{example.name}</span>
						</Pressable>}
				</For>
			</View>
			<Show when={layout() === ""}><span style={p.hint}>⌘ + Enter</span></Show>
			<Pressable style={p.share} onPress={(): void => {
				if (!ready()) { return; }
				shareProgram(() => { setCopied(true); });
			}}>
				<span>{copied() ? "Link copied" : "Share"}</span>
			</Pressable>
			<Pressable style={p.run({ state: running() ? "busy" : "" })} onPress={(): void => { execute(); }}>
				<span>{running() ? "Running" : "Run"}</span>
			</Pressable>
		</View>
		<View style={p.rule} />
		<View style={p.bench({ layout: layout() })}>
			<div style={p.source} ref={startBench} />
			<View style={p.result}>
				<View style={p.resultHead}>
					<span style={p.section}>SIMULATOR</span>
					<View style={p.fill} />
					<span style={p.status({ state: statusState() })}>{statusText()}</span>
				</View>
				<View style={p.rule} />
				<View style={p.output}>
					<Show when={reply().ms < 0 && !running()}>
						<p style={p.empty}>
							Press Run. The program is compiled in your browser and its instructions are executed
							against a simulated Solana runtime: real account checks, real System CPIs, no wallet.
						</p>
					</Show>
					<For each={reply().lines}>
						{(line: string): NeonNode => <View style={p.line({ tone: toneOf(line) })}><span>{line}</span></View>}
					</For>
					<For each={reply().problem}>
						{(line: string): NeonNode => <View style={p.line({ tone: "problem" })}><span>{line}</span></View>}
					</For>
				</View>
				<span style={p.note}>
					Runs on the std/solana host simulator. System and Token CPIs execute; every other CPI is recorded.
				</span>
			</View>
		</View>
	</View>;
}
