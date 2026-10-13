import { createSignal } from "../../../../neon/src/core/signal";
import { For } from "../../../../neon/src/macros/ui/flow";
import { createStyles, styleOf } from "../../../../neon/src/macros/ui/style";
import { Text, View } from "../../../../neon/src/components/primitives";
import { NeonNode } from "../../../../neon/src/render/node";
import { theme } from "../theme";

struct CodeToken {
	content: string;
	color: string;
}

struct CodeLine {
	tokens: CodeToken[];
}

struct CodePaint {
	lines: CodeLine[];
}

extern function highlightMetaScript(code: string, done: (lines: string) => void): void
	from "((code, done) => { if (typeof document === 'undefined') { return; } (globalThis.geassHighlighter ??= Promise.all([import('shiki/core'), import('shiki/engine/javascript'), import('code-block-theme'), import('metascript-grammar')]).then(([core, engine, colors, grammar]) => core.createHighlighterCore({ themes: [colors.default], langs: [{ ...grammar.default, name: 'metascript' }], engine: engine.createJavaScriptRegexEngine() }))).then((shiki) => done(JSON.stringify({ lines: shiki.codeToTokens(code, { lang: 'metascript', theme: 'nerdtools-night' }).tokens.map((line) => ({ tokens: line.some((token) => token.content) ? line.map((token) => ({ content: token.content.replace(/\\t/g, '    '), color: token.color ?? '' })) : [{ content: '\\n', color: '' }] })) }))); })(#, #)";

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

function unpainted(code: string): CodeLine[] {
	let lines: CodeLine[] = [];
	for (const text of code.split("\n")) {
		const content = text === "" ? "\n" : text.replaceAll("\t", "    ");
		lines.push({ tokens: [{ content: content, color: "" }] });
	}
	return lines;
}

export function CodeBlock(props: { code: string }): NeonNode {
	const [lines, setLines] = createSignal<CodeLine[]>(unpainted(props.code));
	highlightMetaScript(props.code, (painted: string): void => {
		const parsed: Result<CodePaint, string> = JSON.parse<CodePaint>(painted);
		if (!parsed.ok) { console.error(`code block: ${parsed.error}`); return; }
		setLines(parsed.value.lines);
	});
	return <View style={c.block}>
		<For each={lines()}>
			{(line: CodeLine): NeonNode => <Text style={c.line}>
				<For each={line.tokens}>
					{(token: CodeToken): NeonNode =>
						<span style={{ color: token.color }}>{token.content}</span>}
				</For>
			</Text>}
		</For>
	</View>;
}
