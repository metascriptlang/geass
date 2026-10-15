import { NeonNode } from "../../../../neon/src/render/node";
import {
	Head, Heading, L, Lede, M, Note, P, Row, Sample, Table, Title, Warning, tone,
} from "../ui/prose";

const CLI_ERROR_CODE = "Program BoPYRB7dosWryTV6q7HgHj5SkgtQczT2aLbuixC2EgmD failed: custom program error: 0x7d6";
const KIT_ERROR_CODE = "SolanaError: Transaction simulation failed
  cause: SolanaError: Custom program error: #6000 (instruction #1)";
const USER_ERROR_CODE = "export enum CounterError {
  NotYourCounter,
  TooLarge,
}

export converter counterError(error: CounterError): ProgramError {
  return ProgramError.userError(error as uint32);
}";

export function ErrorCodes(): NeonNode {
	return <>
		<Title tone={tone.reference} title="Error codes" />
		<Lede t={"A refused instruction returns one number. This page says which check returned " +
			"it and what to fix."} />
		<Heading at="reading" title="Reading an error" />
		<P>
			When a check fails, the instruction stops, nothing it did is kept, and the
			program returns a code. Geass logs nothing else, so the code is the whole message.
			The Solana CLI and explorers print a custom code in hexadecimal:
		</P>
		<Sample code={CLI_ERROR_CODE} />
		<P>
			<M t="@solana/kit" /> prints the same kind of code in decimal:
		</P>
		<Sample code={KIT_ERROR_CODE} />
		<Table>
			<Head a="CODE" b="WHERE IT COMES FROM" />
			<Row a="100 to 102" b="The instruction data: no instruction, an unknown one, bad arguments" />
			<Row a="2000 to 2040" b="A field that must be writable, and the decorators" />
			<Row a="3001 to 3016" b="The type of an accounts field: signer, owner, layout" />
			<Row a="6000 and up" b="Your own error enum" />
			<Row a="A name" b="The runtime's own errors, such as missing required signature" />
		</Table>
		<P>
			The numbers below 6000 are Anchor's, so an error reads the same as in an Anchor
			program. In a test, <M t="run(...).result" /> is the same number, and{" "}
			<M t="ProgramError.constraintSeeds().code" /> spells it by name.
		</P>
		<Heading at="yours" title="Your errors" />
		<P>
			An enum and a converter. The first member is 6000 (0x1770), the next 6001, as
			with Anchor's <M t="#[error_code]" />, and the IDL lists them by name:
		</P>
		<Sample code={USER_ERROR_CODE} />
		<P>
			<M t="ProgramError.custom(n)" /> is the number <M t="n" /> with nothing added,
			for repeating another program's codes. Keep yours on <M t="userError" />, so they
			stay clear of the codes below 6000.
		</P>
		<Heading at="instruction" title="Instruction errors" />
		<Table>
			<Head a="CODE" b="MEANING" />
			<Row
				a="100 · 0x64"
				b="instructionMissing. The data is shorter than the 8-byte discriminator"
			/>
			<Row
				a="101 · 0x65"
				b="instructionFallbackNotFound. The discriminator names none of your instructions. Check the client spells the name as the enum does"
			/>
			<Row
				a="102 · 0x66"
				b="instructionDidNotDeserialize. args<T>() found the arguments too short, a boolean byte other than 0 or 1, or a Bytes length past the end"
			/>
		</Table>
		<Heading at="constraint" title="Constraint errors" />
		<Table>
			<Head a="CODE" b="MEANING" />
			<Row
				a="2000 · 0x7d0"
				b="constraintMut. A Writable, WritableSigner or Mutable field was sent read-only. Mark the account writable in the client"
			/>
			<Row
				a="2001 · 0x7d1"
				b="constraintHasOne. @hasOne: the key stored in the data is not the sibling account's key"
			/>
			<Row a="2003 · 0x7d3" b="constraintRaw. An @constraint condition was false" />
			<Row
				a="2006 · 0x7d6"
				b="constraintSeeds. The account is not at the address its seeds and bump derive. Derive it in the client from the same seeds and program id"
			/>
			<Row
				a="2009 · 0x7d9"
				b="constraintAssociated. @associated: not the associated token account of that mint and wallet"
			/>
			<Row a="2011 · 0x7db" b="constraintClose. close() was given the closed account as its destination" />
			<Row a="2012 · 0x7dc" b="constraintAddress. @address: the key is not the one required" />
			<Row a="2014 · 0x7de" b="constraintTokenMint. @tokenMint: the token account holds another mint" />
			<Row
				a="2015 · 0x7df"
				b="constraintTokenOwner. @tokenAuthority or @associated: the token account belongs to another wallet"
			/>
			<Row
				a="2023 · 0x7e7"
				b="constraintAssociatedTokenTokenProgram. The token program passed does not own the mint"
			/>
			<Row
				a="2040 · 0x7f8"
				b="constraintDuplicateMutableAccount. One account was passed for two fields, at least one of them writable"
			/>
		</Table>
		<Heading at="account" title="Account errors" />
		<Table>
			<Head a="CODE" b="MEANING" />
			<Row
				a="3001 · 0xbb9"
				b="accountDiscriminatorNotFound. The account holds fewer than 8 bytes: it was never created"
			/>
			<Row
				a="3002 · 0xbba"
				b="accountDiscriminatorMismatch. The account holds another type than the field names"
			/>
			<Row
				a="3003 · 0xbbb"
				b="accountDidNotDeserialize. The bytes do not fit the struct: too short, a boolean other than 0 or 1, an enum value that is not a member"
			/>
			<Row
				a="3005 · 0xbbd"
				b="accountNotEnoughKeys. The transaction sent fewer accounts than the accounts struct has fields"
			/>
			<Row
				a="3007 · 0xbbf"
				b="accountOwnedByWrongProgram. Owned or Mutable: the account is not your program's. External: not owned by a program the type accepts"
			/>
			<Row a="3008 · 0xbc0" b="invalidProgramId. A Program<P> field got another program" />
			<Row a="3009 · 0xbc1" b="invalidProgramExecutable. A Program<P> field got an account that is not a program" />
			<Row
				a="3010 · 0xbc2"
				b="accountNotSigner. A Signer or WritableSigner field did not sign. Add the wallet as a signer in the client"
			/>
			<Row a="3011 · 0xbc3" b="accountNotSystemOwned. A SystemAccount field is owned by another program" />
			<Row
				a="3014 · 0xbc6"
				b="accountNotAssociatedTokenAccount. Not the associated token account of that wallet and mint"
			/>
			<Row a="3016 · 0xbc8" b="accountReallocExceedsLimit. realloc grew an account by more than 10,240 bytes" />
			<Row
				a="4101 · 0x1005"
				b="tryingToInitPayerAsProgramAccount. create or createPda got the payer as the new account"
			/>
			<Row
				a="4200 · 0x1068"
				b="Geass only. A Token-2022 account carries an extension Geass does not know to be safe"
			/>
		</Table>
		<Heading at="runtime" title="Runtime errors" />
		<P>
			These are Solana's own and show by name, not by number. The ones Geass returns:
		</P>
		<Table>
			<Head a="NAME" b="MEANING" />
			<Row
				a="MissingRequiredSignature"
				b="A raw signerAccount(i), a token call or a MagicBlock call needed a signature it did not get"
			/>
			<Row a="NotEnoughAccountKeys" b="A raw account(i) asked past the accounts sent" />
			<Row
				a="AccountBorrowFailed"
				b="The same account was claimed writable twice in one instruction"
			/>
			<Row
				a="AccountDataTooSmall"
				b="A read or write past the end of the data, or create with room for less than the discriminator"
			/>
			<Row a="InvalidSeeds" b="The seeds lead to no valid address" />
			<Row a="MaxSeedLengthExceeded" b="More than 16 seeds, or a seed over 32 bytes" />
			<Row
				a="IncorrectProgramId"
				b="A token call got a program that is neither Token nor Token-2022"
			/>
			<Row
				a="InvalidAccountData, UninitializedAccount"
				b="A mint or token account that is malformed, or not initialized yet"
			/>
			<Row a="InvalidRealloc" b="An account grew past its room" />
			<Row a="ArithmeticOverflow" b="A sum of lamports overflowed in close or realloc" />
			<Row
				a="InvalidArgument"
				b="A helper got an argument it cannot use: a CPI over 64 accounts, a payer that is the target, a full heap"
			/>
		</Table>
		<P>
			A CPI that fails returns the called program's own code. A System transfer from an
			account short of lamports returns 1, and so does a token transfer short of
			tokens. The program you called defines what its numbers mean.
		</P>
		<Note>
			In the test simulator, two more values end a run: <M t="REFUSED" /> when the
			runtime itself would refuse the transaction, with the reason in{" "}
			<M t="fault" />, and <M t="NOT_SIMULATED" /> for a call the simulator does not
			model. <L to="/docs/testing#simulator" t="Testing" /> lists what it models.
		</Note>
	</>;
}

