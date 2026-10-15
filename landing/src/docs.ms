import { createMemo } from "../../../neon/src/core/memo";
import { Accessor, Signal, accessor, createSignal } from "../../../neon/src/core/signal";
import { Dispose } from "../../../neon/src/core/types";
import { For, Show } from "../../../neon/src/macros/ui/flow";
import { createStyles, styleOf } from "../../../neon/src/macros/ui/style";
import { View } from "../../../neon/src/components/primitives";
import {
	RouteCodec,
	RoutePlan,
	RoutingError,
	RoutingRegistry,
	bindRoute,
	createRouteParticipant,
} from "../../../neon/src/navigation/routing";
import { RoutingHistory, createRoutingSession } from "../../../neon/src/navigation/routingHistory";
import { createContext, useContext } from "../../../neon/src/render/context";
import { useWindowDimensions } from "../../../neon/src/render/environment";
import { NeonNode } from "../../../neon/src/render/node";
import { Style } from "../../../neon/src/render/style";
import { theme } from "./theme";
import { Hairline } from "./ui/decor";
import { PagePlace } from "./ui/pageHead";
import { Accounts, Cpi, Pdas, ProgramStructure, Validation } from "./docs/core";
import { AccountData, ErrorsEvents } from "./docs/data";
import { Performance, Security } from "./docs/production";
import { Cranks, Randomness, Rollups } from "./docs/rollups";
import { Clients, Deploying, Testing } from "./docs/ship";
import { FirstProgram } from "./docs/first";
import { ErrorCodes, Troubleshooting } from "./docs/reference";
import { FromAnchor, GettingStarted, SolanaBasics } from "./docs/start";
import { Tokens } from "./docs/tokens";

struct DocsPage {
	path: string;
	title: string;
	tone: string;
}

const PAGES: DocsPage[] = [
	{ path: "/docs", title: "Getting started", tone: "start" },
	{ path: "/docs/first-program", title: "Your first program", tone: "start" },
	{ path: "/docs/solana-basics", title: "Solana in five minutes", tone: "start" },
	{ path: "/docs/from-anchor", title: "Coming from Anchor", tone: "start" },
	{ path: "/docs/program", title: "Program structure", tone: "core" },
	{ path: "/docs/accounts", title: "Accounts", tone: "core" },
	{ path: "/docs/validation", title: "Account validation", tone: "core" },
	{ path: "/docs/data", title: "Account data", tone: "core" },
	{ path: "/docs/errors-events", title: "Errors and events", tone: "core" },
	{ path: "/docs/pdas", title: "PDAs", tone: "core" },
	{ path: "/docs/cpi", title: "Cross-program calls", tone: "core" },
	{ path: "/docs/tokens", title: "Tokens", tone: "core" },
	{ path: "/docs/testing", title: "Testing", tone: "build" },
	{ path: "/docs/clients", title: "Clients and IDL", tone: "build" },
	{ path: "/docs/deploying", title: "Deploying", tone: "build" },
	{ path: "/docs/security", title: "Security", tone: "build" },
	{ path: "/docs/performance", title: "Performance", tone: "build" },
	{ path: "/docs/rollups", title: "MagicBlock rollups", tone: "chain" },
	{ path: "/docs/randomness", title: "MagicBlock VRF", tone: "chain" },
	{ path: "/docs/cranks", title: "MagicBlock cranks", tone: "chain" },
	{ path: "/docs/error-codes", title: "Error codes", tone: "reference" },
	{ path: "/docs/troubleshooting", title: "When you are stuck", tone: "reference" },
];

struct Place {
	path: string;
	tone: string;
}

function indexOfPage(path: string): int32 {
	for (let at = 0; at < PAGES.length; at++) {
		if (PAGES[at].path === path) { return at; }
	}
	return -1;
}

function placeOf(path: string): Place {
	const at = indexOfPage(path);
	return { path, tone: at >= 0 ? PAGES[at].tone : "start" };
}

