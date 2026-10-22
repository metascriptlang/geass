import { createMemo } from "../../../../neon/src/core/memo";
import { Accessor, createSignal } from "../../../../neon/src/core/signal";
import { For, Show } from "../../../../neon/src/macros/ui/flow";
import { createStyles, styleOf } from "../../../../neon/src/macros/ui/style";
import { Pressable, Text, View, ViewHandle } from "../../../../neon/src/components/primitives";
import { Circle, Path, Svg } from "../../../../neon/src/components/svg/elements";
import { useWindowDimensions } from "../../../../neon/src/render/environment";
import { useWindowScrollPosition } from "../../../../neon/src/api/pageScroll";
import { NeonNode } from "../../../../neon/src/render/node";
import { fingerprint } from "std/hash";
import { Layers, layersHeight } from "../../../isoline/src/layers";
import { theme } from "../theme";
import { Sample } from "./prose";
import { stageShapes } from "./stageShapes";

struct ShapeField {
	name: string;
	type: string;
	offset: int32;
	size: int32;
	line: int32;
}

struct ShapeAccount {
	name: string;
	tag: string;
	size: int32;
	line: int32;
	fields: ShapeField[];
}

struct ShapeInput {
	name: string;
	checks: string[];
}

struct ShapeInstruction {
	name: string;
	tag: string;
	line: int32;
	accounts: ShapeInput[];
}

struct ShapeError {
	code: int32;
	name: string;
}

struct ProgramShape {
	accounts: ShapeAccount[];
	instructions: ShapeInstruction[];
	errorsLine: int32;
	errors: ShapeError[];
}

struct CounterState {
	program: string;
	authority: string;
	count: string;
}

struct CallReply {
	op: string;
	signature: string;
	ok: boolean;
	failure: string;
	code: int32;
	units: int32;
	before: string;
	after: string;
}

struct Failure {
	failure: string;
}

struct TryCall {
	op: string;
	title: string;
	hint: string;
}

struct Curve {
	top: number;
	height: number;
	d: string;
	end: number;
}

struct StageCard {
	line: int32;
	top: number;
	accounts: ShapeAccount[];
	instructions: ShapeInstruction[];
	errors: ShapeError[];
}

const SHAPES = stageShapes();
const FIELD_TONES = ["#d5d3d1", "#ffa828", "#6cb6ff", "#b78cff", "#5fd4a0", "#f0363a"];
const TONE = "#f0363a";
const PLATE = "#16171a";
const COLUMNS = 8;
const CODE_TOP = 13;
const CODE_LINE = 22;
const CARD = 340;
const WIRE = 64;
const PAD = 16;
const HEAD = 18;
const HEAD_GAP = 12;
const LEGEND = 36;
const ROW = 26;
const CARD_GAP = 12;
const EXPLORER = "https://explorer.solana.com";
const COUNTER_PROGRAM = "7PQcxszNYMSBRWWAxzCXHRPVnbiDLpiHMkMGs3sg8hcM";
const TRY_CALLS: TryCall[] = [
	{ op: "increment", title: "Add one as the authority", hint: "the wallet that made it signs" },
	{ op: "stranger", title: "Add one as a stranger", hint: "any other wallet signs" },
	{ op: "create", title: "Create it again", hint: "the account exists already" },
];
const STICK = 72 + 24;
const TITLE_MID = 19;
const viewport = useWindowDimensions();
const scroll = useWindowScrollPosition();
let stagedBox: HTMLElement | null = null;
let stagedFirst: number = 0;

extern class HTMLElement {}
extern function pageTop(box: HTMLElement): number from "(#.getBoundingClientRect().top + scrollY)";
extern function boxHeight(box: HTMLElement): number from "(#.getBoundingClientRect().height)";
extern function firstOf(box: HTMLElement): HTMLElement from "(#.firstElementChild)";
extern function readCounter(done: (text: string) => void): void
	from "import('devnet-relay').then(relay => relay.readCounter(#))";
extern function sendCall(op: string, done: (text: string) => void): void
	from "import('devnet-relay').then(relay => relay.sendCall(#, #))";

export const STAGE_COLUMN = CARD + WIRE;
export const roomy = createMemo(() => viewport().width >= 1400);

