import { onCleanup } from "../../../neon/src/core/cleanup";
import { createMemo } from "../../../neon/src/core/memo";
import { createSignal } from "../../../neon/src/core/signal";
import { Show } from "../../../neon/src/macros/ui/flow";
import { createStyles, styleOf } from "../../../neon/src/macros/ui/style";
import { View } from "../../../neon/src/components/primitives";
import { useWindowDimensions } from "../../../neon/src/render/environment";
import { NeonNode } from "../../../neon/src/render/node";
import { HostNode } from "../../../neon/src/render/hostTypes";
import { Style } from "../../../neon/src/render/style";
import { theme } from "./theme";
import { Features } from "./features";
import {
	Hairline,
	AccentDash,
	ChamferFrame,
	FOOT_SLANT,
	FOOT_SLANT_RUN,
	FOOT_SLANT_SHARE,
	ScrollMarker,
	ScrollRuler,
	Vignette,
	Arrow,
	GitHubLink,
} from "./ui/decor";
import { PageHead, PageTitle } from "./ui/pageHead";
import { pageShare, shareFrom } from "./pageScroll";

const BACKDROP_LAYERS = [
	"url(/grain.png)",
	"conic-gradient(from 18deg at 58% 118%, transparent 0deg, #ffffff10 0deg, "
		+ "transparent 11deg, transparent 360deg)",
	"conic-gradient(from 196deg at 34% -22%, transparent 0deg, #ffffff0c 0deg, "
		+ "transparent 16deg, transparent 360deg)",
	"conic-gradient(from 118deg at -6% 30%, transparent 0deg, #00000038 0deg, "
		+ "transparent 9deg, transparent 360deg)",
	"linear-gradient(133deg, transparent 47%, #ffffff0d 47%, transparent 71%)",
	"linear-gradient(151deg, transparent 63%, #00000030 63%, transparent 69%)",
	"linear-gradient(133deg, transparent calc(44% - 1px), #ffffff1c 44%, "
		+ "transparent calc(44% + 1px))",
	"linear-gradient(112deg, transparent calc(86% - 1px), rgba(226, 48, 40, 0.3) 86%, "
		+ "transparent calc(86% + 1px))",
	"linear-gradient(90deg, #00000052, transparent 16%, transparent 84%, #00000052)",
	"radial-gradient(ellipse 36% 110% at 47% 34%, rgba(150, 160, 180, 0.12), transparent 80%)",
	"linear-gradient(180deg, #0c0d0f 0%, #0e0f12 60%, #0c0c0f 100%)",
].join(", ");

const DRAWN = "clip-path 0.25s ease-out";
const TEXT_EDGE = "calc(17% - 80px)";
const TEXT_EDGE_BACK = "calc(27% - 110px)";

const WIDEST = "1500px";
const EDGE_LEFT = "max(68px, calc((100vw - " + WIDEST + ") / 2 + 68px))";
const EDGE_RIGHT = "max(49px, calc((100vw - " + WIDEST + ") / 2 + 49px))";

