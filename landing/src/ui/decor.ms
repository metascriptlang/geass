import { Accessor } from "../../../../neon/src/core/signal";
import { Show } from "../../../../neon/src/macros/ui/flow";
import { createStyles, styleOf } from "../../../../neon/src/macros/ui/style";
import { View } from "../../../../neon/src/components/primitives";
import { NeonNode } from "../../../../neon/src/render/node";
import { Style } from "../../../../neon/src/render/style";
import { theme } from "../theme";

const CHAMFER = "polygon(20px 0, calc(100% - 27px) 0, 100% 27px, "
	+ "100% calc(100% - 37px), calc(100% - 37px) 100%, 0 100%, 0 20px)";

export const FOOT_SLANT_RUN = 700;
export const FOOT_SLANT_SHARE = "2.4286%";
export const FOOT_SLANT = "polygon(0 0, 100% 0, 100% calc(100% - 17px), 0 100%)";

const d = createStyles({
	hairline: { minWidth: 1, minHeight: 1, backgroundColor: theme.line },
	arrow: { fontWeight: "300" },
	accentDash: { width: 24, height: 2, backgroundColor: theme.red },
	chamferFrame: { borderWidth: 1, borderColor: theme.line, clipPath: CHAMFER },
	chamferEdge: { position: "absolute", height: 1, backgroundColor: theme.line },
	chamferEdgeLead: { top: 9, left: -4, width: 28, transform: "rotate(-45deg)" },
	chamferEdgeTop: { top: 13, right: -6, width: 38, transform: "rotate(45deg)" },
	chamferEdgeBottom: { bottom: 18, right: -8, width: 52, transform: "rotate(-45deg)" },
	scrollRing: {
		alignItems: "center",
		justifyContent: "center",
		width: 24,
		height: 24,
		borderWidth: 1,
		borderColor: "#4c4f53",
		borderRadius: 12,
	},
	scrollDot: { width: 7, height: 7, borderRadius: 4, borderWidth: 2, borderColor: "#c0c2c5" },
	scrollTick: { position: "absolute", top: -8, left: -2, width: 28, height: 1 },
	scrollTail: {
		position: "absolute",
		top: 24,
		left: 11,
		width: 1,
		height: 60,
		backgroundColor: theme.line,
	},
	scrollRuler: { height: 18 },
	scrollRulerWindow: {
		position: "absolute",
		top: 0,
		left: 0,
		right: 0,
		bottom: 0,
		overflow: "hidden",
		borderRadius: 7,
	},
	scrollRulerTicks: {
		position: "absolute",
		top: 0,
		left: 0,
		bottom: 0,
		width: FOOT_SLANT_RUN,
		backgroundImage: "repeating-linear-gradient(90deg, #5a5d62 0, #5a5d62 1px, "
			+ "transparent 1px, transparent 6px)",
		clipPath: FOOT_SLANT,
	},
	scrollRulerMark: {
		position: "absolute",
		top: 0,
		bottom: 0,
		width: 2,
		backgroundColor: theme.signal,
	},
	vignette: {
		position: "absolute",
		top: 0,
		bottom: 0,
		left: 0,
		right: 0,
		boxShadow: "inset 0 0 220px 20px rgba(0, 0, 0, 0.35)",
	},
});

export function Hairline(props: { place?: Style }): NeonNode {
	return <View style={[d.hairline, props.place ?? {}]} />;
}

export function AccentDash(props: { place?: Style }): NeonNode {
	return <View style={[d.accentDash, props.place ?? {}]} />;
}

export function ChamferFrame(props: { place: Style; children: NeonNode }): NeonNode {
	return <View style={[d.chamferFrame, props.place]}>
		{props.children}
		<View style={[d.chamferEdge, d.chamferEdgeLead]} />
		<View style={[d.chamferEdge, d.chamferEdgeTop]} />
		<View style={[d.chamferEdge, d.chamferEdgeBottom]} />
	</View>;
}

export function ScrollMarker(props: { tail: Accessor<boolean> }): NeonNode {
	return <View>
		<View style={[d.hairline, d.scrollTick]} />
		<View style={d.scrollRing}><View style={d.scrollDot} /></View>
		<Show when={props.tail}><View style={d.scrollTail} /></Show>
	</View>;
}

export function ScrollRuler(props: { place: Style; mark: Style }): NeonNode {
	return <View style={[d.scrollRuler, props.place]}>
		<View style={d.scrollRulerWindow}><View style={d.scrollRulerTicks} /></View>
		<View style={[d.scrollRulerMark, props.mark]} />
	</View>;
}

export function Vignette(): NeonNode {
	return <View style={d.vignette} />;
}

const GITHUB_MARK = "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='20' height='20' viewBox='0 0 16 16'%3E%3Cpath fill='%23f1f1ef' d='"
	+ "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27s1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8Z"
	+ "'/%3E%3C/svg%3E\")";

const g = createStyles({
	github: { width: 20, height: 20, backgroundImage: GITHUB_MARK },
});

export function GitHubLink(): NeonNode {
	return <a href="https://github.com/metascriptlang/compiler" aria-label="GitHub">
		<View style={g.github} />
	</a>;
}

export function Arrow(): NeonNode {
	return <span style={d.arrow} aria-hidden="true">↗</span>;
}