const Here = createContext<() => Place>((): Place => placeOf("/docs"));
const NESTED = [
	"#the-account", "#the-instructions", "#the-entry", "#syntax",
	"#explicit-lifecycle", "#proofs", "#types-first", "#no-lifetimes",
	"#signers", "#program-accounts", "#external-accounts",
];
const FORKED = ["#reading", "#what-differs", "#proof-types"];
const [picked, setPicked] = createSignal("");

function shade(tone: string, to: string): string {
	if (picked() === to) { return tone; }
	const opened = NESTED.includes(picked()) || FORKED.includes(picked());
	return opened && !NESTED.includes(to) ? "dim" : "";
}

function isDocsPage(path: string): boolean {
	return indexOfPage(path) >= 0;
}

function pathOf(address: string): string {
	const queryAt = address.indexOf("?");
	const hashAt = address.indexOf("#");
	let end = queryAt >= 0 ? queryAt : hashAt >= 0 ? hashAt : address.length;
	while (end > 0 && address.charAt(end - 1) === "/") { end -= 1; }
	return address.substring(0, end);
}

function anchorOf(address: string): string {
	const hashAt = address.indexOf("#");
	return hashAt < 0 ? "" : address.substring(hashAt, address.length);
}

export interface DocsSite {
	path: Accessor<string>;
	open: (url: string) => boolean;
	dispose: Dispose;
}

export function createDocsSite(history: RoutingHistory): Result<DocsSite, RoutingError> {
	const address = new Signal<string>("/docs");
	const land = (to: string): void => { address.set(to); setPicked(anchorOf(to)); };
	const codec: RouteCodec<string> = {
		id: "docs",
		decode: (to: string): Result<string, RoutingError> =>
			isDocsPage(pathOf(to)) ? Result.ok(to) : Result.err(RoutingError.NoMatch),
		encode: (to: string): Result<string, RoutingError> => Result.ok(to),
	};
	const registry = new RoutingRegistry("main");
	registry.register(createRouteParticipant(
		"main",
		[bindRoute<string>(codec, (): string | null => address.get(), land)],
		(): void => land("/docs"),
		(): string => address.get(),
		(state: string): Result<RoutePlan, RoutingError> => {
			if (!isDocsPage(pathOf(state))) { return Result.err(RoutingError.IncompleteSnapshot); }
			return Result.ok({ commit: (): void => land(state) });
		},
	));
	const session = try createRoutingSession(registry, history, (failure: RoutingError): void => {});
	return Result.ok({
		path: accessor((): string => pathOf(address.get())),
		open: (url: string): boolean => session.navigate(url, false).ok,
		dispose: (): void => session.dispose(),
	});
}

const viewport = useWindowDimensions();
const wide = createMemo(() => viewport().width >= 900);

const CORE_TONE = "#ffa828";
const BUILD_TONE = "#6cb6ff";
const CHAIN_TONE = "#b78cff";
const REFERENCE_TONE = "#5fd4a0";
const SIDE = "max(0px, calc((100vw - 1500px) / 2))";
const EDGE = "calc(" + SIDE + " + 24px)";