const s = createStyles({
	scrollTrack: { height: "1250vh" },
	scrollRuler: { width: 200, variants: { layout: { narrow: { flex: 1, width: "auto" } } } },
	scrollCount: {
		opacity: 0,
		transition: "opacity 0.5s ease",
		variants: { state: { shown: { opacity: 1 } } },
	},
	daylight: {
		position: "absolute",
		top: 0,
		bottom: 0,
		left: 0,
		right: 0,
		backgroundColor: "rgba(218, 213, 208, 0)",
		transition: "background-color 0.9s ease",
		variants: { state: { lit: { backgroundColor: "rgba(218, 213, 208, 1)" } } },
	},
	site: {
		position: "fixed",
		top: 0,
		left: 0,
		right: 0,
		height: "100vh",
		paddingLeft: EDGE_LEFT,
		paddingRight: EDGE_RIGHT,
		backgroundColor: theme.mechBackdrop,
		backgroundImage: BACKDROP_LAYERS,
		color: theme.ink,
		fontFamily: theme.sans,
		overflow: "hidden",
		variants: { layout: { narrow: { paddingLeft: 24, paddingRight: 24 } } },
	},
	header: { flexDirection: "row", alignItems: "center", gap: 20, height: 92, zIndex: 1 },
	brand: {
		fontSize: 22,
		fontWeight: "bold",
		letterSpacing: 6,
		color: theme.white,
		textDecorationLine: "none",
	},
	divider: { height: 20 },
	tagline: {
		fontFamily: theme.mono,
		fontSize: 13,
		fontWeight: "300",
		letterSpacing: 1.1,
		color: "#a9abaf",
	},
	siteNav: { flexDirection: "row", gap: 36, marginLeft: "auto" },
	navLink: { fontSize: 14, color: theme.white, textDecorationLine: "none" },
	navMark: { color: theme.line },
	buttonLink: { color: theme.ink, textDecorationLine: "none" },
	headerAction: {
		marginLeft: 12,
		color: theme.white,
		textDecorationLine: "none",
		variants: { layout: { narrow: { marginLeft: "auto" } } },
	},
	outline: {
		flexDirection: "row",
		alignItems: "center",
		gap: 14,
		paddingTop: 13,
		paddingBottom: 13,
		paddingLeft: 28,
		paddingRight: 28,
		borderWidth: 1,
		borderColor: "rgba(255, 255, 255, 0.55)",
		borderRadius: 2,
		fontSize: 15,
	},
	solid: {
		flexDirection: "row",
		alignItems: "center",
		gap: 16,
		paddingTop: 16,
		paddingBottom: 16,
		paddingLeft: 40,
		paddingRight: 40,
		backgroundColor: theme.red,
		borderRadius: 2,
		boxShadow: "inset 0 0 0 1px #e63036",
		fontSize: 18,
		fontWeight: "500",
		color: theme.white,
	},
	main: {
		flex: 1,
		flexDirection: "row",
		alignItems: "center",
		gap: 32,
		variants: {
			layout: { narrow: { flexDirection: "column", alignItems: "stretch", gap: 0 } },
		},
	},
	stage: {
		flex: 1,
		alignSelf: "stretch",
	},
	backdrop: {
		position: "absolute",
		top: -92,
		bottom: -120,
		left: "calc(-1 * " + EDGE_LEFT + ")",
		right: "calc(-1 * " + EDGE_RIGHT + ")",
		transition: "opacity 0.9s ease",
		variants: { state: { lit: { opacity: 0 } } },
	},
	inked: {
		filter: "none",
		transition: "filter 0.9s ease",
		variants: { state: { lit: { filter: "invert(1) hue-rotate(180deg) brightness(0.5)" } } },
	},
	frameTick: {
		position: "absolute",
		top: 0,
		left: "calc(" + EDGE_LEFT + " - 27px)",
		height: 62,
		opacity: 0.6,
	},
	hero: {
		width: 480,
		paddingTop: 61,
		paddingBottom: 24,
		zIndex: 1,
		transition: "opacity 0.5s ease, transform 0.5s ease",
		variants: {
			layout: { narrow: { width: "100%", paddingTop: 32 } },
			state: { away: { opacity: 0, transform: "translateX(-48px)" } },
		},
	},
	eyebrow: {
		margin: 0,
		fontFamily: theme.mono,
		fontSize: 14,
		fontWeight: "500",
		letterSpacing: 1,
		color: theme.signal,
	},
	title: {
		margin: 0,
		marginTop: 16,
		marginBottom: 24,
		marginRight: -60,
		fontSize: 58,
		lineHeight: 58,
		letterSpacing: -0.5,
		fontWeight: "500",
		color: "#f6f6f5",
		variants: { layout: { narrow: { marginRight: 0, fontSize: 28, lineHeight: 32 } } },
	},
	titleLast: { color: "#dadad9" },
	intro: { margin: 0, maxWidth: 412, fontSize: 18, lineHeight: 28, color: "#b9bcc1" },
	actions: {
		flexDirection: "row",
		alignItems: "center",
		gap: 38,
		marginTop: 28,
		marginBottom: 40,
	},
	textLink: {
		display: "flex",
		flexDirection: "column",
		gap: 6,
		marginTop: 6,
		fontSize: 15,
		color: theme.white,
		textDecorationLine: "none",
	},
	card: {
		flexDirection: "row",
		width: 460,
		backgroundColor: "rgba(7, 8, 10, 0.6)",
		variants: { layout: { narrow: { width: "100%" } } },
	},
	cardLineTop: { position: "absolute", top: 41, left: "52%", right: 0 },
	cardLineBottom: { position: "absolute", bottom: 25, left: "52%", right: 0 },
	cardArt: {
		flexBasis: "52%",
		aspectRatio: 1.2,
		overflow: "hidden",
		clipPath: "polygon(0 0, 100% 0, 100% calc(100% - 18px), calc(100% - 18px) 100%, 0 100%)",
		variants: { layout: { narrow: { flexBasis: "44%" } } },
	},
	cardArtSide: { position: "absolute", top: 0, bottom: 18, right: 0 },
	cardArtCut: {
		position: "absolute",
		right: -4,
		bottom: 8,
		width: 26,
		transform: "rotate(-45deg)",
	},
	cardHead: { position: "absolute", top: "-10%", left: 0, width: "100%" },
	cardText: {
		flex: 1,
		justifyContent: "center",
		gap: 6,
		paddingTop: 14,
		paddingLeft: 20,
		paddingRight: 20,
	},
	cardTitle: {
		margin: 0,
		fontFamily: theme.mono,
		fontSize: 15,
		fontWeight: "300",
		lineHeight: 19,
		letterSpacing: 2,
		color: "#d0d2d6",
	},
	cardBody: { margin: 0, fontSize: 13, lineHeight: 18, color: "#b6b9bc" },
	accent: { marginTop: 12, backgroundColor: theme.signal },
	mech: {
		position: "absolute",
		top: "50%",
		left: "min(55%, calc(100% - 6.13vw - 155px))",
		width: "clamp(520px, min(max(calc(min(100vw, " + WIDEST + ") - 620px), calc(26.67vw + 333px)), 94vh), 1280px)",
		aspectRatio: 1,
		transform: "translate(-50%, -50%)",
		transition: "transform 0.7s ease",
		variants: {
			layout: {
				narrow: { position: "fixed", left: "51%", width: "clamp(280px, min(90vw, calc(26.67vw + 333px)), 600px)" },
			},
		},
	},
	mechImage: {
		position: "absolute",
		top: 0,
		left: "-15%",
		width: "130%",
		height: "100%",
		pointerEvents: "none",
		opacity: 0,
		transition: "opacity 1s ease",
		variants: { state: { ready: { opacity: 1 } } },
	},
	labels: {
		position: "absolute",
		top: 0,
		left: 0,
		width: "100%",
		aspectRatio: 1,
		fontFamily: theme.mono,
		fontSize: 13,
		variants: {
			layout: { narrow: { fontSize: 10 } },
		},
	},
	leadRow: {
		position: "absolute",
		gap: 7,
		transform: "translateY(calc(-100% + 1.5px))",
	},
	leadGroup: { position: "absolute", top: 0, left: 0, width: "100%", height: "100%", transition: DRAWN },
	leadText: {
		gap: 2,
		width: "max-content",
		variants: { side: { back: { alignItems: "flex-end", alignSelf: "flex-end" } } },
	},
	leadRun: {
		flexDirection: "row",
		alignItems: "center",
		variants: { side: { back: { flexDirection: "row-reverse" } } },
	},
	leadHead: {
		width: 20,
		height: 3,
		backgroundColor: "#ff4b45",
		boxShadow: "0 0 10px 1px rgba(255, 60, 56, 0.85)",
	},
	leadRule: { flex: 1, height: 1, backgroundColor: "#f0363a" },
	leadSlope: { position: "absolute", aspectRatio: 1 },
	slopeDown: { backgroundImage: "linear-gradient(to top right, transparent calc(50% - 0.6px), #f0363a calc(50% - 0.6px), "
			+ "#f0363a calc(50% + 0.6px), transparent calc(50% + 0.6px))" },
	slopeUp: { backgroundImage: "linear-gradient(to bottom right, transparent calc(50% - 0.6px), #f0363a calc(50% - 0.6px), "
			+ "#f0363a calc(50% + 0.6px), transparent calc(50% + 0.6px))" },
	labelTitle: { fontWeight: "bold", letterSpacing: 1 },
	labelPart: { fontFamily: theme.sans, color: "#b4b5b8" },
	rowInterface: { top: "41%", left: TEXT_EDGE, right: "83%", variants: { layout: { narrow: { left: "6%" } } } },
	slopeInterface: { top: "41%", left: "17%", width: "5%" },
	rowGuard: { top: "88.8%", left: "64.8%", right: TEXT_EDGE_BACK, variants: { layout: { narrow: { right: "6%" } } } },
	slopeGuard: { top: "54%", left: "30%", width: "34.8%" },
	rowCompiler: { top: "31.1%", left: TEXT_EDGE, right: "78.9%", variants: { layout: { narrow: { left: "6%" } } } },
	slopeCompiler: { top: "31.1%", left: "21.1%", width: "14.9%" },
	rowMemory: { top: "78.9%", left: "68.9%", right: TEXT_EDGE_BACK, variants: { layout: { narrow: { right: "6%" } } } },
	slopeMemory: { top: "54%", left: "44%", width: "24.9%" },
	rowRuntime: { top: "21.2%", left: TEXT_EDGE, right: "74.8%", variants: { layout: { narrow: { left: "6%" } } } },
	slopeRuntime: { top: "21.2%", left: "25.2%", width: "24.8%" },
	rowTarget: { top: "69%", left: "73%", right: TEXT_EDGE_BACK, variants: { layout: { narrow: { right: "6%" } } } },
	slopeTarget: { top: "54%", left: "58%", width: "15%" },
	footer: {
		flexDirection: "row",
		alignItems: "flex-end",
		justifyContent: "space-between",
		paddingTop: 24,
		paddingBottom: 42,
		zIndex: 1,
		fontFamily: theme.mono,
		fontSize: 13,
		letterSpacing: 1.7,
		color: "#878b8e",
		variants: {
			layout: { narrow: { flexDirection: "column", alignItems: "flex-start", gap: 20 } },
		},
	},
	footBand: {
		position: "absolute",
		top: -8,
		left: -63,
		width: FOOT_SLANT_RUN,
		height: 45,
		backgroundColor: "rgba(0, 0, 0, 0.35)",
		clipPath: FOOT_SLANT,
	},
	scrollHint: {
		flexDirection: "row",
		alignItems: "center",
		gap: 24,
		marginLeft: -5,
		variants: { layout: { narrow: { alignSelf: "stretch" } } },
	},
	mottoDash: { width: 22, marginTop: 13, backgroundColor: theme.signal },
	motto: {
		alignItems: "flex-end",
		gap: 3,
		fontSize: 11,
		letterSpacing: 1.5,
		transform: "translateY(-13px)",
		transition: "opacity 0.4s ease",
		variants: { state: { between: { opacity: 0 } } },
	},
	mottoLead: {
		fontFamily: theme.sans,
		fontSize: 14,
		letterSpacing: 3.2,
		color: "#7c8086",
	},
});

