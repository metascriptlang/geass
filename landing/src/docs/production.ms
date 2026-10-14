import { NeonNode } from "../../../../neon/src/render/node";
import {
	Head, Heading, L, Lede, M, P, Row, Sample, Subheading, Table, Title, tone,
} from "../ui/prose";

const DANGER_CODE = "$ msc build program.ms --os=solana --danger
error: --danger is refused on --os=solana: it drops the bound, range, object and division checks that guard a program fed adversarial input
  → use --release, which links with LTO on this target";
const GUARD_CODE = "const limit: uint64 = 1000000;
if (amount > limit || counter.value > limit - amount) {
  return Result.err(CounterError.LimitExceeded);
}
counter.value += amount;";
const NARROW_CODE = "if (given.bump > 255) {
  return Result.err(ProgramError.invalidInstructionData());
}
counter.bump = given.bump as uint8;";
const SECURITY_TXT_CODE = "import { securityTxt } from \"std/solana\";

securityTxt({
  name: \"Counter\",
  projectUrl: \"https://example.com\",
  contacts: \"email:security@example.com\",
  policy: \"https://example.com/security\",
});";
const RAW_CODE = "const vault = x.vault.asAccount();
const user = x.user.asAccount();
vault.setLamports(vault.lamports() - given.amount);
user.setLamports(user.lamports() + given.amount);";
const DIVISION_CODE = "const config = {
  globalImports: [\"std/solana/arithmetic\"],
};
export default config;";