const s = createStyles({
	staged: { position: "relative" },
	band: {
		position: "absolute",
		left: 0,
		right: 0,
		height: CODE_LINE,
		backgroundColor: "rgba(240, 54, 58, 0.07)",
		pointerEvents: "none",
	},
	bandLit: { backgroundColor: "rgba(240, 54, 58, 0.16)" },
	bandEdge: { position: "absolute", top: 0, bottom: 0, left: 0, width: 2, backgroundColor: TONE },
	column: { position: "absolute", top: 0, left: -STAGE_COLUMN, width: CARD },
	columnInline: { marginBottom: 24 },
	card: {
		position: "absolute",
		left: 0,
		right: 0,
		paddingTop: PAD,
		paddingBottom: PAD,
		paddingLeft: PAD + 4,
		paddingRight: PAD + 4,
		borderWidth: 1,
		borderColor: "#202125",
		borderRadius: 6,
		backgroundColor: PLATE,
		fontFamily: theme.mono,
		fontSize: 12,
		color: "#b4b1af",
	},
	cardInline: { position: "relative", marginBottom: CARD_GAP },
	wire: { position: "absolute", left: CARD },
	head: {
		flexDirection: "row",
		justifyContent: "space-between",
		alignItems: "center",
		height: HEAD,
		marginBottom: HEAD_GAP,
		fontSize: 11,
		fontWeight: "600",
		letterSpacing: 1.4,
		color: TONE,
	},
	tag: { fontWeight: "400", letterSpacing: 0.5, color: "#6b6966" },
	figure: { flexDirection: "row", gap: 16 },
	legend: { flex: 1, minWidth: 0 },
	field: { height: LEGEND, justifyContent: "center", cursor: "pointer" },
	fieldName: { color: "#b4b1af" },
	fieldType: { fontSize: 11, color: "#4c4f53" },
	row: { flexDirection: "row", alignItems: "center", gap: 10, height: ROW },
	input: { width: 104, flexShrink: 0, color: "#d5d3d1" },
	pills: { flexDirection: "row", gap: 6 },
	pill: {
		paddingLeft: 6,
		paddingRight: 6,
		height: 18,
		lineHeight: 18,
		borderRadius: 3,
		fontSize: 10,
		letterSpacing: 0.8,
		variants: {
			kind: {
				signs: { color: "#ffa828", backgroundColor: "rgba(255, 168, 40, 0.14)" },
				writable: { color: "#6cb6ff", backgroundColor: "rgba(108, 182, 255, 0.14)" },
				pda: { color: "#b78cff", backgroundColor: "rgba(183, 140, 255, 0.14)" },
				program: { color: "#5fd4a0", backgroundColor: "rgba(95, 212, 160, 0.14)" },
				op: { color: "#d5d3d1", backgroundColor: "#202125" },
			},
		},
	},
	code: { width: 48, fontSize: 16, fontWeight: "700", color: TONE },
	tryout: { fontSize: 13, lineHeight: 20 },
	about: { marginBottom: 14, color: "#93908d" },
	count: { fontSize: 28, fontWeight: "700", lineHeight: 34, color: "#d5d3d1" },
	link: { color: "#93908d", textDecorationLine: "none" },
	tryCall: {
		marginTop: 8,
		paddingTop: 8,
		paddingBottom: 8,
		paddingLeft: 12,
		paddingRight: 12,
		borderWidth: 1,
		borderColor: "#2a2b30",
		borderRadius: 4,
		cursor: "pointer",
	},
	tryTitle: { color: "#d5d3d1" },
	reply: { marginTop: 12 },
	ok: { color: "#5fd4a0" },
	err: { color: TONE },
});

function shapeOf(code: string): ProgramShape {
	const shape = SHAPES.get(fingerprint(code));
	if (shape == null) {
		const start = code.slice(0, 40);
		throw new Error(`stage: no build-time shape for "${start}", run tools/stage.mjs`);
	}
	const parsed: Result<ProgramShape, string> = JSON.parse<ProgramShape>(shape);
	if (!parsed.ok) { throw new Error(`stage: ${parsed.error}`); }
	return parsed.value;
}

function toneOf(at: number): string {
	return FIELD_TONES[at % FIELD_TONES.length];
}

function groupsOf(account: ShapeAccount): int32[] {
	const groups: int32[] = [];
	for (let at = 0; at < account.fields.length; at++) {
		for (let i = 0; i < account.fields[at].size; i++) { groups.push(at as int32); }
	}
	return groups;
}

function tonesOf(account: ShapeAccount): string[] {
	const tones: string[] = [];
	for (let at = 0; at < account.fields.length; at++) { tones.push(toneOf(at)); }
	return tones;
}