const d = createStyles({
	page: {
		position: "absolute",
		top: 0,
		left: 0,
		right: 0,
		minHeight: "100vh",
		backgroundColor: "#0c0d0f",
		color: theme.ink,
		fontFamily: theme.sans,
	},
	header: {
		position: "fixed",
		top: 0,
		left: 0,
		right: 0,
		flexDirection: "row",
		alignItems: "center",
		gap: "clamp(10px, calc((100vw - 310px) / 2), 20px)",
		height: 72,
		paddingLeft: EDGE,
		paddingRight: EDGE,
		backgroundColor: "#0c0d0f",
		zIndex: 2,
	},
	headerEdge: { position: "absolute", bottom: 0, left: EDGE, right: EDGE },
	brand: {
		fontSize: 22,
		fontWeight: "bold",
		letterSpacing: 6,
		color: theme.white,
		textDecorationLine: "none",
	},
	label: {
		fontFamily: theme.mono,
		fontSize: 12,
		letterSpacing: 0.12,
		color: "#93908d",
	},
	headerLinks: { flexDirection: "row", gap: "clamp(12px, calc(100vw - 338px), 28px)", marginLeft: "auto" },
	headerLink: {
		fontFamily: theme.mono,
		fontSize: 12,
		fontWeight: "600",
		letterSpacing: 1.2,
		color: theme.ink,
		textDecorationLine: "none",
	},
	nav: {
		position: "fixed",
		top: 72,
		bottom: 0,
		left: SIDE,
		width: 256,
		paddingTop: 16,
		paddingBottom: 24,
		paddingLeft: 24,
		overflow: "scroll",
		fontFamily: theme.mono,
		fontSize: 12,
		lineHeight: 24,
		fontWeight: "500",
		letterSpacing: 0.12,
		variants: {
			layout: {
				narrow: {
					position: "relative",
					top: 0,
					left: 0,
					width: "auto",
					paddingTop: 96,
					paddingBottom: 8,
					paddingRight: 24,
					overflow: "visible",
				},
			},
		},
	},
	navGroup: {
		marginBottom: 20,
		variants: {
			layout: {
				narrow: { flexDirection: "row", flexWrap: "wrap", columnGap: 24, marginBottom: 12 },
			},
		},
	},
	navGroupLabel: {
		marginBottom: 4,
		fontSize: 10,
		lineHeight: 20,
		letterSpacing: 2,
		color: "#6b6966",
		variants: { layout: { narrow: { width: "100%" } } },
	},
	navPage: {
		color: "#93908d",
		textDecorationLine: "none",
		variants: {
			state: {
				start: { color: theme.signal },
				core: { color: CORE_TONE },
				build: { color: BUILD_TONE },
				chain: { color: CHAIN_TONE },
				reference: { color: REFERENCE_TONE },
			},
		},
	},
	navParts: { marginBottom: 4 },
	navPartsEdge: {
		position: "absolute",
		top: 0,
		bottom: 0,
		left: 0,
		backgroundColor: "#d5d3d1",
		opacity: 0.35,
	},
	navNested: { marginLeft: 12, marginBottom: 4 },
	navPart: {
		paddingLeft: 12,
		color: "#d5d3d1",
		textDecorationLine: "none",
		variants: {
			state: {
				start: { color: theme.signal },
				core: { color: CORE_TONE },
				build: { color: BUILD_TONE },
				chain: { color: CHAIN_TONE },
				reference: { color: REFERENCE_TONE },
				dim: { color: "#93908d" },
			},
		},
	},
	navTick: {
		position: "absolute",
		top: 12,
		left: 0,
		width: 4,
		height: 1,
		backgroundColor: "#d5d3d1",
		opacity: 0.4,
		variants: {
			state: {
				start: { opacity: 1, backgroundColor: theme.signal },
				core: { opacity: 1, backgroundColor: CORE_TONE },
				build: { opacity: 1, backgroundColor: BUILD_TONE },
				chain: { opacity: 1, backgroundColor: CHAIN_TONE },
				reference: { opacity: 1, backgroundColor: REFERENCE_TONE },
				dim: {},
			},
		},
	},
	navBar: {
		position: "absolute",
		top: 0,
		left: 0,
		width: 1,
		height: 24,
		opacity: 0,
		variants: {
			state: {
				start: { opacity: 1, backgroundColor: theme.signal },
				core: { opacity: 1, backgroundColor: CORE_TONE },
				build: { opacity: 1, backgroundColor: BUILD_TONE },
				chain: { opacity: 1, backgroundColor: CHAIN_TONE },
				reference: { opacity: 1, backgroundColor: REFERENCE_TONE },
				dim: {},
			},
		},
	},
	navBarWhole: { height: "100%" },
	article: {
		maxWidth: 686,
		marginLeft: "calc(" + SIDE + " + 324px)",
		paddingTop: 128,
		paddingBottom: 120,
		paddingRight: 24,
		variants: { layout: { narrow: { marginLeft: 0, paddingTop: 24, paddingLeft: 24 } } },
	},
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
		margin: 0,
		marginTop: 28,
		marginBottom: 16,
		fontFamily: theme.display,
		fontSize: 20,
		lineHeight: 25,
		fontWeight: "700",
		color: "#d5d3d1",
	},
	subheading: {
		margin: 0,
		marginBottom: 12,
		fontFamily: theme.display,
		fontSize: 16,
		lineHeight: 24,
		fontWeight: "700",
		color: "#d5d3d1",
	},
	anchor: { position: "absolute", top: -96 },
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
	code: { marginBottom: 24, overflow: "scroll" },
	table: { marginBottom: 28 },
	row: {
		flexDirection: "row",
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
	turn: { flexDirection: "row", gap: 24, marginTop: 56, paddingTop: 24 },
	turnEdge: { position: "absolute", top: 0, left: 0, right: 0 },
	turnLink: { flex: 1, minWidth: 0, textDecorationLine: "none" },
	turnNext: { alignItems: "flex-end", textAlign: "right" },
	turnLabel: {
		marginBottom: 4,
		fontFamily: theme.mono,
		fontSize: 12,
		letterSpacing: 1.2,
		color: "#93908d",
	},
	turnTitle: {
		fontFamily: theme.display,
		fontSize: 18,
		lineHeight: 24,
		fontWeight: "700",
		color: "#d5d3d1",
	},
	cellName: { width: 172, flexShrink: 0 },
	cellText: { flex: 1 },
});