export function Security(): NeonNode {
	return <>
		<Title tone={tone.build} title="Security" />
		<Lede t={"A handler reaches an account only through a proof, and the checks behind a proof " +
			"cannot be switched off."} />
		<Heading at="default" title="Secure by default" />
		<Table>
			<Head a="CHECK" b="WHERE IT LIVES" />
			<Row a="Enough accounts" b="accounts<T>(), before any field (3005)" />
			<Row a="Signed, writable" b="The field type (3010, 2000)" />
			<Row
				a="Owner"
				b="Owned<T>, Mutable<T>, External<T>, SystemAccount (3007, 3011)"
			/>
			<Row
				a="Discriminator, size, field values"
				b="Owned<T>, Mutable<T> (3001, 3002, 3003)"
			/>
			<Row a="A writable account passed twice" b="Every writable field type (2040)" />
			<Row a="Address" b="@seeds with @bump, @address (2006, 2012)" />
			<Row a="Relations" b="@hasOne, @constraint (2001, 2003)" />
		</Table>
		<P>
			There is no <M t="guardrails" /> feature to turn off. The way to check less is to
			declare a weaker type, and the weaker type says so: an <M t="Account" /> field
			proves the account is present and nothing else.
		</P>
		<Heading at="always-on" title="Checks that stay on" />
		<P>
			An index out of range, a division by zero and a cast to a signed type that does
			not hold the value stop the program. One cast does not stop yet: a{" "}
			<M t="uint64" /> past 2⁶³ cast to <M t="int64" /> becomes negative, so compare
			it first. The flag that drops those checks is refused for a program:
		</P>
		<Sample code={DANGER_CODE} />
		<Heading at="narrowing" title="An unsigned cast keeps the low bits" />
		<P>
			<M t="as" /> between unsigned integers does not stop: a <M t="uint16" /> holding 256
			cast to <M t="uint8" /> is 0, and one holding 300 is 44. A constant that does not
			fit is a compile error. The compiler asks for the cast wherever a
			wider value meets a narrower slot, so compare first when the value comes from an
			instruction:
		</P>
		<Sample code={NARROW_CODE} />
		<Heading at="overflow" title="Integer overflow is yours" />
		<P>
			<M t="+" />, <M t="-" /> and <M t="*" /> wrap without an error, as in a Rust
			program built with <M t="overflow-checks = false" />: on a <M t="uint64" />,
			1 minus 2 is 18,446,744,073,709,551,615. Compare before you subtract or add:
		</P>
		<Sample code={GUARD_CODE} />
		<Heading at="refused" title="Refused at compile time" />
		<Table>
			<Head a="YOU WRITE" b="WHAT HAPPENS" />
			<Row a="A proof by cast or struct literal" b="Refused. A proof comes from a check" />
			<Row a="A write through Owned<T>" b="The data is read-only" />
			<Row a="A module-level let" b="A program has no writable static storage" />
			<Row a="A function frame over 4,096 bytes" b="The build fails, with or without LTO" />
			<Row a="A CPI written with over 64 accounts" b="The runtime's limit, named" />
		</Table>
		<P>
			An account type with padding between its fields does build. The IDL is what
			refuses it, naming the field and the bytes, so generate the IDL before you
			deploy.
		</P>
		<Heading at="limits" title="Runtime limits" />
		<Table>
			<Head a="LIMIT" b="VALUE" />
			<Row a="Stack" b="4,096 bytes for each function" />
			<Row a="Heap" b="32 KiB, never freed" />
			<Row a="Accounts of an instruction" b="255" />
			<Row a="Account infos of a CPI" b="64" />
			<Row a="An event" b="1,024 bytes" />
			<Row a="Account growth" b="10,240 bytes in one instruction" />
		</Table>
		<Heading at="security-txt" title="A security contact" />
		<P>
			<M t="securityTxt" /> at module scope writes the block explorers read into the
			program, in the layout of the <M t="solana-security-txt" /> crate. The four
			fields shown are required:
		</P>
		<Sample code={SECURITY_TXT_CODE} />
		<Heading at="raw" title="Below the macros" />
		<P>
			Every field type has a function that checks one account by index:{" "}
			<M t="signer(i)" />, <M t="mutable<T>(i)" />, <M t="external<T>(i)" /> and the
			rest. <M t="account(i)" /> returns the account with no check, and{" "}
			<M t="asAccount()" /> turns a proof back into one. Validate with{" "}
			<M t="accounts<T>()" />, then go raw where you need to:
		</P>
		<Sample code={RAW_CODE} />
		<Heading at="limitations" title="Known limitations" />
		<P>
			Geass has not been audited. The figures on these pages come from LiteSVM 1.4.1
			with platform-tools v1.57, not from a cluster.
		</P>
		<Table>
			<Head a="TODAY" b="WHAT TO DO" />
			<Row
				a="The test simulator accepts a CPI whose program is not among the accounts"
				b="Run the built program in LiteSVM too. See Testing"
			/>
			<Row
				a="A cast between unsigned integers keeps the low bits"
				b="Compare before the cast"
			/>
			<Row
				a="std/solana/arithmetic does not stop on the lowest int64 divided by -1"
				b="Refuse that divisor yourself. See Performance"
			/>
			<Row
				a="The MagicBlock bindings are tested in the simulator only"
				b="Prove them on a MagicBlock devnet before you rely on them"
			/>
		</Table>
	</>;
}