function bytesOf(field: ShapeField): string {
	const end = field.offset + field.size - 1;
	return field.size === 1 ? `${field.offset}` : `${field.offset}–${end}`;
}

function lineTop(line: number): number {
	return CODE_TOP + line * CODE_LINE;
}

function accountHeight(account: ShapeAccount): number {
	return Math.max(layersHeight(account.size, COLUMNS), account.fields.length * LEGEND);
}

function heightOf(card: StageCard): number {
	let inner: number = card.errors.length * ROW;
	for (const account of card.accounts) { inner += accountHeight(account); }
	for (const instruction of card.instructions) { inner += instruction.accounts.length * ROW; }
	return 2 * PAD + 2 + HEAD + HEAD_GAP + inner;
}

function cardsOf(shape: ProgramShape): StageCard[] {
	const cards: StageCard[] = [];
	for (const account of shape.accounts) {
		cards.push({
			line: account.line, top: 0, accounts: [account], instructions: [], errors: [],
		});
	}
	for (const instruction of shape.instructions) {
		cards.push({
			line: instruction.line, top: 0, accounts: [], instructions: [instruction], errors: [],
		});
	}
	if (shape.errors.length > 0) {
		cards.push({
			line: shape.errorsLine, top: 0, accounts: [], instructions: [], errors: shape.errors,
		});
	}
	cards.sort((a, b) => a.line - b.line);
	let free: number = 0;
	for (let at = 0; at < cards.length; at++) {
		cards[at].top = Math.max(lineTop(cards[at].line) - PAD, free);
		free = cards[at].top + heightOf(cards[at]) + CARD_GAP;
	}
	return cards;
}

function pillKind(check: string): string {
	if (check === "SIGNS") { return "signs"; }
	if (check === "WRITABLE") { return "writable"; }
	return check.startsWith("PDA") ? "pda" : "program";
}

function curveOf(from: number, to: number): Curve {
	const top = Math.min(from, to) - 4;
	const height = Math.abs(to - from) + 8;
	const bend = WIRE / 2;
	const start = from - top;
	const end = to - top;
	return { top, height, d: `M 0 ${start} C ${bend} ${start} ${bend} ${end} ${WIRE} ${end}`, end };
}

const [drawn, setDrawn] = createSignal(false);
export const drawFigures = (): void => { setDrawn(true); };

function Lead(props: { curve: Accessor<Curve> }): NeonNode {
	const c = props.curve;
	return <View style={[s.wire, styleOf({ top: c().top, width: WIRE, height: c().height })]}>
		<Show when={drawn()}>
			<Svg width={WIRE} height={c().height} viewBox={`0 0 ${WIRE} ${c().height}`}>
				<Path d={c().d} fill="none" stroke={TONE} strokeOpacity={0.55} strokeWidth={1} />
				<Circle cx={WIRE - 2} cy={c().end} r={2} fill={TONE} />
			</Svg>
		</Show>
	</View>;
}

function Account(props: {
	account: ShapeAccount;
	lit: Accessor<number>;
	pick: (at: number) => void;
}): NeonNode {
	const tones = tonesOf(props.account);
	const nameStyle = (at: number) =>
		props.lit() === at ? styleOf({ color: tones[at] }) : s.fieldName;
	return <>
		<View style={s.head}>
			<span>ACCOUNT · {props.account.name}</span>
			<span style={s.tag}>{props.account.size} BYTES</span>
		</View>
		<View style={s.figure}>
			<Show when={drawn()}>
				<Layers
					groups={groupsOf(props.account)}
					columns={COLUMNS}
					tones={tones}
					lit={props.lit}
					palette={{ plate: PLATE, line: "#4c4f53" }}
					label={`The ${props.account.size} bytes of ${props.account.name},`
						+ " eight to a layer"}
				/>
			</Show>
			<View style={s.legend}>
				<For each={props.account.fields}>
					{(field: ShapeField, at: () => number): NeonNode => <Pressable
						style={s.field}
						accessibilityLabel={field.name}
						onPress={(): void => { props.pick(at()); }}
					>
						<Text style={nameStyle(at())}>
							{field.name}
						</Text>
						<Text style={s.fieldType}>{field.type} · {bytesOf(field)}</Text>
					</Pressable>}
				</For>
			</View>
		</View>
	</>;
}