function page(path: string): NeonNode {
	return match (path) {
		"/docs/first-program" => <FirstProgram />,
		"/docs/solana-basics" => <SolanaBasics />,
		"/docs/from-anchor" => <FromAnchor />,
		"/docs/program" => <ProgramStructure />,
		"/docs/accounts" => <Accounts />,
		"/docs/validation" => <Validation />,
		"/docs/pdas" => <Pdas />,
		"/docs/cpi" => <Cpi />,
		"/docs/tokens" => <Tokens />,
		"/docs/rollups" => <Rollups />,
		"/docs/randomness" => <Randomness />,
		"/docs/cranks" => <Cranks />,
		"/docs/data" => <AccountData />,
		"/docs/errors-events" => <ErrorsEvents />,
		"/docs/testing" => <Testing />,
		"/docs/clients" => <Clients />,
		"/docs/deploying" => <Deploying />,
		"/docs/security" => <Security />,
		"/docs/performance" => <Performance />,
		"/docs/error-codes" => <ErrorCodes />,
		"/docs/troubleshooting" => <Troubleshooting />,
		_ => <GettingStarted />,
	};
}

function Part(props: { title: string; at: string }): NeonNode {
	const to = "#" + props.at;
	const spot = useContext(Here);
	return <View>
		<a style={d.navPart({ state: shade(spot().tone, to) })} href={to}>{props.title}</a>
		<View style={d.navBar({ state: shade(spot().tone, to) })} />
	</View>;
}

function Fork(props: { title: string; at: string; children: NeonNode }): NeonNode {
	const to = "#" + props.at;
	const spot = useContext(Here);
	return <View>
		<a style={d.navPart({ state: shade(spot().tone, to) })} href={to}>{props.title}</a>
		<View style={d.navTick({ state: shade(spot().tone, to) })} />
		<View style={d.navNested}>
			<Hairline place={d.navPartsEdge} />
			{props.children}
		</View>
		<View style={[d.navBar({ state: shade(spot().tone, to) }), d.navBarWhole]} />
	</View>;
}