extern class HTMLCanvasElement {
	width: number;
}

extern function startVoidCanvas(canvas: HTMLCanvasElement, base: cstring, script: cstring): void
	from "((canvas, base, script) => { const forced = new URLSearchParams(location.search); const load = ([dir, device]) => new Promise((ready) => { window.Module = { voidBackend: dir, preinitializedWebGPUDevice: device, onVoidReady: ready, locateFile: (file) => base + dir + '/' + file }; const tag = document.createElement('script'); tag.src = base + dir + '/' + script; document.body.appendChild(tag); }); window.voidLoaded ??= (forced.has('gl') || !navigator.gpu ? Promise.resolve(['gl']) : navigator.gpu.requestAdapter().then((adapter) => adapter.requestDevice()).then((device) => ['wgpu', device], (error) => forced.has('wgpu') ? Promise.reject(error) : ['gl'])).then(load); window.voidLoaded.then(() => { canvas.dataset.voidBackend = Module.voidBackend; if (!canvas.voidLeft) { canvas.voidStop = Module.voidStart(canvas); } }); })(#, #, #)";

extern function stopVoidCanvas(canvas: HTMLCanvasElement): void
	from "((canvas) => { canvas.voidLeft = true; canvas.voidStop?.(); })(#)";

extern function whenMechReady(done: () => void): void
	from "((done) => addEventListener('mechready', done, { once: true }))(#)";