function Instruction(props: { instruction: ShapeInstruction }): NeonNode {
	return <>
		<View style={s.head}>
			<span>CALL · {props.instruction.name}</span>
			<span style={s.tag}>{props.instruction.tag}</span>
		</View>
		<For each={props.instruction.accounts}>
			{(input: ShapeInput): NeonNode => <View style={s.row}>
				<Text style={s.input}>{input.name}</Text>
				<View style={s.pills}>
					<For each={input.checks}>
						{(check: string): NeonNode =>
							<Text style={s.pill({ kind: pillKind(check) })}>{check}</Text>}
					</For>
				</View>
			</View>}
		</For>
	</>;
}

function Errors(props: { errors: ShapeError[] }): NeonNode {
	return <>
		<View style={s.head}><span>ERRORS</span></View>
		<For each={props.errors}>
			{(error: ShapeError): NeonNode => <View style={s.row}>
				<Text style={s.code}>{error.code}</Text>
				<Text style={s.input}>{error.name}</Text>
			</View>}
		</For>
	</>;
}

export function Staged(props: { code: string; idl: string }): NeonNode {
	const shape = shapeOf(props.code);
	if (shape.accounts.length !== 1) {
		const count = shape.accounts.length;
		throw new Error(`stage: a staged program has one account type, not ${count}`);
	}
	const cards = cardsOf(shape);
	const fields = shape.accounts[0].fields;
	const [lit, setLit] = createSignal<number>(-1);
	const pick = (at: number): void => { setLit(lit() === at ? -1 : at); };
	const litLine = (): number => lit() < 0 ? 0 : fields[lit()].line;
	const litTone = (): string => lit() < 0 ? TONE : toneOf(lit());
	let held: HTMLElement | null = null;
	const tops = createMemo((): number[] => {
		const y = scroll().y;
		const placed: number[] = [];
		for (const card of cards) { placed.push(card.top); }
		if (!roomy() || held === null) { return placed; }
		const line = y + STICK - pageTop(held);
		const end = boxHeight(held);
		for (let at = 0; at < cards.length; at++) {
			const next = at + 1 < cards.length ? cards[at + 1].top - CARD_GAP : end;
			placed[at] = Math.max(cards[at].top, Math.min(line, next - heightOf(cards[at])));
		}
		return placed;
	});
	const wireOf = (at: number): Curve =>
		curveOf(PAD + HEAD / 2, lineTop(cards[at].line) + CODE_LINE / 2 - tops()[at]);
	const placedStyle = (at: number): Style =>
		roomy() ? styleOf({ top: tops()[at] }) : s.cardInline;
	const hold = (handle: ViewHandle): void => {
		held = handle.node as unknown as HTMLElement;
		stagedBox = held;
		stagedFirst = cards[0].top;
	};
	return <View style={s.staged} ref={hold}>
		<Sample code={props.code} />
		<Show when={roomy()}>
			<For each={cards}>
				{(card: StageCard): NeonNode =>
					<View style={[s.band, styleOf({ top: lineTop(card.line) })]}>
						<View style={s.bandEdge} />
					</View>}
			</For>
			<Show when={lit() >= 0}>
				<View style={[s.band, s.bandLit, styleOf({ top: lineTop(litLine()) })]}>
					<View style={[s.bandEdge, styleOf({ backgroundColor: litTone() })]} />
				</View>
			</Show>
		</Show>
		<View style={roomy() ? s.column : s.columnInline}>
			<For each={cards}>
				{(card: StageCard, at: () => number): NeonNode =>
					<View style={[s.card, placedStyle(at())]}>
						<Show when={roomy()}><Lead curve={wireOf(at())} /></Show>
						<For each={card.accounts}>
							{(shown: ShapeAccount): NeonNode =>
								<Account account={shown} lit={lit} pick={pick} />}
						</For>
						<For each={card.instructions}>
							{(instruction: ShapeInstruction): NeonNode =>
								<Instruction instruction={instruction} />}
						</For>
						<Show when={card.errors.length > 0}><Errors errors={card.errors} /></Show>
					</View>}
			</For>
		</View>
	</View>;
}

function shortOf(key: string): string {
	return key.length > 12 ? `${key.slice(0, 4)}…${key.slice(key.length - 4)}` : key;
}

function explorerOf(path: string): string {
	return `${EXPLORER}/${path}?cluster=devnet`;
}

function failureIn(text: string): string {
	const parsed: Result<Failure, string> = JSON.parse<Failure>(text);
	return parsed.ok ? parsed.value.failure : text;
}

