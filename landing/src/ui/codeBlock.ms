import { For } from "../../../../neon/src/macros/ui/flow";
import { createStyles, styleOf } from "../../../../neon/src/macros/ui/style";
import { Text, View } from "../../../../neon/src/components/primitives";
import { NeonNode } from "../../../../neon/src/render/node";
import { theme } from "../theme";
import { codeColors, codePaints } from "./codePaint";

struct CodeToken {
	content: string;
	color: string;
}

struct CodeLine {
	tokens: CodeToken[];
}

struct CodeRuns {
	runs: int32[];
}

struct CodePaint {
	lines: CodeRuns[];
}

const COLORS = codeColors();
const PAINTS = codePaints();

const c = createStyles({
	block: {
		paddingTop: 12,
		paddingBottom: 12,
		paddingLeft: 16,
		paddingRight: 16,
		borderWidth: 1,
		borderColor: theme.line,
		backgroundColor: "rgba(12, 13, 15, 0.86)",
		fontFamily: "'Berkeley Mono', " + theme.mono,
		borderRadius: 6,
		fontSize: 14,
		lineHeight: 22,
		color: theme.ink,
	},
	line: { width: "max-content", minHeight: 22 },
});

function painted(code: string): CodeLine[] {
	const paint = PAINTS.get(code);
	if (paint == null) {
		throw new Error(`code block: no build-time paint for "${code.slice(0, 40)}", run tools/paint.mjs`);
	}
	const parsed: Result<CodePaint, string> = JSON.parse<CodePaint>(paint);
	if (!parsed.ok) { throw new Error(`code block: ${parsed.error}`); }
	const texts = code.split("\n");
	let lines: CodeLine[] = [];
	for (let i = 0; i < texts.length; i++) {
		const runs = parsed.value.lines[i].runs;
		let tokens: CodeToken[] = [];
		let at = 0;
		for (let r = 0; r < runs.length; r += 2) {
			const end = at + runs[r + 1];
			tokens.push({ content: texts[i].slice(at, end), color: COLORS[runs[r]] });
			at = end;
		}
		lines.push({ tokens: texts[i] === "" ? [{ content: "\n", color: "" }] : tokens });
	}
	return lines;
}

export function CodeBlock(props: { code: string }): NeonNode {
	return <View style={c.block}>
		<For each={painted(props.code)}>
			{(line: CodeLine): NeonNode => <Text style={c.line}>
				<For each={line.tokens}>
					{(token: CodeToken): NeonNode =>
						<span style={{ color: token.color }}>{token.content}</span>}
				</For>
			</Text>}
		</For>
	</View>;
}
