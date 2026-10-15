import { NeonNode } from "../../../../neon/src/render/node";
import {
	Head, Heading, L, Lede, M, P, Row, Sample, Subheading, Table, Title, tone,
} from "../ui/prose";

const INSTALL_CODE = "$ curl -fsSL https://metascriptlang.org/install.sh | sh";
const GLANCE_CODE = "export struct IncrementAccounts {
  authority: Signer;
  @seeds(\"counter\") @bump(counter.bump) counter: Mutable<Counter>;
}

function increment(): Result<uint64, ProgramError> {
  const x = try accounts<IncrementAccounts>();
  const counter = x.counter.data();
  if (counter.authority != x.authority.key()) {
    return Result.err(CounterError.NotYourCounter);
  }
  counter.count += 1;
  return Result.ok(0);
}";
const TOOLCHAIN_CODE = "$ sh -c \"$(curl -sSfL https://release.anza.xyz/stable/install)\"
$ cargo-build-sbf --install-only --tools-version v1.57";
const CHECK_CODE = "$ msc --version
$ solana --version";

export function GettingStarted(): NeonNode {
	return <>
		<Title tone={tone.start} title="Getting started" />
		<Lede t={"Geass is the Solana toolkit of MetaScript. You write TypeScript syntax; the " +
			"compiler writes C and builds it into an sBPF program, with no Rust and no " +
			"framework underneath."} />
		<Heading at="glance" title="At a glance" />
		<P>
			One instruction of a counter program. The struct lists the accounts the
			instruction takes, and each field's type is a check that passes before the
			function runs: here, that the caller signed and that the counter is this
			program's, at its address. The rest is the TypeScript you know:
		</P>
		<Sample code={GLANCE_CODE} />
		<P>
			The output is an ordinary Solana program that Anchor's tools, Codama and explorers
			read like one written in Rust.
		</P>
		<Heading at="installation" title="Installation" />
		<P>
			Geass is not a separate package. It is the <M t="std/solana" /> module that ships
			with the MetaScript compiler, <M t="msc" />. One command installs it:
		</P>
		<Sample code={INSTALL_CODE} />
		<P>
			The installer puts <M t="msc" /> on your <M t="PATH" />; open a new terminal
			before you use it.
		</P>
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
		<Heading at="check" title="Check that it works" />
		<P>In a new terminal, both commands print a version:</P>
		<Sample code={CHECK_CODE} />
		<Heading at="first-program" title="Your first program" />
		<P>
			<L to="/docs/first-program" t="Your first program" /> builds a counter from an
			empty folder to a deployed program you call from TypeScript, with a test on the
			way. Pick where to start:
		</P>
		<Table>
			<Head a="YOU" b="READ" />
			<Row a="Want to build something now" b="Your first program, the next page" />
			<Row a="Have not written a Solana program" b="Solana in five minutes" />
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
			<Row a="anchor build" b="msc build src/index.ms --os=solana --release" />
			<Row a="anchor test" b="msc test src/index.ms" />
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
