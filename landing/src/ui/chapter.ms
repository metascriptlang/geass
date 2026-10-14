import { Accessor } from "../../../../neon/src/core/signal";
import { createStyles, styleOf } from "../../../../neon/src/macros/ui/style";
import { View } from "../../../../neon/src/components/primitives";
import { NeonNode } from "../../../../neon/src/render/node";
import { Style, layerStyles } from "../../../../neon/src/render/style";
import { theme } from "../theme";
import { CodeBlock } from "./codeBlock";

const SPRING = "cubic-bezier(0.2, 0.8, 0.2, 1)";
const MOVE_RULE = "clip-path 0.7s " + SPRING + " 0.1s";
const MOVE_CODE = "opacity 0.55s ease 0.1s, transform 0.7s " + SPRING + " 0.1s";

const h = createStyles({
	textBody: {
		flexDirection: "column-reverse",
		variants: { size: { compact: { transform: "translate(-15%, 15%) scale(0.7)" } } },
	},
	codeBody: {
		variants: { size: { compact: { transform: "translate(10%, -10%) scale(0.8)" } } },
	},
	title: {
		margin: 0,
		fontFamily: theme.display,
		fontSize: 52,
		lineHeight: 45,
		fontWeight: "700",
		opacity: 0,
		transition: "opacity 0.4s ease",
		variants: { state: { shown: { opacity: 1 }, passed: {} } },
	},
	titleCompact: { fontSize: 34, lineHeight: 30 },
	body: {
		margin: 0,
		marginBottom: 19,
		maxWidth: 320,
		fontFamily: theme.display,
		fontSize: 20,
		lineHeight: 25,
		fontWeight: "600",
		color: "#d5d3d1",
		opacity: 0,
		transition: "opacity 0.4s ease",
		variants: { state: { shown: { opacity: 1 }, passed: {} } },
	},
	rule: {
		width: 256,
		height: 1,
		marginTop: 16,
		marginBottom: 25,
		backgroundColor: "#b4b1af",
		clipPath: "inset(0 100% 0 0)",
		transition: MOVE_RULE,
		variants: { state: { shown: { clipPath: "inset(0 0 0 0)" }, passed: {} } },
	},
	point: {
		flexDirection: "row",
		alignItems: "center",
		gap: 12,
		fontFamily: theme.mono,
		fontSize: 12,
		lineHeight: 24,
		fontWeight: "600",
		letterSpacing: 0.12,
		color: "#b4b1af",
		opacity: 0,
	},
	pointFirst: {
		transition: "opacity 0.35s ease 0.2s",
		variants: { state: { shown: { opacity: 1 }, passed: {} } },
	},
	arrow: { fontFamily: theme.sans, fontSize: 16 },
	code: {
		position: "absolute",
		right: 0,
		top: 24,
		zIndex: 1,
		opacity: 0,
		transform: "translateY(-180px)",
		transition: MOVE_CODE,
		variants: {
			state: {
				shown: { opacity: 1, transform: "none" },
				passed: { transform: "translateY(180px)" },
			},
		},
	},
});

function phase(at: int32, current: int32): "" | "shown" | "passed" {
	return current === at ? "shown" : current > at ? "passed" : "";
}

export function Chapter(
	props: {
		at: int32;
		current: Accessor<int32>;
		coded: Accessor<int32>;
		compact: Accessor<boolean>;
		title: string;
		body: string;
		point: string;
		code: string;
		tone: Style;
		rise: Accessor<string>;
		fade: Accessor<string>;
	},
): NeonNode {
	return <>
		<View style={{
			position: "absolute",
			bottom: 24,
			left: 0,
			width: "min(400px, 100%)",
			zIndex: 1,
			transform: props.rise(),
			filter: props.fade(),
		}}>
			<View style={h.textBody({ size: props.compact() ? "compact" : "" })}>
				<h2
					style={layerStyles([
						h.title({ state: phase(props.at, props.current()) }),
						props.compact() ? h.titleCompact : {},
						props.tone,
					])}
				>
					{props.title}
				</h2>
				<p style={h.body({ state: phase(props.at, props.current()) })}>{props.body}</p>
				<View style={h.rule({ state: phase(props.at, props.current()) })} />
				<View style={[h.point, h.pointFirst({ state: phase(props.at, props.current()) })]}>
					<span style={h.arrow} aria-hidden="true">→</span>{props.point}
				</View>
			</View>
		</View>
		<View style={h.code({ state: phase(props.at, props.coded()) })}>
			<View style={h.codeBody({ size: props.compact() ? "compact" : "" })}>
				<CodeBlock code={props.code} />
			</View>
		</View>
	</>;
}