export function Performance(): NeonNode {
	return <>
		<Title tone={tone.build} title="Performance" />
		<Lede t={"Five programs of Anchor's own benchmark, ported and measured against Anchor v2 and" +
			" Pinocchio."} />
		<Heading at="results" title="Results" />
		<P>
			Program size in bytes, then compute units for each instruction. Measured on
			2026-10-15 with <M t="msc" /> 0.3.3 (build f82403c8e) and <M t="--release" />,
			platform-tools v1.57, in LiteSVM 1.4.1. Another platform-tools version moves the
			numbers: the helloworld program is 3,392 bytes and 1,420 units with v1.54.
		</P>
		<Subheading at="helloworld" title="helloworld" />
		<Table>
			<Head a="BUILD" b="BYTES · INIT" />
			<Row a="Geass" b="3,464 · 1,409" />
			<Row a="Anchor v2" b="6,400 · 1,441" />
		</Table>
		<Subheading at="vault" title="vault" />
		<Table>
			<Head a="BUILD" b="BYTES · DEPOSIT, WITHDRAW" />
			<Row a="Geass" b="3,688 · 1,577, 404" />
			<Row a="Anchor v2" b="5,632 · 1,602, 418" />
			<Row a="Pinocchio" b="5,544 · 1,593, 404" />
			<Row a="Pinocchio, lazy" b="3,576 · 1,599, 415" />
		</Table>
		<Subheading at="nested" title="nested" />
		<Table>
			<Head a="BUILD" b="BYTES · INITIALIZE, INCREMENT, RESET" />
			<Row a="Geass" b="5,728 · 2,733, 149, 144" />
			<Row a="Anchor v2" b="12,256 · 2,840, 866, 861" />
		</Table>
		<Subheading at="prop-amm" title="prop-amm" />
		<Table>
			<Head a="BUILD" b="BYTES · UPDATE, INITIALIZE, ROTATE_AUTHORITY" />
			<Row a="Geass" b="4,544 · 77, 1,370, 101" />
			<Row a="Anchor v2" b="8,448 · 81, 1,398, 93" />
			<Row a="Pinocchio" b="6,672 · 91, 1,375, 95" />
			<Row a="Pinocchio, lazy" b="5,184 · 103, 1,385, 108" />
		</Table>
		<Subheading at="multisig" title="multisig" />
		<Table>
			<Head a="BUILD" b="BYTES · CREATE, DEPOSIT, SET_LABEL, EXECUTE_TRANSFER" />
			<Row a="Geass" b="11,760 · 2,447, 2,266, 444, 2,540" />
			<Row a="Anchor v2" b="30,496 · 2,762, 2,292, 621, 2,991" />
		</Table>
		<Heading at="reading" title="Reading the table" />
		<P>
			Geass is the smallest program in four of five, and in 12 of 13 instructions no
			build takes fewer units. The lazy Pinocchio vault is 112 bytes smaller, and{" "}
			<M t="rotate_authority" /> costs 8 units more than Anchor's and 6 more than
			Pinocchio's.
		</P>
		<Heading at="method" title="How it is measured" />
		<P>
			Every build receives the same keys, accounts and instruction bytes, and must
			leave the same account data. The Anchor programs are v2 2.0.0-rc.1 built for
			sBPF v3 with fat LTO, the Pinocchio programs 0.11.2 with the same checks in the
			same order.
		</P>
		<P>
			The Pinocchio programs are written for this comparison, not taken from
			Pinocchio or from Anchor's benchmark. The Anchor programs are Anchor's own at
			revision <M t="ff0514b" /> with three changes, so that every build does the same
			work: the 8-byte discriminators replace the 1-byte ones, the vault compares the
			program id itself, and prop-amm runs through the ordinary dispatcher instead of
			its assembly fast path, which skips checks the other builds make.
		</P>
		<Heading at="reproduce" title="Run it yourself" />
		<P>
			The programs and the harness are in the compiler's repository:{" "}
			<L
				to="https://github.com/metascriptlang/compiler/tree/main/examples/anchorBench"
				t="examples/anchorBench"
			/> holds the five Geass programs,{" "}
			<L
				to="https://github.com/metascriptlang/compiler/blob/main/tools/solana/anchorReference.mjs"
				t="tools/solana/anchorReference.mjs"
			/> builds the Anchor ones,{" "}
			<L
				to="https://github.com/metascriptlang/compiler/tree/main/tools/solana/pinocchio"
				t="tools/solana/pinocchio"
			/> holds the Pinocchio ones, and{" "}
			<L
				to="https://github.com/metascriptlang/compiler/blob/main/tools/solana/anchorBench.mjs"
				t="tools/solana/anchorBench.mjs"
			/> runs every build through the same transactions and prints this table.
		</P>
		<Heading at="signed-division" title="Signed division" />
		<P>
			sBPF has no signed divide instruction, so <M t="/" /> and <M t="%" /> on{" "}
			<M t="int32" /> and <M t="int64" /> become a library call.{" "}
			<M t="std/solana/arithmetic" /> divides the magnitudes as unsigned and restores
			the sign. One line of <M t="build.ms" /> applies it to every module:
		</P>
		<Sample code={DIVISION_CODE} />
		<P>
			An instruction that divides one <M t="int64" /> went from 274 to 137 units, and
			its program from 3,456 to 2,232 bytes.
		</P>
		<P>
			The import changes one result. The lowest <M t="int64" /> divided by -1 has no
			answer that fits: without the import the program stops, with it the division
			returns a negative number and the program goes on. Refuse a divisor of -1 where
			an instruction supplies it.
		</P>
	</>;
}