export function Troubleshooting(): NeonNode {
	return <>
		<Title tone={tone.reference} title="When you are stuck" />
		<Lede t={"The messages a first program meets, what they mean and what to change."} />
		<Heading at="compile" title="It does not compile" />
		<P>
			<M t="msc check" /> finds most of these in seconds. Read the first error: the ones
			after it often follow from it.
		</P>
		<Table>
			<Head a="YOU SEE" b="WHAT TO DO" />
			<Row
				a="Cannot find name 'seeds', Undefined variable 'accounts'"
				b="Add the name to the import from \"std/solana\". Decorators are imported like functions"
			/>
			<Row
				a="Unresolved type 'Mutable' - missing import?"
				b="The same. The errors after it come from the missing type"
			/>
			<Row
				a="@seeds on field 'counter' needs @bump"
				b="Add @bump(counter.bump) when the account stores its bump, or a bare @bump"
			/>
			<Row
				a="'account.name' is not a wire value"
				b="An account has a fixed size. A string becomes a uint8[32] with its length beside it, a growing list a fixed array with a count. The error points at createPda or accounts<T>(), not at the field"
			/>
			<Row
				a="Macro 'accounts' failed: attempt to access a nil address"
				b="The account type is a class. Write it as an export struct"
			/>
			<Row
				a="Optional field 'label?' in struct"
				b="An account has no optional fields. Keep label and a hasLabel: boolean beside it"
			/>
			<Row a="'any' is not a MetaScript type" b="Give the field a sized type" />
			<Row
				a="Type 'Result<number, ProgramError>' is not assignable"
				b="number is a float. On chain, use uint64, uint32 or uint8"
			/>
			<Row
				a="cannot write through Readonly<Ptr<Counter>>"
				b="The field is Owned<Counter>, which is read-only. Declare it Mutable<Counter> to change the account"
			/>
			<Row
				a="does not hash its own name: write accountDiscriminator(\"Counter\")"
				b="The discriminator names another type. Write the struct's exact name"
			/>
			<Row
				a="seed 2 has type int32: a seed is a string, a byte array, a Pubkey or an account"
				b="Turn the number into bytes: [x] for a uint8, leBytes(x) for a wider integer"
			/>
			<Row
				a="the build declares programId ..., but the deploy keypair ... is program ..."
				b="Copy the address that solana address -k prints into programId. The error points into the program; the fix is in build.ms"
			/>
			<Row
				a="the build declares no programId"
				b="Add defines: { programId: \"...\" } to build.ms. Check and build pass without it; tests need it"
			/>
		</Table>
		<P>Some pass <M t="msc check" /> and stop only in the Solana build:</P>
		<Table>
			<Head a="YOU SEE" b="WHAT TO DO" />
			<Row
				a="a module-level 'let' needs writable static storage"
				b="A program keeps no variables between calls. Keep the value in an account; module level takes const only"
			/>
			<Row
				a="Function MsMain overflows the maximum allowed frame space"
				b="Some function's locals take more than 4 KB. MsMain is not your function's name: look for a large local array and move it into account data"
			/>
			<Row
				a="--os=solana requires a clang with the sbf target registered"
				b="Install Anza's platform tools, as Getting started shows"
			/>
		</Table>
		<Heading at="test" title="A test fails" />
		<Table>
			<Head a="YOU SEE" b="WHAT TO DO" />
			<Row
				a="AssertionError: run ( ... ) . result == 0"
				b="The message does not show the value. Print it with console.log, then look the number up in Error codes: 3010 is a missing signature, 2006 a wrong address, 3005 too few accounts"
			/>
			<Row
				a="void function '__ms_test_0' should not return a value"
				b="try does not work inside a test block yet. Write const r = f(); and assert r.ok"
			/>
			<Row
				a="'assert' can only be used inside test blocks"
				b="Let the helper return a boolean or the value, and assert in the test"
			/>
			<Row
				a="The account did not change after run"
				b="A struct is a value, so a copy did not change either. Read the account from the array you passed to run"
			/>
			<Row
				a="Test Files  30 passed, Tests  400 passed"
				b="Those are the standard library's tests too. Add --tests-in-dir to run only yours"
			/>
		</Table>
		<Note>
			<M t="msc check" /> does not look inside <M t="when (testBuild)" />, so a mistake in
			a test shows up only in <M t="msc test" />.
		</Note>
		<Heading at="chain" title="It fails on chain" />
		<Table>
			<Head a="YOU SEE" b="WHAT TO DO" />
			<Row
				a="Every instruction succeeds, nothing changes, a few dozen units"
				b="The file lost its top-level entry() call, and msc 0.3.3 builds such a file. End it with when (!testBuild) { entry(); }"
			/>
			<Row
				a="A refused instruction reports success"
				b="The top level calls dispatch(), whose error nobody reports. Call entry(), which hands the error to the runtime"
			/>
			<Row
				a="custom program error: 0x7d6"
				b="A code in hexadecimal: 0x7d6 is 2006. Look it up in Error codes"
			/>
			<Row a="Custom program error: #6000" b="The first member of your error enum" />
			<Row
				a="2006 for an address that the client derived"
				b="Seeds and program id must match the program's. Literal seeds are computed at build time from the id in build.ms, so rebuild for each id you deploy to"
			/>
			<Row
				a="The airdrop is refused"
				b="Devnet limits airdrops. faucet.solana.com hands out devnet SOL too"
			/>
		</Table>
		<Warning>
			A green test does not prove a deploy. The simulator accepts a CPI whose program is
			missing from the instruction's accounts; run the built program in LiteSVM, as{" "}
			<L to="/docs/testing#litesvm" t="Testing" /> shows, before you deploy.
		</Warning>
		<P>
			Something else? Ask in the{" "}
			<L to="https://discord.gg/gCwkmqS3xB" t="MetaScript Discord" />, with the command
			and its whole output.
		</P>
	</>;
}
