import { createSignal } from "../../../../neon/src/core/signal";
import { createStyles, styleOf } from "../../../../neon/src/macros/ui/style";
import { Pressable, Text, View } from "../../../../neon/src/components/primitives";
import { NeonNode } from "../../../../neon/src/render/node";
import { Style } from "../../../../neon/src/render/style";
import { Clipboard } from "../../../../neon/src/api/clipboard";
import { theme } from "../theme";
import { CodeBlock } from "./codeBlock";
import { Hairline } from "./decor";
import { PageAbout, PageTitle } from "./pageHead";

const COPIED_MS = 1600;

const ICON = "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24'" +
	" height='24' viewBox='0 0 24 24'%3E%3Cpath fill='none' stroke-width='1.5' ";
const ICON_END = "/%3E%3C/svg%3E\")";
const COPY_ICON = ICON +
	"stroke='%2393908d' d='M6 9.75h8.25V18H6zM9.75 9.75V6H18v8.25h-3.75'" + ICON_END;
const COPIED_ICON = ICON + "stroke='%23f0363a' d='M5 12l5 5 9-9'" + ICON_END;

export const tone = createStyles({
	start: { color: theme.signal },
	core: { color: "#ffa828" },
	build: { color: "#6cb6ff" },
	chain: { color: "#b78cff" },
	reference: { color: "#5fd4a0" },
});

const p = createStyles({
	title: {
		margin: 0,
		marginBottom: 20,
		fontFamily: theme.display,
		fontSize: 40,
		lineHeight: 38,
		fontWeight: "700",
		letterSpacing: -0.5,
	},
	lede: {
		margin: 0,
		marginBottom: 28,
		fontFamily: theme.display,
		fontSize: 20,
		lineHeight: 25,
		fontWeight: "700",
		color: "#b4b1af",
	},
	heading: {
		position: "relative",
		margin: 0,
		marginTop: 28,
		marginBottom: 16,
		fontFamily: theme.display,
		fontSize: 20,
		lineHeight: 25,
		fontWeight: "700",
		color: "#d5d3d1",
	},
	link: { color: "#d5d3d1", textDecorationLine: "underline" },
	subheading: {
		position: "relative",
		margin: 0,
		marginBottom: 12,
		fontFamily: theme.display,
		fontSize: 16,
		lineHeight: 24,
		fontWeight: "700",
		color: "#d5d3d1",
	},
	anchor: { position: "absolute", top: "-96px" },
	text: { margin: 0, marginBottom: 24, fontSize: 16, lineHeight: 24, color: "#b4b1af" },
	mark: {
		paddingTop: 2,
		paddingBottom: 2,
		paddingLeft: 4,
		paddingRight: 4,
		borderRadius: 4,
		backgroundColor: "#1f2023",
		fontFamily: theme.mono,
		fontSize: 14,
	},
	code: { position: "relative", marginBottom: 24 },
	scroll: { overflow: "scroll" },
	copy: {
		position: "absolute",
		top: 1,
		right: 1,
		width: 44,
		height: 44,
		alignItems: "center",
		justifyContent: "center",
		borderRadius: 5,
		backgroundColor: "#0c0d0f",
		cursor: "pointer",
	},
	copyIcon: {
		width: 24,
		height: 24,
		backgroundImage: COPY_ICON,
		variants: { state: { copied: { backgroundImage: COPIED_ICON } } },
	},
	note: {
		marginBottom: 24,
		paddingTop: 12,
		paddingBottom: 12,
		paddingLeft: 18,
		paddingRight: 16,
		backgroundColor: "#121417",
		fontSize: 16,
		lineHeight: 24,
		color: "#b4b1af",
	},
	noteEdge: {
		position: "absolute",
		top: 0,
		bottom: 0,
		left: 0,
		width: 2,
		backgroundColor: "#6cb6ff",
		variants: { kind: { warning: { backgroundColor: "#ffa828" } } },
	},
	noteLabel: {
		marginBottom: 4,
		fontFamily: theme.mono,
		fontSize: 12,
		fontWeight: "600",
		letterSpacing: 1.2,
		color: "#6cb6ff",
		variants: { kind: { warning: { color: "#ffa828" } } },
	},
	noteText: { margin: 0 },
	table: { marginBottom: 28 },
	row: {
		flexDirection: "row",
		gap: 24,
		paddingTop: 12,
		paddingBottom: 12,
		fontSize: 16,
		lineHeight: 24,
		color: "#b4b1af",
	},
	rowHead: {
		paddingTop: 4,
		fontFamily: theme.mono,
		fontSize: 12,
		lineHeight: 18,
		fontWeight: "600",
		letterSpacing: 1.2,
		color: "#93908d",
	},
	cellName: { width: "38%", flexShrink: 0 },
	cellMono: { fontFamily: theme.mono, fontSize: 14, color: "#d5d3d1" },
	cellText: { flex: 1, minWidth: 0 },
});

