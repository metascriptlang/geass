import { NeonNode } from "../../../../neon/src/render/node";
import {
	Head, Heading, L, Lede, M, P, Row, Sample, Subheading, Table, Title, tone,
} from "../ui/prose";

const INSTALL_CODE = "$ curl -fsSL https://metascriptlang.org/install.sh | sh";
const VERSION_CODE = "$ msc --version";
const TOOLCHAIN_CODE = "$ sh -c \"$(curl -sSfL https://release.anza.xyz/stable/install)\"
$ cargo-build-sbf --install-only --tools-version v1.57";
const ID_CODE = "const config = {
  defines: { programId: \"B7ihZyoXZ1fwAY3TugkiFJ6SXkzJwMuQrxrekBaSmn32\" },
};
export default config;";
const STATE_CODE = "import {
  Discriminator, Program, ProgramError, System, Writable, WritableSigner,
  accountDiscriminator, accounts, createPda, failWith, instruction,
} from \"std/solana\";

export struct Counter {
  value: uint64;
  bump: uint8;
  pad: uint8[7];
}

export function discriminator(this typeof Counter): Discriminator {
  return @comptime { return accountDiscriminator(\"Counter\"); };
}";
const HANDLER_CODE = "export struct InitAccounts {
  payer: WritableSigner;
  counter: Writable;
  systemProgram: Program<System>;
}

function init(): Result<uint64, ProgramError> {
  const x = try accounts<InitAccounts>();
  const made = try createPda<Counter>(x.payer, x.counter, [\"counter\"]);
  const counter = made.asMutable().data();
  counter.value = 42;
  counter.bump = made.foundBump();
  return Result.ok(0);
}";
const ENTRY_CODE = "export enum HelloOp {
  Init,
}

export function dispatch(): Result<uint64, ProgramError> {
  return match (try instruction<HelloOp>()) {
    HelloOp.Init => init(),
  };
}

export function entry(): void {
  const result = dispatch();
  if (!result.ok) { failWith(result.error); }
}

when (!testBuild) {
  entry();
}";
const BUILD_CODE = "$ msc check program.ms
$ msc build program.ms --os=solana --release --output=out/counter.so";

export function GettingStarted(): NeonNode {
	return <>
		<Title tone={tone.start} title="Getting started" />
		<Lede t={"Geass is the Solana toolkit of MetaScript. You write TypeScript syntax; the " +
			"compiler writes C and builds it into an sBPF program, with no Rust and no " +
			"framework underneath."} />
		<Heading at="installation" title="Installation" />
		<P>
			Geass is not a separate package. It is the <M t="std/solana" /> module that ships
			with the MetaScript compiler, <M t="msc" />. One command installs it:
		</P>
		<Sample code={INSTALL_CODE} />
		<P>
			The installer puts <M t="msc" /> on your <M t="PATH" />. Open a new terminal and
			check it:
		</P>
		<Sample code={VERSION_CODE} />
		<P>
			The first build for your own machine, such as <M t="msc test" />, asks before it
			downloads Zig 0.16.0 as its C compiler: about 55 MB to download (97 MB on
			Windows), about 400 MB once unpacked on a Mac. Pass <M t="--cc=clang" /> to use
			the one you have. A build for Solana does not use Zig.
		</P>
		<Subheading at="solana-toolchain" title="The Solana toolchain" />
		<P>
			Building for the chain needs Anza's platform tools, the clang and linker that
			know the SBF target. The Solana CLI brings the command that fetches them, and
			deploys the result:
		</P>
		<Sample code={TOOLCHAIN_CODE} />
		<P>
			The tools land in <M t="~/.cache/solana" />, where <M t="msc" /> finds them.{" "}
			<M t="MSC_SBF_CLANG" /> names another clang when you keep several versions.
		</P>
		<Heading at="first-program" title="Your first program" />
		<P>
			A counter in one file, <M t="program.ms" />, with its id beside it in{" "}
			<M t="build.ms" />. It has the four parts every Geass program has.
		</P>
		<Subheading at="program-id" title="The program id" />
		<P>
			The id lives in the project's <M t="build.ms" />, where Anchor keeps it in{" "}
			<M t="Anchor.toml" /> beside <M t="declare_id!" />. Every module reads the same one:
		</P>
		<Sample code={ID_CODE} />
		<Subheading at="account" title="An account" />
		<P>
			State is a fixed-size struct. Its discriminator is the 8 bytes Anchor would
			compute, found at compile time from the type's own name:
		</P>
		<Sample code={STATE_CODE} />
		<Subheading at="instruction" title="An instruction" />
		<P>
			A struct lists the accounts the instruction takes; each field's type is the check
			it must pass. The handler asks for them with <M t="accounts<T>()" /> and gets them
			already verified:
		</P>
		<Sample code={HANDLER_CODE} />
		<Subheading at="entry" title="Dispatch and entry" />
		<P>
			An enum names the instructions, <M t="instruction<Op>()" /> picks one by its
			8-byte discriminator, and <M t="entry" /> reports a failure to the runtime:
		</P>
		<Sample code={ENTRY_CODE} />
		<P>
			The last block is the program's entrypoint: the chain runs the top level of the
			file. Leave the call out and the program still builds, does nothing and reports
			success.
		</P>
		<Subheading at="syntax" title="Syntax TypeScript does not have" />
		<Table>
			<Head a="YOU READ" b="IT MEANS" />
			<Row a="struct" b="A value with a fixed layout in memory, field after field" />
			<Row a="uint64, uint8[7]" b="Sized integers and arrays of a fixed length" />
			<Row
				a="pad: uint8[7]"
				b="Fills the struct to 16 bytes, so the layout has no hidden gap"
			/>
			<Row
				a="try call()"
				b="On a failed Result, returns the error from this function. Otherwise gives the value"
			/>
			<Row a="match (x) { A => ..., }" b="A switch that must cover every case" />
			<Row a="when (flag) { }" b="Decided by the compiler. The other branch is not built" />
			<Row a="@comptime { }" b="Runs in the compiler; the result is a constant" />
			<Row
				a="function f(this typeof Counter)"
				b="A function called as Counter.f(), declared outside the type"
			/>
			<Row a="Result.ok(0)" b="Success. The number is not sent anywhere" />
		</Table>
		<P>
			The rest of the language is in the{" "}
			<L to="https://metascriptlang.org/learn" t="MetaScript documentation" />.
		</P>
		<Heading at="build-and-test" title="Build and test" />
		<P>
			<M t="msc check" /> type-checks the program and runs every compile-time check
			of its accounts. <M t="--os=solana" /> writes the program the chain runs:
		</P>
		<Sample code={BUILD_CODE} />
		<P>
			This counter builds to a 3,344-byte <M t="counter.so" /> with platform tools
			v1.57. It has no test yet: <L to="/docs/testing" t="Testing" /> writes its first
			one and runs it on your machine, and <L to="/docs/deploying" t="Deploying" />{" "}
			puts it on a cluster.
		</P>
		<Heading at="next" title="Where to go next" />
		<Table>
			<Head a="YOU" b="READ" />
			<Row a="Have not written a Solana program" b="Solana in five minutes, the next page" />
			<Row a="Write Anchor programs" b="Coming from Anchor" />
			<Row a="Want to try without installing" b="The Playground, in the header" />
		</Table>
		<P>
			The source, the releases and the issue tracker are at{" "}
			<L to="https://github.com/metascriptlang/compiler" t="github.com/metascriptlang/compiler" />;
			Geass is its <M t="std/solana" /> directory. Questions go to the{" "}
			<L to="https://discord.gg/gCwkmqS3xB" t="MetaScript Discord" />.
		</P>
	</>;
}

export function SolanaBasics(): NeonNode {
	return <>
		<Title tone={tone.start} title="Solana in five minutes" />
		<Lede t={"The words the other pages use without explaining, for a reader who has not written" +
			" a Solana program."} />
		<Heading at="accounts" title="Everything is an account" />
		<P>
			Solana keeps all state in accounts. A program has no variables of its own
			between two calls; what it remembers, it writes into an account.
		</P>
		<Table>
			<Head a="WORD" b="MEANING" />
			<Row a="account" b="An address with a balance, a byte array and an owner" />
			<Row a="address" b="32 bytes, written in base58. Pubkey in Geass" />
			<Row a="lamports" b="The balance. One SOL is 1,000,000,000 lamports" />
			<Row
				a="rent"
				b="The balance an account must hold to exist, set by the size of its data. Closing the account gives it back"
			/>
			<Row
				a="owner"
				b="The one program allowed to change the account's data and take its lamports. A new account belongs to the System program"
			/>
			<Row a="data" b="The bytes. Your struct is a view of them" />
		</Table>
		<P>
			The full model is in{" "}
			<L to="https://solana.com/docs/core/accounts" t="the Solana documentation" />.
		</P>
		<Heading at="programs" title="Programs and instructions" />
		<P>
			A program is an account marked executable that holds compiled code. It runs
			when a transaction sends it an instruction.
		</P>
		<Table>
			<Head a="WORD" b="MEANING" />
			<Row
				a="instruction"
				b="One call: a program id, a list of accounts and bytes of data. The program reads nothing the list does not name"
			/>
			<Row
				a="transaction"
				b="One or more instructions that succeed or fail together"
			/>
			<Row a="signer" b="An account whose key signed the transaction. Signer in Geass" />
			<Row
				a="writable"
				b="An account the transaction declared it may change. Writable in Geass"
			/>
			<Row a="System program" b="Creates accounts and moves lamports. Its address is written as 32 ones" />
			<Row
				a="compute units"
				b="The price of running. An instruction gets 200,000 unless the transaction asks for more"
			/>
			<Row a="sBPF, SBF" b="The bytecode a program is compiled to. The file is a .so" />
		</Table>
		<P>
			<L to="https://solana.com/docs/core/transactions" t="Transactions" />,{" "}
			<L to="https://solana.com/docs/core/programs" t="programs" /> and{" "}
			<L to="https://solana.com/docs/core/fees" t="fees" /> in the Solana documentation.
		</P>
		<Heading at="pdas" title="Addresses a program controls" />
		<Table>
			<Head a="WORD" b="MEANING" />
			<Row
				a="PDA"
				b="A program derived address: computed from a program id and seeds, with no private key. Only that program can sign for it"
			/>
			<Row a="seeds" b="The bytes that name one PDA: a word, a wallet, a number" />
			<Row
				a="bump"
				b="One more byte, searched from 255 down, that moves the address off the signature curve. Programs store it to skip the search"
			/>
			<Row
				a="CPI"
				b="A cross-program invocation: your program calls another one inside the same instruction"
			/>
		</Table>
		<P>
			<L to="https://solana.com/docs/core/pda" t="PDAs" /> and{" "}
			<L to="https://solana.com/docs/core/cpi" t="CPIs" /> in the Solana documentation;{" "}
			<L to="/docs/pdas" t="PDAs" /> and <L to="/docs/cpi" t="Cross-program calls" />{" "}
			here.
		</P>
		<Heading at="conventions" title="Conventions on top" />
		<P>
			The chain does not know what an account's bytes mean. These are conventions,
			started by Anchor and kept by Geass, that let tools read a program:
		</P>
		<Table>
			<Head a="WORD" b="MEANING" />
			<Row
				a="discriminator"
				b="The first 8 bytes of an account or of an instruction's data. They name its type"
			/>
			<Row
				a="IDL"
				b="A JSON file that lists a program's instructions, accounts and errors. Clients are generated from it"
			/>
			<Row a="error code" b="A number the program returns. Yours start at 6000" />
		</Table>
		<Heading at="tokens" title="Tokens" />
		<P>
			A token is not built into the chain. It is accounts owned by the Token program
			or by Token-2022, its newer version.
		</P>
		<Table>
			<Head a="WORD" b="MEANING" />
			<Row a="mint" b="The account that defines one token: its supply and decimals" />
			<Row a="token account" b="Holds a balance of one mint for one wallet" />
			<Row
				a="associated token account"
				b="The token account at the address derived from the wallet and the mint, so anyone can find it"
			/>
		</Table>
		<P>
			<L to="https://solana.com/docs/tokens" t="Tokens in the Solana documentation" />;{" "}
			<L to="/docs/tokens" t="Tokens" /> here.
		</P>
	</>;
}

export function FromAnchor(): NeonNode {
	return <>
		<Title tone={tone.start} title="Coming from Anchor" />
		<Lede t={"Geass is not built on Anchor. It compiles to C and keeps Anchor's conventions on " +
			"the wire, so what you know carries over."} />
		<Heading at="pipeline" title="What Geass is" />
		<P>
			MetaScript compiles to C, and the clang of Anza's platform tools builds the C
			into an sBPF v3 program. There is no Rust in the build and no Anchor crate in the
			program. Your accounts are read in place, as in Pinocchio: <M t="data()" /> is a
			pointer into the account, not a decoded copy.
		</P>
		<Heading at="same-bytes" title="The same bytes on chain" />
		<P>
			What Geass shares with Anchor is the convention, not the code: account and
			instruction discriminators, the zero-copy account layout, instruction encoding,
			error codes, events and the format of the IDL. Codama, an Anchor client, an
			explorer or an indexer reads a Geass program as it reads one written in Rust.
		</P>
		<Heading at="concept-map" title="Concept map" />
		<Table>
			<Head a="ANCHOR" b="GEASS" />
			<Row a="declare_id!(...)" b="programId in the defines of build.ms" />
			<Row
				a="#[program] mod"
				b="an enum of instructions and a dispatch() that matches on instruction<Op>()"
			/>
			<Row a="Context<T>" b="const x = try accounts<T>()" />
			<Row
				a="handler arguments"
				b="const a = try args<T>(), a struct of fixed-size fields read in Borsh order"
			/>
			<Row a="#[derive(Accounts)]" b="a plain struct whose field types are the checks" />
			<Row
				a="#[account(...)]"
				b="decorators on the field: @seeds, @bump, @hasOne, @address, @constraint, and three for tokens"
			/>
			<Row a="#[account] struct" b="a struct plus one exported discriminator function" />
			<Row
				a="init, payer, space"
				b="create<T>(payer, target) or createPda<T>(payer, target, seeds)"
			/>
			<Row a="close = dest" b="close(account, dest)" />
			<Row a="realloc = size" b="realloc<T>(account, space, payer)" />
			<Row
				a="ctx.bumps.name"
				b="foundBump() on a WritablePda field, or the bump createPda returns"
			/>
			<Row a="CpiContext::new(..).with_signer(seeds)" b="signed(call, seeds)" />
			<Row a="#[error_code] enum" b="an enum and a converter to ProgramError" />
			<Row a="emit!(Event { .. })" b="emit<Event>(value)" />
			<Row a="Pubkey / Address" b="Pubkey" />
			<Row a="u64, u8, bool" b="uint64, uint8, boolean" />
			<Row a="Result<()>" b="Result<uint64, ProgramError>" />
			<Row a="anchor build" b="msc build program.ms --os=solana --release" />
			<Row a="anchor test" b="msc test program.ms" />
		</Table>
		<Heading at="what-differs" title="What differs" />
		<Subheading at="explicit-lifecycle" title="Create and close are calls" />
		<P>
			Anchor creates, resizes and closes accounts from attributes. Here those three are
			calls in the handler, so the order they run in is the order you read. Checks stay
			declarative; <M t="mut" /> and <M t="signer" /> are the field's type.
		</P>
		<Subheading at="proofs" title="A check is a type" />
		<P>
			A verified account is a value only the toolkit can build. A function that needs a
			signer takes a <M t="Signer" />, and there is no cast that makes one.
		</P>
		<Subheading at="types-first" title="Types first, then decorators" />
		<P>
			Both check the type of every field first and the constraints after. Anchor's{" "}
			<M t="mut" /> is a constraint; in Geass, writable is part of the field's type. So
			a read-only account in a <M t="Mutable" /> field and a wrong owner in the next
			field fail with 2000 here and 3007 in Anchor.{" "}
			<L to="/docs/validation#order" t="Order of checks" /> has the rule.
		</P>
		<Subheading at="no-lifetimes" title="No lifetimes, no derives" />
		<P>
			There is no <M t="'info" /> and no derive macro. Handlers are ordinary
			functions that return a <M t="Result" />, and <M t="try" /> passes a failure up.
		</P>
		<Heading at="not-yet" title="Not there yet" />
		<P>
			These have no form of their own today: optional accounts and nested account
			structs, <M t="init_if_needed" />, <M t="seeds::program" />, the{" "}
			<M t="owner" /> constraint, Borsh accounts with a <M t="String" /> or a{" "}
			<M t="Vec" />, 128-bit integers, the <M t="require!" /> macros and{" "}
			<M t="#[msg]" /> texts. Most are a few lines in the handler: an <M t="if" /> that
			returns the error, a branch that creates the account, a fixed array with its
			length beside it.
		</P>
		<P>
			Two have no short form: a typed call into another program from its IDL like{" "}
			<M t="declare_program!" />, and failure logs that name the account that failed.
			A failed check logs its error code and nothing else. <M t="logText" /> is{" "}
			<M t="msg!" />; <M t="logU64" />, <M t="logPubkey" /> and <M t="emit" /> log
			numbers, keys and events.
		</P>
	</>;
}
