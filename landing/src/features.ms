import { Accessor } from "../../../neon/src/core/signal";
import { element } from "../../../neon/src/macros/ui/element";
import { NeonNode } from "../../../neon/src/render/node";
import { createStyles, styleOf } from "../../../neon/src/macros/ui/style";
import { theme } from "./theme";
import { pageShare, unit } from "./pageScroll";
import { Chapter } from "./ui/chapter";

const CHAPTER_SPAN = 0.1;

function riseAt(at: number): string {
	const into = (pageShare() - at) / CHAPTER_SPAN;
	const drop = unit((0.3 - into) / 0.25);
	const creep = unit((0.85 - into) / 0.55);
	const leave = unit((into - 0.85) / 0.1);
	return `translateY(calc(-1 * (${drop} * (100vh - 480px) + ${creep} * 1.4vh - ${leave} * 12vh)))`;
}

function fadeAt(at: number): string {
	const into = (pageShare() - at) / CHAPTER_SPAN;
	return `opacity(${Math.pow(unit((into - 0.05) / 0.25), 3)})`;
}

const f = createStyles({
	toneSyntax: { color: theme.signal },
	toneGuard: { color: "#ffa828" },
	toneTarget: { color: "#00ffaa" },
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
			rise={riseAt(0.2)}
			fade={fadeAt(0.2)}
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
			rise={riseAt(0.3)}
			fade={fadeAt(0.3)}
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
			rise={riseAt(0.4)}
			fade={fadeAt(0.4)}
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
			rise={riseAt(0.5)}
			fade={fadeAt(0.5)}
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
			rise={riseAt(0.6)}
			fade={fadeAt(0.6)}
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
			rise={riseAt(0.7)}
			fade={fadeAt(0.7)}
		/>
	</>;
}
