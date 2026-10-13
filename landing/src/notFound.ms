import { createStyles, styleOf } from "../../../neon/src/macros/ui/style";
import { View } from "../../../neon/src/components/primitives";
import { Head } from "../../../neon/src/render/head";
import { NeonNode } from "../../../neon/src/render/node";
import { theme } from "./theme";

const n = createStyles({
	page: {
		position: "absolute",
		top: 0,
		left: 0,
		right: 0,
		minHeight: "100vh",
		alignItems: "center",
		justifyContent: "center",
		paddingLeft: 24,
		paddingRight: 24,
		backgroundColor: "#0c0d0f",
		color: theme.ink,
		fontFamily: theme.sans,
	},
	brand: {
		marginBottom: 56,
		fontSize: 22,
		fontWeight: "bold",
		letterSpacing: 6,
		color: theme.white,
		textDecorationLine: "none",
	},
	code: {
		margin: 0,
		fontFamily: theme.display,
		fontSize: 128,
		lineHeight: 128,
		fontWeight: "700",
		letterSpacing: -2,
		color: "#ffa828",
	},
	line: {
		margin: 0,
		marginTop: 12,
		fontFamily: theme.display,
		fontSize: 20,
		color: theme.muted,
		textAlign: "center",
	},
	links: { flexDirection: "row", gap: 28, marginTop: 40 },
	link: {
		fontFamily: theme.mono,
		fontSize: 12,
		fontWeight: "600",
		letterSpacing: 1.2,
		color: theme.ink,
		textDecorationLine: "none",
	},
});

export function NotFound(): NeonNode {
	return <View style={n.page}>
		<Head>
			<title>Page not found · Geass</title>
			<meta name="robots" content="noindex" />
		</Head>
		<a style={n.brand} href="/">GEASS</a>
		<h1 style={n.code}>404</h1>
		<p style={n.line}>This page does not exist.</p>
		<View style={n.links}>
			<a style={n.link} href="/">HOME</a>
			<a style={n.link} href="/docs">DOCS</a>
			<a style={n.link} href="/playground">PLAYGROUND</a>
		</View>
	</View>;
}