function Leaf(props: { path: string; children: NeonNode }): NeonNode {
	const spot = useContext(Here);
	const here = (): boolean => spot().path === props.path;
	return <>
		<a style={d.navPage({ state: here() && picked() === "" ? spot().tone : "" })} href={props.path}>
			{PAGES[indexOfPage(props.path)].title.toUpperCase()}
		</a>
		<Show when={wide() && here()}>
			<View style={d.navParts}>
				<Hairline place={d.navPartsEdge} />
				{props.children}
			</View>
		</Show>
	</>;
}

function Group(props: { label: string; children: NeonNode }): NeonNode {
	const layout = (): string => wide() ? "" : "narrow";
	return <View style={d.navGroup({ layout: layout() })}>
		<span style={d.navGroupLabel({ layout: layout() })}>{props.label}</span>
		{props.children}
	</View>;
}

function Turn(props: { path: string }): NeonNode {
	const at = indexOfPage(props.path);
	const previous: DocsPage = at > 0 ? PAGES[at - 1] : PAGES[0];
	const after: DocsPage = at >= 0 && at < PAGES.length - 1 ? PAGES[at + 1] : PAGES[0];
	return <View style={d.turn}>
		<Hairline place={d.turnEdge} />
		<Show when={at > 0}>
			<a style={d.turnLink} href={previous.path}>
				<View>
					<span style={d.turnLabel}>← PREVIOUS</span>
					<span style={d.turnTitle}>{previous.title}</span>
				</View>
			</a>
		</Show>
		<View style={d.turnLink} />
		<Show when={at >= 0 && at < PAGES.length - 1}>
			<a style={d.turnLink} href={after.path}>
				<View style={d.turnNext}>
					<span style={d.turnLabel}>NEXT →</span>
					<span style={d.turnTitle}>{after.title}</span>
				</View>
			</a>
		</Show>
	</View>;
}