const [mechLoading, setMechLoading] = createSignal(true);

function startMech(node: HostNode): void {
	const canvas = node as unknown as HTMLCanvasElement;
	whenMechReady(() => { setMechLoading(false); });
	startVoidCanvas(canvas, "/void/", "mechView.js");
	onCleanup(() => { stopVoidCanvas(canvas); });
}

const viewport = useWindowDimensions();
const wide = createMemo(() => viewport().width >= 900);

const UNFOLDED_BY = 0.2;
const CLOSING_FROM = 0.8;
const UNFOLDING_FROM = 0.42;
const CHAPTERS = 6;
const FEATURE_FROM = 0.05;
const FEATURE_UNTIL = 0.92;
const DAYLIGHT_FROM = 0.84;
const QUOTES = [
	"DATA DOMINATES.",
	"READABILITY COUNTS.",
	"PARSE, DON'T VALIDATE.",
	"WRITE CODE THAT WRITES CODE.",
	"YOU AREN'T GONNA NEED IT.",
	"LESS IS EXPONENTIALLY MORE.",
	"RELEASE EARLY. RELEASE OFTEN.",
];
const QUOTED = [
	"ROB PIKE, RULE 5",
	"TIM PETERS",
	"ALEXIS KING",
	"HUNT & THOMAS",
	"RON JEFFRIES",
	"ROB PIKE",
	"ERIC S. RAYMOND",
];
const unfolding = createMemo((): boolean => pageShare() > UNFOLDING_FROM * UNFOLDED_BY);
const daylit = createMemo((): boolean => pageShare() > DAYLIGHT_FROM);
const along = createMemo((): number => (pageShare() - UNFOLDED_BY) / (CLOSING_FROM - UNFOLDED_BY) * (CHAPTERS as number));
const chapter = createMemo((): int32 => {
	const reached = Math.floor(along()) as int32;
	return pageShare() <= UNFOLDED_BY ? -1 : reached < CHAPTERS ? reached : CHAPTERS - 1;
});
const into = createMemo((): number => along() - (chapter() as number));
const featured = createMemo((): int32 => into() >= FEATURE_FROM && into() <= FEATURE_UNTIL ? chapter() : -1);
const coded = createMemo((): int32 => into() < FEATURE_FROM ? chapter() - 1
	: chapter() === CHAPTERS - 1 && into() > FEATURE_UNTIL ? CHAPTERS : chapter());
