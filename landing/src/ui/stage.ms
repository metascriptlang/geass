import { createMemo } from "../../../../neon/src/core/memo";
import { For, Show } from "../../../../neon/src/macros/ui/flow";
import { createStyles, styleOf } from "../../../../neon/src/macros/ui/style";
import { Text, View } from "../../../../neon/src/components/primitives";
import { useWindowDimensions } from "../../../../neon/src/render/environment";
import { NeonNode } from "../../../../neon/src/render/node";
import { fingerprint } from "std/hash";
import { theme } from "../theme";
import { Sample } from "./prose";
import { stageShapes } from "./stageShapes";

struct ShapeField {
	name: string;
	type: string;
	offset: int32;
	size: int32;
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

struct StageByte {
	color: string;
	label: string;
}

struct StageCard {
	line: int32;
	top: number;
	accounts: ShapeAccount[];
	instructions: ShapeInstruction[];
	errors: ShapeError[];
}

const SHAPES = stageShapes();
const FIELD_TONES = ["#6b6966", "#ffa828", "#6cb6ff", "#b78cff", "#5fd4a0", "#f0363a"];
const TONE = "#f0363a";
const CODE_TOP = 13;
const CODE_LINE = 22;
const PAD = 16;
const HEAD = 18;
const HEAD_GAP = 12;
const SQUARE = 24;
const SQUARE_GAP = 3;
const LEGEND = 18;
const ROW = 26;
const CARD_GAP = 12;
const viewport = useWindowDimensions();
const roomy = createMemo(() => viewport().width >= 1440);

const s = createStyles({
	staged: { position: "relative" },
	band: {
		position: "absolute",
		left: 0,
		right: 0,
		height: CODE_LINE,
		backgroundColor: "rgba(240, 54, 58, 0.09)",
		pointerEvents: "none",
	},
	bandEdge: { position: "absolute", top: 0, bottom: 0, left: 0, width: 2, backgroundColor: TONE },
	column: { position: "absolute", top: 0, left: "calc(100% + 40px)", width: 380 },
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
		borderColor: theme.line,
		borderRadius: 6,
		backgroundColor: "#131417",
		fontFamily: theme.mono,
		fontSize: 12,
		color: "#b4b1af",
	},
	cardInline: { position: "relative", marginBottom: CARD_GAP },
	wire: { position: "absolute", backgroundColor: "rgba(240, 54, 58, 0.5)" },
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
	grid: {
		flexDirection: "row",
		flexWrap: "wrap",
		gap: SQUARE_GAP,
		width: 8 * SQUARE + 7 * SQUARE_GAP,
		marginBottom: HEAD_GAP,
	},
	square: {
		width: SQUARE,
		height: SQUARE,
		paddingTop: 2,
		paddingLeft: 3,
		borderRadius: 3,
		fontSize: 9,
		lineHeight: 10,
		color: "rgba(12, 13, 15, 0.75)",
	},
	legend: { flexDirection: "row", alignItems: "center", gap: 10, height: LEGEND },
	dot: { width: 8, height: 8, borderRadius: 2 },
	legendName: { width: 104, color: "#d5d3d1" },
	legendType: { flex: 1 },
	legendBytes: { color: "#6b6966" },
	row: { flexDirection: "row", alignItems: "center", gap: 10, height: ROW },
	input: { width: 112, flexShrink: 0, color: "#d5d3d1" },
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
			},
		},
	},
	code: { width: 48, fontSize: 16, fontWeight: "700", color: TONE },
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

function fieldTone(at: number): string {
	return FIELD_TONES[at % FIELD_TONES.length];
}

function bytesOf(account: ShapeAccount): StageByte[] {
	const bytes: StageByte[] = [];
	for (let at = 0; at < account.fields.length; at++) {
		const field = account.fields[at];
		for (let i = 0; i < field.size; i++) {
			bytes.push({ color: fieldTone(at), label: i === 0 ? `${field.offset}` : "" });
		}
	}
	return bytes;
}

function heightOf(card: StageCard): number {
	let inner: number = card.errors.length * ROW;
	for (const account of card.accounts) {
		const rows = Math.ceil(account.size / 8);
		inner += rows * SQUARE + (rows - 1) * SQUARE_GAP + HEAD_GAP;
		inner += account.fields.length * LEGEND;
	}
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
		cards[at].top = Math.max(CODE_TOP + cards[at].line * CODE_LINE - PAD, free);
		free = cards[at].top + heightOf(cards[at]) + CARD_GAP;
	}
	return cards;
}

function pillKind(check: string): string {
	if (check === "SIGNS") { return "signs"; }
	if (check === "WRITABLE") { return "writable"; }
	return check.startsWith("PDA") ? "pda" : "program";
}

function Wire(props: { card: StageCard }): NeonNode {
	const from = CODE_TOP + props.card.line * CODE_LINE + CODE_LINE / 2 - props.card.top;
	const to = PAD + HEAD / 2;
	const drop = Math.abs(to - from) + 1;
	return <>
		<View style={[s.wire, { top: from, left: -41, width: 20, height: 1 }]} />
		<View style={[s.wire, { top: Math.min(from, to), left: -21, width: 1, height: drop }]} />
		<View style={[s.wire, { top: to, left: -21, width: 20, height: 1 }]} />
	</>;
}

function Account(props: { account: ShapeAccount }): NeonNode {
	return <>
		<View style={s.head}>
			<span>ACCOUNT · {props.account.name}</span>
			<span style={s.tag}>{props.account.size} BYTES</span>
		</View>
		<View style={s.grid}>
			<For each={bytesOf(props.account)}>
				{(cell: StageByte): NeonNode =>
					<Text style={[s.square, { backgroundColor: cell.color }]}>{cell.label}</Text>}
			</For>
		</View>
		<For each={props.account.fields}>
			{(field: ShapeField, at: () => number): NeonNode => <View style={s.legend}>
				<View style={[s.dot, { backgroundColor: fieldTone(at()) }]} />
				<Text style={s.legendName}>{field.name}</Text>
				<Text style={s.legendType}>{field.type}</Text>
				<Text style={s.legendBytes}>
					{field.size === 1
						? `byte ${field.offset}`
						: `bytes ${field.offset}–${field.offset + field.size - 1}`}
				</Text>
			</View>}
		</For>
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
	const cards = cardsOf(shapeOf(props.code));
	return <View style={s.staged}>
		<Sample code={props.code} />
		<Show when={roomy()}>
			<For each={cards}>
				{(card: StageCard): NeonNode =>
					<View style={[s.band, { top: CODE_TOP + card.line * CODE_LINE }]}>
						<View style={s.bandEdge} />
					</View>}
			</For>
		</Show>
		<View style={roomy() ? s.column : s.columnInline}>
			<For each={cards}>
				{(card: StageCard): NeonNode =>
					<View style={[s.card, roomy() ? styleOf({ top: card.top }) : s.cardInline]}>
						<Show when={roomy()}><Wire card={card} /></Show>
						<For each={card.accounts}>
							{(account: ShapeAccount): NeonNode => <Account account={account} />}
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