export function Docs(props: { site: DocsSite }): NeonNode {
	const path = props.site.path;
	return <Here.Provider value={(): Place => placeOf(path())}><View style={d.page}>
		<PagePlace path={path()} />
		<View style={d.header}>
			<a style={d.brand} href="/">GEASS</a>
			<span style={d.label}>DOCS</span>
			<View style={d.headerLinks}>
				<a style={d.headerLink} href="/playground">PLAYGROUND</a>
				<a style={d.headerLink} href="/">HOME</a>
			</View>
			<Hairline place={d.headerEdge} />
		</View>
		<View style={d.nav({ layout: wide() ? "" : "narrow" })}>
			<Group label="START">
				<Leaf path="/docs">
					<Part title="At a glance" at="glance" />
					<Part title="Installation" at="installation" />
					<Part title="The Solana toolchain" at="solana-toolchain" />
					<Part title="Check that it works" at="check" />
					<Part title="Your first program" at="first-program" />
				</Leaf>
				<Leaf path="/docs/first-program">
					<Part title="What you will build" at="goal" />
					<Part title="Create the project" at="create" />
					<Part title="The whole program" at="program" />
					<Fork title="Reading it" at="reading">
						<Part title="The account" at="the-account" />
						<Part title="The instructions" at="the-instructions" />
						<Part title="The entry" at="the-entry" />
						<Part title="Syntax TypeScript lacks" at="syntax" />
					</Fork>
					<Part title="Test it" at="test" />
					<Part title="Build it" at="build" />
					<Part title="Deploy it to devnet" at="deploy" />
					<Part title="Call it from TypeScript" at="call" />
					<Part title="Where to go next" at="next" />
				</Leaf>
				<Leaf path="/docs/solana-basics">
					<Part title="Everything is an account" at="accounts" />
					<Part title="Programs and instructions" at="programs" />
					<Part title="Addresses a program controls" at="pdas" />
					<Part title="Conventions on top" at="conventions" />
					<Part title="Tokens" at="tokens" />
				</Leaf>
				<Leaf path="/docs/from-anchor">
					<Part title="What Geass is" at="pipeline" />
					<Part title="The same bytes on chain" at="same-bytes" />
					<Part title="Concept map" at="concept-map" />
					<Fork title="What differs" at="what-differs">
						<Part title="Create and close are calls" at="explicit-lifecycle" />
						<Part title="A check is a type" at="proofs" />
						<Part title="Types first, then decorators" at="types-first" />
						<Part title="No lifetimes, no derives" at="no-lifetimes" />
					</Fork>
					<Part title="Not there yet" at="not-yet" />
				</Leaf>
			</Group>
			<Group label="WRITE A PROGRAM">
				<Leaf path="/docs/program">
					<Part title="The program id" at="program-id" />
					<Part title="Instructions and dispatch" at="instructions" />
					<Part title="Handlers" at="handlers" />
					<Part title="The entry" at="entry" />
				</Leaf>
				<Leaf path="/docs/accounts">
					<Part title="The accounts struct" at="context" />
					<Fork title="Proof types" at="proof-types">
						<Part title="Signers and plain accounts" at="signers" />
						<Part title="Accounts your program owns" at="program-accounts" />
						<Part title="Accounts of other programs" at="external-accounts" />
					</Fork>
					<Part title="Reading the data" at="reading-data" />
					<Part title="Duplicate accounts" at="duplicates" />
					<Part title="Weakening a proof" at="weakening" />
				</Leaf>
				<Leaf path="/docs/validation">
					<Part title="Decorators" at="decorators" />
					<Part title="Names inside a decorator" at="names" />
					<Part title="Your own error" at="custom-errors" />
					<Part title="Order of checks" at="order" />
					<Part title="Refused at compile time" at="refused" />
				</Leaf>
				<Leaf path="/docs/data">
					<Part title="Declaring an account type" at="declaring" />
					<Part title="Field types" at="field-types" />
					<Part title="Create, resize, close" at="lifecycle" />
				</Leaf>
				<Leaf path="/docs/errors-events">
					<Part title="Your program's errors" at="errors" />
					<Part title="Framework errors" at="framework-errors" />
					<Part title="Events" at="events" />
				</Leaf>
				<Leaf path="/docs/pdas">
					<Part title="Checking a PDA" at="constraint" />
					<Part title="What a seed can be" at="seeds" />
					<Part title="Deriving in a handler" at="deriving" />
					<Part title="Creating an account at a PDA" at="creating" />
					<Part title="Storing the bump" at="stored-bump" />
					<Part title="Literal seeds cost nothing" at="folded" />
				</Leaf>
				<Leaf path="/docs/cpi">
					<Part title="Moving lamports" at="transfer" />
					<Part title="Signing with a PDA" at="signing" />
					<Part title="Token calls" at="tokens" />
					<Part title="Any other program" at="raw-invoke" />
				</Leaf>
				<Leaf path="/docs/tokens">
					<Part title="One module, two token programs" at="module" />
					<Part title="Mints and token accounts" at="fields" />
					<Part title="Checking a token account" at="checks" />
					<Part title="Creating a mint" at="create-mint" />
					<Part title="Creating a token account" at="create-account" />
					<Part title="Minting" at="mint-to" />
					<Part title="Transferring" at="transfer" />
					<Part title="Closing a token account" at="close" />
					<Part title="Token-2022 and extensions" at="token-2022" />
					<Part title="Anchor to Geass" at="from-anchor" />
					<Part title="Not there yet" at="not-yet" />
				</Leaf>
			</Group>
			<Group label="SHIP IT">
				<Leaf path="/docs/testing">
					<Part title="Tests beside the program" at="host-tests" />
					<Part title="Running" at="running" />
					<Part title="What the simulator runs" at="simulator" />
					<Part title="Asserting" at="asserting" />
					<Part title="One handler at a time" at="one-handler" />
					<Part title="The program in LiteSVM" at="litesvm" />
					<Part title="Anchor to Geass" at="from-anchor" />
				</Leaf>
				<Leaf path="/docs/clients">
					<Part title="The IDL" at="idl" />
					<Part title="What it holds" at="idl-contents" />
					<Part title="Codama" at="codama" />
					<Part title="Anchor's TypeScript client" at="anchor-client" />
					<Part title="A client in MetaScript" at="metascript-client" />
					<Part title="By hand" at="kit-client" />
					<Part title="Not there yet" at="not-yet" />
				</Leaf>
				<Leaf path="/docs/deploying">
					<Part title="The build" at="build" />
					<Part title="The program id" at="program-id" />
					<Part title="The deploy keypair" at="keypair" />
					<Part title="Deploying" at="deploy" />
					<Part title="Anchor to Geass" at="from-anchor" />
				</Leaf>
				<Leaf path="/docs/security">
					<Part title="Secure by default" at="default" />
					<Part title="Checks that stay on" at="always-on" />
					<Part title="Integer overflow is yours" at="overflow" />
					<Part title="An unsigned cast keeps the low bits" at="narrowing" />
					<Part title="Refused at compile time" at="refused" />
					<Part title="Runtime limits" at="limits" />
					<Part title="A security contact" at="security-txt" />
					<Part title="Below the macros" at="raw" />
					<Part title="Known limitations" at="limitations" />
				</Leaf>
				<Leaf path="/docs/performance">
					<Part title="Results" at="results" />
					<Part title="Reading the table" at="reading" />
					<Part title="How it is measured" at="method" />
					<Part title="Run it yourself" at="reproduce" />
					<Part title="Signed division" at="signed-division" />
				</Leaf>
			</Group>
			<Group label="MAGICBLOCK">
				<Leaf path="/docs/rollups">
					<Part title="The life of a delegated account" at="life" />
					<Part title="Delegating" at="delegating" />
					<Part title="What you check yourself" at="delegate-checks" />
					<Part title="Committing" at="committing" />
					<Part title="Coming back" at="undelegation" />
					<Part title="Reading a delegated account" at="delegated" />
					<Part title="Testing" at="testing" />
					<Part title="MagicBlock's Rust SDK to Geass" at="from-sdk" />
				</Leaf>
				<Leaf path="/docs/randomness">
					<Part title="Requesting" at="requesting" />
					<Part title="Naming the callback" at="callback-id" />
					<Part title="The callback" at="callback" />
					<Part title="Limits" at="limits" />
					<Part title="Testing" at="testing" />
				</Leaf>
				<Leaf path="/docs/cranks">
					<Part title="The accounts" at="accounts" />
					<Part title="Creating" at="creating" />
					<Part title="The schedule" at="schedule" />
					<Part title="When it fires" at="firing" />
					<Part title="Cancelling" at="sweeping" />
					<Part title="Testing" at="testing" />
					<Part title="The older scheduleTask" at="schedule-task" />
				</Leaf>
			</Group>
			<Group label="REFERENCE">
				<Leaf path="/docs/error-codes">
					<Part title="Reading an error" at="reading" />
					<Part title="Your errors" at="yours" />
					<Part title="Instruction errors" at="instruction" />
					<Part title="Constraint errors" at="constraint" />
					<Part title="Account errors" at="account" />
					<Part title="Runtime errors" at="runtime" />
				</Leaf>
				<Leaf path="/docs/troubleshooting">
					<Part title="It does not compile" at="compile" />
					<Part title="A test fails" at="test" />
					<Part title="It fails on chain" at="chain" />
				</Leaf>
			</Group>
		</View>
		<View style={d.article({ layout: wide() ? "" : "narrow" })}>
			<For each={[path()]}>{(at: string): NeonNode => <>{page(at)}<Turn path={at} /></>}</For>
		</View>
	</View></Here.Provider>;
}