const LEAD_DRAWS_OVER = 0.04;
const LABELS_CLOSE_FROM = 0.8;
const LABELS_CLOSE_OVER = 0.03;
const labelsClip = (): string => `inset(calc(-100% + ${150 * shareFrom(LABELS_CLOSE_FROM, LABELS_CLOSE_OVER)}%))`;

function Lead(
	props: { title: string; name: string; drawsAt: number; reach: string; row: Style; slope: Style; back?: boolean },
): NeonNode {
	const drawn = (): number => shareFrom(props.drawsAt, LEAD_DRAWS_OVER);
	const wipe = (): string => props.back
		? `inset(-60px -400px -20px calc(73% + 130px - ${drawn()} * (${props.reach} + 130px)))`
		: `inset(-60px calc(83% + 100px - ${drawn()} * (${props.reach} + 100px)) -20px -400px)`;
	return <View style={[s.leadGroup, { clipPath: wipe() }]}>
		<View style={[s.leadRow, props.row]}>
			<View style={s.leadText({ side: props.back ? "back" : "" })}>
				<span style={s.labelTitle}>{props.title}</span>
				<Show when={wide}><span style={s.labelPart}>{props.name}</span></Show>
			</View>
			<View style={s.leadRun({ side: props.back ? "back" : "" })}>
				<View style={s.leadHead} />
				<View style={s.leadRule} />
			</View>
		</View>
		<View style={[s.leadSlope, s.slopeDown, props.slope]} />
	</View>;
}

