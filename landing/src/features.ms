import { Accessor } from "../../../neon/src/core/signal";
import { element } from "../../../neon/src/macros/ui/element";
import { NeonNode } from "../../../neon/src/render/node";
import { createStyles, styleOf } from "../../../neon/src/macros/ui/style";
import { theme } from "./theme";
import { Chapter } from "./ui/chapter";

const DROP_FROM = "translateY(calc(-1 * (clamp(0, (0.3 - (var(--page, 0) - ";
const DROP_TO = ") / 0.1) / 0.25, 1) * (100vh - 480px)";
const CREEP_FROM = " + clamp(0, (0.85 - (var(--page, 0) - ";
const CREEP_TO = ") / 0.1) / 0.55, 1) * 1.4vh";
const LEAVE_FROM = " - clamp(0, ((var(--page, 0) - ";
const LEAVE_TO = ") / 0.1 - 0.85) / 0.1, 1) * 12vh";

const FADE_FROM = "opacity(calc(pow(clamp(0, ((var(--page, 0) - ";
const FADE_TO = ") / 0.1 - 0.05) / 0.25, 1), 3)))";

const f = createStyles({
	toneSyntax: { color: theme.signal },
	toneGuard: { color: "#ffa828" },
	toneTarget: { color: "#00ffaa" },
	rideInterface: {
		transform: DROP_FROM + "0.200" + DROP_TO + CREEP_FROM + "0.200" + CREEP_TO
			+ LEAVE_FROM + "0.200" + LEAVE_TO + ")))",
		filter: FADE_FROM + "0.200" + FADE_TO,
	},
	rideGuard: {
		transform: DROP_FROM + "0.300" + DROP_TO + CREEP_FROM + "0.300" + CREEP_TO
			+ LEAVE_FROM + "0.300" + LEAVE_TO + ")))",
		filter: FADE_FROM + "0.300" + FADE_TO,
	},
	rideCompiler: {
		transform: DROP_FROM + "0.400" + DROP_TO + CREEP_FROM + "0.400" + CREEP_TO
			+ LEAVE_FROM + "0.400" + LEAVE_TO + ")))",
		filter: FADE_FROM + "0.400" + FADE_TO,
	},
	rideMemory: {
		transform: DROP_FROM + "0.500" + DROP_TO + CREEP_FROM + "0.500" + CREEP_TO
			+ LEAVE_FROM + "0.500" + LEAVE_TO + ")))",
		filter: FADE_FROM + "0.500" + FADE_TO,
	},
	rideRuntime: {
		transform: DROP_FROM + "0.600" + DROP_TO + CREEP_FROM + "0.600" + CREEP_TO
			+ LEAVE_FROM + "0.600" + LEAVE_TO + ")))",
		filter: FADE_FROM + "0.600" + FADE_TO,
	},
	rideTarget: {
		transform: DROP_FROM + "0.700" + DROP_TO + CREEP_FROM + "0.700" + CREEP_TO
			+ LEAVE_FROM + "0.700" + LEAVE_TO + ")))",
		filter: FADE_FROM + "0.700" + FADE_TO,
	},
});

const INTERFACE_CODE = "export struct Counter {
  authority: Pubkey;
  value: uint64;
  bump: uint8;
  pad: uint8[7];
}";
const GUARD_CODE = "export struct InitAccounts {
  payer: WritableSigner;
  counter: Writable;
  systemProgram: Program<System>;
}";
const COMPILER_CODE = "$ msc check counter.ms
$ msc build counter.ms --os=solana";
const MEMORY_CODE = "const counter = x.counter.data();
counter.value += 1;
return Result.ok(counter.value);";
const RUNTIME_CODE = "$ msc build counter.ms --os=solana --release";
const TARGET_CODE = "$ solana program deploy out/release/counter.so";

export function Features(
	props: { chapter: Accessor<int32>; coded: Accessor<int32>; compact: Accessor<boolean> },
): NeonNode {
	return <>
		<Chapter
			at={0}
			current={props.chapter()}
			coded={props.coded()}
			compact={props.compact()}
			title="TypeScript syntax"
			body="Write on-chain programs in the language you already know."
			point="INTERFACE · TYPESCRIPT"
			code={INTERFACE_CODE}
			tone={f.toneSyntax}
			travel={f.rideInterface}
		/>
		<Chapter
			at={1}
			current={props.chapter()}
			coded={props.coded()}
			compact={props.compact()}
			title="Checked before it ships"
			body="An account reaches your handler only through a type that checked it."
			point="GUARD · COMPILE-TIME"
			code={GUARD_CODE}
			tone={f.toneSyntax}
			travel={f.rideGuard}
		/>
		<Chapter
			at={2}
			current={props.chapter()}
			coded={props.coded()}
			compact={props.compact()}
			title="Powered by MetaScript"
			body="One compiler takes your source to a Solana program."
			point="COMPILER · METASCRIPT"
			code={COMPILER_CODE}
			tone={f.toneGuard}
			travel={f.rideCompiler}
		/>
		<Chapter
			at={3}
			current={props.chapter()}
			coded={props.coded()}
			compact={props.compact()}
			title="No garbage collector"
			body="Account data is read and written in place, with nothing to collect."
			point="MEMORY · NO GC"
			code={MEMORY_CODE}
			tone={f.toneGuard}
			travel={f.rideMemory}
		/>
		<Chapter
			at={4}
			current={props.chapter()}
			coded={props.coded()}
			compact={props.compact()}
			title="Zero runtime overhead"
			body="Nothing ships with your program but your program."
			point="RUNTIME · ZERO OVERHEAD"
			code={RUNTIME_CODE}
			tone={f.toneTarget}
			travel={f.rideRuntime}
		/>
		<Chapter
			at={5}
			current={props.chapter()}
			coded={props.coded()}
			compact={props.compact()}
			title="Native on Solana"
			body="Straight to SBF bytecode, ready to deploy."
			point="TARGET · SOLANA SBF"
			code={TARGET_CODE}
			tone={f.toneTarget}
			travel={f.rideTarget}
		/>
	</>;
}