export function Title(props: { title: string; tone: Style }): NeonNode {
	return <>
		<PageTitle title={props.title + " · Geass docs"} />
		<h1 style={[p.title, props.tone]}>{props.title}</h1>
	</>;
}

export function Lede(props: { t: string }): NeonNode {
	return <>
		<PageAbout about={props.t} />
		<p style={p.lede}>{props.t}</p>
	</>;
}

export function Heading(props: { at: string; title: string }): NeonNode {
	return <h2 style={p.heading}>{props.title}<span id={props.at} style={p.anchor} /></h2>;
}

export function Subheading(props: { at: string; title: string }): NeonNode {
	return <h3 style={p.subheading}>{props.title}<span id={props.at} style={p.anchor} /></h3>;
}

export function P(props: { children: NeonNode }): NeonNode {
	return <p style={p.text}>{props.children}</p>;
}

export function M(props: { t: string }): NeonNode {
	return <Text style={p.mark}>{props.t}</Text>;
}

export function L(props: { to: string; t: string }): NeonNode {
	return <a style={p.link} href={props.to}>{props.t}</a>;
}

export function Sample(props: { code: string }): NeonNode {
	const [copied, setCopied] = createSignal(false);
	return <View style={p.code}>
		<View style={p.scroll}><CodeBlock code={props.code} /></View>
		<Pressable
			style={p.copy}
			accessibilityLabel={copied() ? "Copied" : "Copy"}
			onPress={(): void => {
				Clipboard.setString(props.code);
				setCopied(true);
				setTimeout((): void => { setCopied(false); }, COPIED_MS);
			}}
		>
			<View style={p.copyIcon({ state: copied() ? "copied" : "" })} />
		</Pressable>
	</View>;
}

export function Note(props: { children: NeonNode }): NeonNode {
	return <View style={p.note}>
		<View style={p.noteEdge({ kind: "" })} />
		<span style={p.noteLabel({ kind: "" })}>NOTE</span>
		<p style={p.noteText}>{props.children}</p>
	</View>;
}

export function Warning(props: { children: NeonNode }): NeonNode {
	return <View style={p.note}>
		<View style={p.noteEdge({ kind: "warning" })} />
		<span style={p.noteLabel({ kind: "warning" })}>WARNING</span>
		<p style={p.noteText}>{props.children}</p>
	</View>;
}

export function Table(props: { children: NeonNode }): NeonNode {
	return <View style={p.table}>{props.children}</View>;
}

export function Head(props: { a: string; b: string }): NeonNode {
	return <>
		<View style={[p.row, p.rowHead]}>
			<span style={p.cellName}>{props.a}</span>
			<span style={p.cellText}>{props.b}</span>
		</View>
		<Hairline />
	</>;
}

export function Row(props: { a: string; b: string }): NeonNode {
	return <>
		<View style={p.row}>
			<Text style={[p.cellName, p.cellMono]}>{props.a}</Text>
			<Text style={p.cellText}>{props.b}</Text>
		</View>
		<Hairline />
	</>;
}