function outcomeOf(reply: CallReply, errors: ShapeError[]): string {
	if (reply.ok) { return `${reply.before} → ${reply.after} · ${reply.units} CU`; }
	const known = errors.find((error: ShapeError): boolean => error.code === reply.code);
	return known == null ? reply.failure : `#${reply.code} ${known.name}`;
}

export function Tryout(props: { code: string; children: NeonNode }): NeonNode {
	const errors = shapeOf(props.code).errors;
	const [state, setState] = createSignal<CounterState>({
		program: COUNTER_PROGRAM, authority: "", count: "…",
	});
	const [note, setNote] = createSignal<string>("reading the counter from devnet…");
	const [busy, setBusy] = createSignal<boolean>(false);
	const [replies, setReplies] = createSignal<CallReply[]>([]);
	const read = (text: string): void => {
		const parsed: Result<CounterState, string> = JSON.parse<CounterState>(text);
		if (parsed.ok) { setState(parsed.value); setNote(""); } else { setNote(failureIn(text)); }
	};
	const answered = (text: string): void => {
		setBusy(false);
		const parsed: Result<CallReply, string> = JSON.parse<CallReply>(text);
		if (!parsed.ok) { setNote(failureIn(text)); return; }
		setNote("");
		setReplies([parsed.value, ...replies()].slice(0, 3));
		readCounter(read);
	};
	const send = (op: string): void => {
		if (busy()) { return; }
		setBusy(true);
		setNote("sending, waiting for devnet to confirm…");
		sendCall(op, answered);
	};
	const from = PAD + HEAD / 2;
	let held: HTMLElement | null = null;
	let shown: HTMLElement | null = null;
	const placed = createMemo((): number[] => {
		const y = scroll().y;
		if (!roomy() || held === null || shown === null) {
			return [TITLE_MID - from, TITLE_MID];
		}
		const top = pageTop(held);
		const lead = pageTop(firstOf(held)) + boxHeight(firstOf(held)) / 2 - top;
		const line = y + STICK - top;
		const height = boxHeight(shown);
		if (stagedBox === null) { return [Math.max(lead - from, line), lead]; }
		const next = pageTop(stagedBox) + stagedFirst - CARD_GAP - top;
		return [Math.max(lead - from, Math.min(line, next - height)), lead];
	});
	const lead = createMemo((): Curve => curveOf(from, placed()[1] - placed()[0]));
	const hold = (handle: ViewHandle): void => { held = handle.node as unknown as HTMLElement; };
	return <View style={s.staged} ref={hold}>
		{props.children}
		<View style={roomy() ? s.column : s.columnInline}>
			<View
				style={[s.card, s.tryout, roomy() ? styleOf({ top: placed()[0] }) : s.cardInline]}
				ref={(handle: ViewHandle): void => {
					shown = handle.node as unknown as HTMLElement;
					readCounter(read);
				}}
			>
				<Show when={roomy()}><Lead curve={lead} /></Show>
				<View style={s.head}>
					<span>TRY IT ON DEVNET</span>
					<a style={[s.tag, s.link]} href={explorerOf(`address/${state().program}`)}>
						program ↗
					</a>
				</View>
				<Text style={s.about}>
					This counter is deployed on Solana's devnet. Each button sends a real
					transaction and shows what the program answered.
				</Text>
				<View style={s.row}>
					<Text style={s.input}>count</Text>
					<Text style={s.count}>{state().count}</Text>
				</View>
				<View style={s.row}>
					<Text style={s.input}>authority</Text>
					<Text>{shortOf(state().authority)}</Text>
				</View>
				<For each={TRY_CALLS}>
					{(tried: TryCall): NeonNode => <Pressable
						style={s.tryCall}
						accessibilityLabel={tried.title}
						onPress={(): void => { send(tried.op); }}
					>
						<Text style={s.tryTitle}>▸ {tried.title}</Text>
						<Text style={s.fieldType}>{tried.op} · {tried.hint}</Text>
					</Pressable>}
				</For>
				<Show when={note() !== ""}><Text style={s.about}>{note()}</Text></Show>
				<For each={replies()}>
					{(reply: CallReply): NeonNode => <View style={s.reply}>
						<Text style={reply.ok ? s.ok : s.err}>
							{reply.ok ? "✓" : "✗"} {reply.op} · {outcomeOf(reply, errors)}
						</Text>
						<a style={s.link} href={explorerOf(`tx/${reply.signature}`)}>
							{shortOf(reply.signature)} on the explorer ↗
						</a>
					</View>}
				</For>
			</View>
		</View>
	</View>;
}
