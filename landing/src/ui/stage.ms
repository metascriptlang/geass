import { createMemo } from "../../../../neon/src/core/memo";
import { For } from "../../../../neon/src/macros/ui/flow";
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
	fields: ShapeField[];
}

struct ShapeInput {
	name: string;
	checks: string;
}

struct ShapeInstruction {
	name: string;
	tag: string;
	accounts: ShapeInput[];
}

struct ShapeError {
	code: int32;
	name: string;
}

struct ProgramShape {
	accounts: ShapeAccount[];
	instructions: ShapeInstruction[];
	errors: ShapeError[];
}

const SHAPES = stageShapes();
const SEGMENTS = ["#4c4f53", "#f0363a", "#ffa828", "#6cb6ff", "#b78cff", "#5fd4a0"];
const viewport = useWindowDimensions();
const roomy = createMemo(() => viewport().width >= 1440);

const s = createStyles({
	staged: { position: "relative" },
	stage: {
		position: "absolute",
		top: 0,
		left: "calc(100% + 40px)",
		width: 380,
		paddingTop: 16,
		paddingBottom: 16,
		paddingLeft: 16,
		paddingRight: 16,
		borderWidth: 1,
		borderColor: theme.line,
		borderRadius: 6,
		backgroundColor: "#121417",
		fontFamily: theme.mono,
		fontSize: 12,
		lineHeight: 20,
		color: "#b4b1af",
		variants: { layout: { inline: { position: "relative", left: 0, width: "auto", marginBottom: 24 } } },
	},
	label: { fontSize: 10, letterSpacing: 2, color: "#6b6966" },
	head: { flexDirection: "row", justifyContent: "space-between", marginTop: 14, color: "#d5d3d1" },
	tag: { color: "#6b6966" },
	bar: { flexDirection: "row", height: 10, marginTop: 8, marginBottom: 8, gap: 2 },
	row: { flexDirection: "row", gap: 12 },
	at: { width: 28, flexShrink: 0, textAlign: "right", color: "#6b6966" },
	name: { width: 132, flexShrink: 0, color: "#d5d3d1" },
	type: { flex: 1, minWidth: 0 },
	size: { width: 24, flexShrink: 0, textAlign: "right", color: "#6b6966" },
});

function shapeOf(code: string): ProgramShape {
	const shape = SHAPES.get(fingerprint(code));
	if (shape == null) {
		throw new Error(`stage: no build-time shape for "${code.slice(0, 40)}", run tools/stage.mjs`);
	}
	const parsed: Result<ProgramShape, string> = JSON.parse<ProgramShape>(shape);
	if (!parsed.ok) { throw new Error(`stage: ${parsed.error}`); }
	return parsed.value;
}

function Account(props: { account: ShapeAccount }): NeonNode {
	return <>
		<View style={s.head}>
			<span>ACCOUNT {props.account.name}</span>
			<span style={s.tag}>{props.account.size} BYTES</span>
		</View>
		<View style={s.bar}>
			<For each={props.account.fields}>
				{(field: ShapeField, at: () => number): NeonNode => <View
					style={{ flex: field.size, backgroundColor: SEGMENTS[at() % SEGMENTS.length] }}
				/>}
			</For>
		</View>
		<For each={props.account.fields}>
			{(field: ShapeField, at: () => number): NeonNode => <View style={s.row}>
				<Text style={s.at}>{field.offset}</Text>
				<Text style={[s.name, { color: SEGMENTS[at() % SEGMENTS.length] }]}>{field.name}</Text>
				<Text style={s.type}>{field.type}</Text>
				<Text style={s.size}>{field.size}</Text>
			</View>}
		</For>
	</>;
}

function Instruction(props: { instruction: ShapeInstruction }): NeonNode {
	return <>
		<View style={s.head}>
			<span>CALL {props.instruction.name}</span>
			<span style={s.tag}>{props.instruction.tag}</span>
		</View>
		<For each={props.instruction.accounts}>
			{(input: ShapeInput): NeonNode => <View style={s.row}>
				<Text style={s.name}>{input.name}</Text>
				<Text style={s.type}>{input.checks}</Text>
			</View>}
		</For>
	</>;
}

export function Staged(props: { code: string; idl: string }): NeonNode {
	const shape = shapeOf(props.code);
	return <View style={s.staged}>
		<Sample code={props.code} />
		<View style={s.stage({ layout: roomy() ? "" : "inline" })}>
			<span style={s.label}>AS CLIENTS SEE IT · FROM ITS IDL</span>
			<For each={shape.accounts}>
				{(account: ShapeAccount): NeonNode => <Account account={account} />}
			</For>
			<For each={shape.instructions}>
				{(instruction: ShapeInstruction): NeonNode => <Instruction instruction={instruction} />}
			</For>
			<View style={s.head}><span>ERRORS</span></View>
			<For each={shape.errors}>
				{(error: ShapeError): NeonNode => <View style={s.row}>
					<Text style={s.name}>{error.code}</Text>
					<Text style={s.type}>{error.name}</Text>
				</View>}
			</For>
		</View>
	</View>;
}