export function Home(): NeonNode {
	return <View style={s.scrollTrack}>
	<PageTitle title="Geass — MetaScript for Solana" />
	<PageHead
		about="Geass: write Solana on-chain programs in TypeScript syntax, powered by MetaScript."
		path="/"
	/>
	<View style={s.site({ layout: wide() ? "" : "narrow" })}>
		<View style={s.daylight({ state: daylit() ? "lit" : "" })} />
		<View style={[s.header, s.inked({ state: daylit() ? "lit" : "" })]}>
			<a style={s.brand} href="#overview">GEASS</a>
			<Show when={wide}>
				<Hairline place={s.divider} />
				<span style={s.tagline}>METASCRIPT FOR SOLANA</span>
				<View style={s.siteNav}>
					<a style={s.navLink} href="/docs">Docs</a>
					<a style={s.navLink} href="/playground">Playground</a>
					<GitHubLink />
					<span style={s.navMark} aria-hidden="true">›</span>
				</View>
			</Show>
			<a style={s.headerAction({ layout: wide() ? "" : "narrow" })} href="/docs">
				<View style={s.outline}>Get Started <Arrow /></View>
			</a>
		</View>
		<View style={s.main({ layout: wide() ? "" : "narrow" })}>
			<View style={s.hero({ layout: wide() ? "" : "narrow", state: unfolding() ? "away" : "" })}>
				<p style={s.eyebrow}>{"// TYPESCRIPT. ON-CHAIN."}</p>
				<h1 id="overview" style={s.title({ layout: wide() ? "" : "narrow" })}>
					Write TypeScript.<br /><span style={s.titleLast}>Build on Solana.</span>
				</h1>
				<Show when={wide}>
				<p style={s.intro}>
					Geass lets you write Solana on-chain programs using TypeScript syntax,
					powered by MetaScript. Familiar language. New battlefield.
				</p>
				<View style={s.actions}>
					<a style={s.buttonLink} href="/docs">
						<View style={s.solid}>Get Started <Arrow /></View>
					</a>
					<a style={s.textLink} href="/docs">
						Read the Docs
						<Hairline />
					</a>
				</View>
				<ChamferFrame place={s.card({ layout: wide() ? "" : "narrow" })}>
					<View style={s.cardArt({ layout: wide() ? "" : "narrow" })}>
						<img style={s.cardHead} src="/cardHead.webp" alt="" />
						<Hairline place={s.cardArtSide} />
						<Hairline place={s.cardArtCut} />
					</View>
					<View style={s.cardText}>
						<p style={s.cardTitle}>SAME MIND.<br />A WIDER WORLD.</p>
						<p style={s.cardBody}>From familiar syntax<br />to on-chain reality.</p>
						<AccentDash place={s.accent} />
					</View>
					<Hairline place={s.cardLineTop} />
					<Hairline place={s.cardLineBottom} />
				</ChamferFrame>
				</Show>
			</View>
			<Features chapter={featured()} coded={coded()} compact={!wide()} />
			<View style={s.stage}>
			<View style={s.mech({ layout: wide() ? "" : "narrow" })}>
				<canvas
					id="canvas"
					style={s.mechImage({ state: mechLoading() ? "" : "ready" })}
					role="img"
					aria-label="Geass mech, rendered live"
					ref={startMech}
				/>
				<View style={[s.labels({ layout: wide() ? "" : "narrow" }), { clipPath: labelsClip() }]}>
					<Lead title="INTERFACE" name="TypeScript" drawsAt={0.22} reach="17%" row={s.rowInterface({ layout: wide() ? "" : "narrow" })}
						slope={s.slopeInterface} />
					<Lead title="GUARD" name="Compile-time" drawsAt={0.32} reach="43%" row={s.rowGuard({ layout: wide() ? "" : "narrow" })}
						back slope={s.slopeGuard} />
					<Lead title="COMPILER" name="MetaScript" drawsAt={0.42} reach="31%" row={s.rowCompiler({ layout: wide() ? "" : "narrow" })}
						slope={s.slopeCompiler} />
					<Lead title="MEMORY" name="No GC" drawsAt={0.52} reach="29%" row={s.rowMemory({ layout: wide() ? "" : "narrow" })}
						back slope={s.slopeMemory} />
					<Lead title="RUNTIME" name="Zero overhead" drawsAt={0.62} reach="45%" row={s.rowRuntime({ layout: wide() ? "" : "narrow" })}
						slope={s.slopeRuntime} />
					<Lead title="TARGET" name="Solana SBF" drawsAt={0.72} reach="15%" row={s.rowTarget({ layout: wide() ? "" : "narrow" })}
						back slope={s.slopeTarget} />
				</View>
			</View>
			</View>
			<Show when={wide}>
				<View style={s.backdrop({ state: daylit() ? "lit" : "" })}>
					<Hairline place={s.frameTick} />
					<Vignette />
				</View>
			</Show>
		</View>
		<View style={[s.footer({ layout: wide() ? "" : "narrow" }), s.inked({ state: daylit() ? "lit" : "" })]}>
			<View style={s.scrollHint({ layout: wide() ? "" : "narrow" })}>
				<View style={s.footBand} />
				<ScrollMarker tail={wide()} />
				<span>SCROLL TO UNFOLD</span>
				<ScrollRuler
					place={s.scrollRuler({ layout: wide() ? "" : "narrow" })}
					along={`${100 * pageShare()}%`}
					drop={`calc(${pageShare()} * ${FOOT_SLANT_SHARE})`}
				/>
				<Show when={wide}>
					<span style={s.scrollCount({ state: chapter() >= 0 ? "shown" : "" })}>
						{`0${chapter() + 1} / 0${CHAPTERS}`}
					</span>
				</Show>
			</View>
			<Show when={wide}>
				<View
					style={s.motto({
						state: chapter() < 0 || featured() >= 0 || daylit() ? "" : "between",
					})}
				>
					<span style={s.mottoLead}>{QUOTES[chapter() + 1]}</span>
					<span>{QUOTED[chapter() + 1]}</span>
					<AccentDash place={s.mottoDash} />
				</View>
			</Show>
		</View>
	</View>
	</View>;
}
