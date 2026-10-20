import { createMemo } from "../../../../neon/src/core/memo";
import { Accessor } from "../../../../neon/src/core/signal";
import { For, Show } from "../../../../neon/src/macros/ui/flow";
import { createStyles, styleOf } from "../../../../neon/src/macros/ui/style";
import { Pressable, Text, View } from "../../../../neon/src/components/primitives";
import { Circle, Path, Svg } from "../../../../neon/src/components/svg/elements";
import { useWindowDimensions } from "../../../../neon/src/render/environment";
import { NeonNode } from "../../../../neon/src/render/node";
import { fingerprint } from "std/hash";
import { Layers, layersHeight } from "../../../isoline/src/layers";
import { createTour } from "../../../isoline/src/tour";
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
const TOUR_MS = 1800;
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
const viewport = useWindowDimensions();

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
	fieldName: { color: "#6b6966" },
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

function Wire(props: { card: StageCard }): NeonNode {
	const from = PAD + HEAD / 2;
	const to = lineTop(props.card.line) + CODE_LINE / 2 - props.card.top;
	const top = Math.min(from, to) - 4;
	const height = Math.abs(to - from) + 8;
	const bend = WIRE / 2;
	const start = from - top;
	const end = to - top;
	const curve = `M 0 ${start} C ${bend} ${start} ${bend} ${end} ${WIRE} ${end}`;
	return <View style={[s.wire, styleOf({ top, width: WIRE, height })]}>
		<Svg width={WIRE} height={height} viewBox={`0 0 ${WIRE} ${height}`}>
			<Path d={curve} fill="none" stroke={TONE} strokeOpacity={0.55} strokeWidth={1} />
			<Circle cx={WIRE - 2} cy={end} r={2} fill={TONE} />
		</Svg>
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
			<Layers
				groups={groupsOf(props.account)}
				columns={COLUMNS}
				tones={tones}
				lit={props.lit}
				palette={{ plate: PLATE, line: "#4c4f53" }}
				label={`The ${props.account.size} bytes of ${props.account.name}, eight to a layer`}
			/>
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
	const [lit, pick] = createTour(fields.length, TOUR_MS);
	return <View style={s.staged}>
		<Sample code={props.code} />
		<Show when={roomy()}>
			<For each={cards}>
				{(card: StageCard): NeonNode =>
					<View style={[s.band, styleOf({ top: lineTop(card.line) })]}>
						<View style={s.bandEdge} />
					</View>}
			</For>
			<View style={[s.band, s.bandLit, styleOf({ top: lineTop(fields[lit()].line) })]}>
				<View style={[s.bandEdge, styleOf({ backgroundColor: toneOf(lit()) })]} />
			</View>
		</Show>
		<View style={roomy() ? s.column : s.columnInline}>
			<For each={cards}>
				{(card: StageCard): NeonNode =>
					<View style={[s.card, roomy() ? styleOf({ top: card.top }) : s.cardInline]}>
						<Show when={roomy()}><Wire card={card} /></Show>
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
