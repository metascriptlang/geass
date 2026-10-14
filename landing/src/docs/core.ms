import { NeonNode } from "../../../../neon/src/render/node";
import {
	Head, Heading, L, Lede, M, P, Row, Sample, Subheading, Table, Title, tone,
} from "../ui/prose";

const ID_CODE = "const config = {
  defines: { programId: \"Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS\" },
};
export default config;";
const DISPATCH_CODE = "export enum VaultOp {
  Deposit,
  Withdraw,
}

export function dispatch(): Result<uint64, ProgramError> {
  return match (try instruction<VaultOp>()) {
    VaultOp.Deposit => deposit(),
    VaultOp.Withdraw => withdraw(),
  };
}";
const HANDLER_CODE = "export struct AmountArgs {
  amount: uint64;
}

function deposit(): Result<uint64, ProgramError> {
  const given = try args<AmountArgs>();
  const x = try accounts<DepositAccounts>();
  return transfer(x.user.asAccount(), x.vault.asAccount(), given.amount);
}";
const ENTRY_CODE = "export function entry(): void {
  const result = dispatch();
  if (!result.ok) { failWith(result.error); }
}

when (!testBuild) {
  entry();
}";
const IMPORT_CODE = "import {
  Program, ProgramError, System, Writable, WritableSigner,
  accounts, args, bump, failWith, instruction, seeds, transfer,
} from \"std/solana\";";
const ACCOUNTS_CODE = "export struct SessionAccounts {
  signer: Signer;
  pet: Mutable<PetAccount>;
  world: Owned<World>;
  session: Account;
}

function tick(): Result<uint64, ProgramError> {
  const x = try accounts<SessionAccounts>();
  const world = x.world.data();
  const record = x.pet.data();
  return Result.ok(0);
}";
const TAKE_CODE = "export struct TakeAccounts {
  taker: WritableSigner;
  maker: Writable;
  mintA: External<Mint>;
  mintB: External<Mint>;
  @associated(mintA, taker) takerAtaA: ExternalMutable<TokenAccount>;
  @associated(mintB, taker) takerAtaB: ExternalMutable<TokenAccount>;
  @associated(mintB, maker) makerAtaB: ExternalMutable<TokenAccount>;
  @seeds(\"escrow\", maker, leBytes(escrow.seed)) @bump(escrow.bump)
  @hasOne(maker) @hasOne(mintA) @hasOne(mintB)
  escrow: Mutable<Escrow>;
  @associated(mintA, escrow) vault: ExternalMutable<TokenAccount>;
  tokenProgram: Account;
  systemProgram: Program<System>;
}";
const ERROR_ARG_CODE = "@hasOne(authority, ProgramError.userError(0)) oracle: Mutable<Oracle>;";
const ERROR_ENUM_CODE = "@hasOne(authority, OracleError.NotTheAuthority) oracle: Mutable<Oracle>;";
const TEST_DERIVE_CODE = "const vault = findProgramAddressOf(declaredProgramId(), [\"vault\", alice]);";
const DEBIT_CODE = "const vault = x.vault.asAccount();
const user = x.user.asAccount();
vault.setLamports(vault.lamports() - given.amount);
user.setLamports(user.lamports() + given.amount);";
const VAULT_CODE = "export struct DepositAccounts {
  user: WritableSigner;
  @seeds(\"vault\", user) @bump vault: Writable;
  systemProgram: Program<System>;
}";
const DERIVE_CODE = "const revenue = try findProgramAddress([\"revenue\"]);
if (x.revenue.key() != revenue.key) { return Result.err(ProgramError.constraintSeeds()); }

const _seeds = try pdaWithBump(x.pet, [\"pet\", record.mint], record.bump);";
const CREATE_CODE = "const made = try createPda<Escrow>(
  x.maker,
  x.escrow,
  [\"escrow\", x.maker, leBytes(a.seed)],
);
const escrow = made.asMutable().data();
escrow.bump = made.foundBump();";
const STORED_CODE = "@seeds(\"escrow\", maker, leBytes(escrow.seed)) @bump(escrow.bump)
escrow: Mutable<Escrow>;";
const TRANSFER_CODE = "return transfer(x.user.asAccount(), x.vault.asAccount(), given.amount);";
const SIGNED_CODE = "const _released = try signed(
  transferTokens(x.vault, x.takerAtaA, x.mintA, escrowAccount, held),
  [\"escrow\", escrow.maker, leBytes(escrow.seed), [escrow.bump]],
);";
const TOKEN_CODE = "import { Mint, TokenAccount, closeTokenAccount, transferTokens } from \"std/solana/token\";

const _paid = try transferTokens(x.takerAtaB, x.makerAtaB, x.mintB, x.taker.asAccount(), receive);
const held = (try x.vault.read()).amount;";
const PET_SEED = "\"pet\"";
const INVOKE_CODE = "let storage: uint8[12] = [];
const length = storage.putU64(storage.putU32(0, 2), lamports);
const sent = invoke(
  SYSTEM_PROGRAM_ID,
  [InstructionAccount.writableSigner(source), InstructionAccount.writable(destination)],
  storage,
  length,
);";

export function ProgramStructure(): NeonNode {
	return <>
		<Title tone={tone.core} title="Program structure" />
		<Lede t={"A program is an id, an enum of instructions, one handler per instruction and an " +
			"entry. All of it is ordinary code you can read top to bottom."} />
		<Heading at="program-id" title="The program id" />
		<P>
			Declare the id in <M t="build.ms" />. <M t="-d:programId=<base58>" /> on the command
			line overrides it, and nothing has to import it:
		</P>
		<Sample code={ID_CODE} />
		<P>
			The samples on these pages are parts of programs. Every name in them comes from{" "}
			<M t="std/solana" /> unless the sample imports it from somewhere else, and you
			import each one you use, decorators included. The vault this page builds starts
			with:
		</P>
		<Sample code={IMPORT_CODE} />
		<P>
			The whole vault, with a scenario that runs it, is the Vault example in the{" "}
			<L to="/playground" t="Playground" />.
		</P>
		<P>
			With an id declared, a PDA whose seeds are all literals is derived at compile time,
			and the IDL carries the id as its address. Name the deploy keypair with{" "}
			<M t="programKeypair" /> and the build stops on an id that does not match it.{" "}
			<M t="anchor keys sync" /> rewrites the id; here you edit it.
		</P>
		<Heading at="instructions" title="Instructions and dispatch" />
		<P>
			Each member of the enum is an instruction. Its discriminator is Anchor's, the first
			8 bytes of the SHA-256 of <M t="global:" /> and the snake_case name, computed at compile time.
			Data too short to hold one is error 100, an unknown one 101:
		</P>
		<Sample code={DISPATCH_CODE} />
		<Heading at="handlers" title="Handlers" />
		<P>
			A handler returns <M t="Result<uint64, ProgramError>" />. It reads its arguments
			with{" "}
			<M t="args<T>()" />, a struct decoded in Borsh order, and its accounts with{" "}
			<M t="accounts<T>()" />. An argument is a sized integer, a <M t="boolean" />, a{" "}
			<M t="Pubkey" />, a fixed array of those, or one last <M t="Bytes" /> field.{" "}
			<M t="try" /> returns the error to the caller when either fails:
		</P>
		<Sample code={HANDLER_CODE} />
		<Heading at="entry" title="The entry" />
		<P>
			<M t="entry" /> runs the dispatch and hands a failure to the runtime. The call at
			the top level of the file is the program's entrypoint: the chain runs the top
			level, and nothing else calls <M t="entry" />. It sits under{" "}
			<M t="when (!testBuild)" /> so a test build does not run it and the same file can
			carry its own tests:
		</P>
		<Sample code={ENTRY_CODE} />
		<P>
			A file without that call still builds and passes tests that hand{" "}
			<M t="entry" /> to the simulator. On chain it does nothing and reports success
			for every instruction, so check that the block is there before you deploy.
		</P>
	</>;
}

export function Accounts(): NeonNode {
	return <>
		<Title tone={tone.core} title="Accounts" />
		<Lede t={"An instruction lists its accounts in a struct. The type of each field is the check" +
			" the account must pass before the handler sees it."} />
		<Heading at="context" title="The accounts struct" />
		<P>
			<M t="accounts<T>()" /> verifies the fields in declaration order, which is also the
			order a client lists them. Fewer accounts than fields is error 3005 before any
			field is checked:
		</P>
		<Sample code={ACCOUNTS_CODE} />
		<Heading at="proof-types" title="Proof types" />
		<P>
			Each type is a proof: a value only the toolkit builds, after the checks pass. The
			codes are Anchor's.
		</P>
		<Subheading at="signers" title="Signers and plain accounts" />
		<Table>
			<Head a="TYPE" b="ANCHOR, AND WHAT IT CHECKS" />
			<Row a="Signer" b="Signer. Signed the transaction (3010)" />
			<Row a="WritableSigner" b="#[account(mut)] Signer. Signed (3010) and writable (2000)" />
			<Row a="Writable" b="#[account(mut)] UncheckedAccount. Writable (2000)" />
			<Row
				a="WritablePda"
				b="The same, with seeds and a bare bump. Writable (2000), and foundBump() answers the bump"
			/>
			<Row a="SystemAccount" b="SystemAccount. Owned by the System program (3011)" />
			<Row a="Account" b="UncheckedAccount. Present, nothing else" />
			<Row
				a="Program<P>"
				b="Program<P>. The key is P's id (3008) and it is executable (3009)"
			/>
		</Table>
		<Subheading at="program-accounts" title="Accounts your program owns" />
		<Table>
			<Head a="TYPE" b="ANCHOR, AND WHAT IT CHECKS" />
			<Row
				a="Owned<T>"
				b="A read-only Account<T>. Owner is this program (3007), discriminator (3001, 3002), size and valid field values (3003)"
			/>
			<Row
				a="Mutable<T>"
				b="#[account(mut)] Account<T>. The same, plus writable (2000) and an exclusive claim"
			/>
			<Row
				a="Delegated<T>"
				b="An account delegated to a MagicBlock ephemeral rollup. Owner is the delegation program (3007), then as Owned<T>; the field needs @seeds and @bump, or @address"
			/>
		</Table>
		<Subheading at="external-accounts" title="Accounts of other programs" />
		<Table>
			<Head a="TYPE" b="ANCHOR, AND WHAT IT CHECKS" />
			<Row
				a="External<T>"
				b="InterfaceAccount<T>. The owner is one T accepts (3007) and the data has T's layout (3003)"
			/>
			<Row
				a="ExternalMutable<T>"
				b="#[account(mut)] InterfaceAccount<T>. The same, plus writable and exclusive"
			/>
		</Table>
		<Heading at="reading-data" title="Reading the data" />
		<P>
			<M t="Owned<T>.data()" /> is a read-only pointer into the account, and{" "}
			<M t="Mutable<T>.data()" /> a writable one: zero-copy, at offset 8, with nothing to
			save on exit. A boolean byte other than 0 or 1, or an enum value that is not a
			member, is refused with 3003 before you get the pointer.{" "}
			<M t="External<T>.read()" /> decodes another program's layout, such as a token
			account.
		</P>
		<Heading at="duplicates" title="Duplicate accounts" />
		<P>
			The same account passed for two writable fields is refused with
			ConstraintDuplicateMutableAccount (2040), as in Anchor v2. A repeat between
			read-only fields stays allowed.
		</P>
		<Heading at="weakening" title="Weakening a proof" />
		<P>
			<M t="asSigner()" /> and <M t="asWritable()" /> turn a stronger proof into the weaker
			one a function asks for, and <M t="asAccount()" /> gives the plain account a CPI
			takes. Nothing converts the other way.
		</P>
	</>;
}

export function Validation(): NeonNode {
	return <>
		<Title tone={tone.core} title="Account validation" />
		<Lede t={"A check that needs more than the field's type is a decorator on the field, written" +
			" where Anchor writes #[account(...)]."} />
		<Heading at="decorators" title="Decorators" />
		<P>
			A decorator is a macro of <M t="std/solana" />. Import each one you use by name,
			as you import <M t="accounts" />. In this sample <M t="Mint" /> and{" "}
			<M t="TokenAccount" /> come from <M t="std/solana/token" />, and{" "}
			<M t="Escrow" /> is the program's own account type:
		</P>
		<Sample code={TAKE_CODE} />
		<Table>
			<Head a="DECORATOR" b="ANCHOR, AND THE CODE A FAILURE RETURNS" />
			<Row
				a="@seeds(a, b, ...) @bump"
				b="seeds = [..], bump. The key is the PDA of the seeds (2006)"
			/>
			<Row
				a="@seeds(...) @bump(x.bump)"
				b="bump = x.bump. The key is the PDA at the stored bump (2006)"
			/>
			<Row
				a="@hasOne(name, error?)"
				b="has_one. The data field name equals the key of the sibling account name (2001)"
			/>
			<Row a="@address(key, error?)" b="address = key. The field's key equals key (2012)" />
			<Row
				a="@constraint(condition, error?)"
				b="constraint = condition. The condition holds (2003)"
			/>
			<Row
				a="@associated(mint, authority)"
				b="associated_token. Owned by the authority (2015), at the associated address (2009)"
			/>
			<Row
				a="@tokenAuthority(key)"
				b="token::authority. The token account's owner is key (2015)"
			/>
			<Row a="@tokenMint(key)" b="token::mint. The token account's mint is key (2014)" />
		</Table>
		<Heading at="names" title="Names inside a decorator" />
		<P>
			A name that is a field of the struct is that account. <M t="escrow.seed" /> is a
			member of its data when the field is an <M t="Owned" /> or a <M t="Mutable" />.
			Any other name is resolved where <M t="accounts<T>()" /> is written, so a local of
			the handler names an instruction argument: <M t="leBytes(a.seed)" /> after{" "}
			<M t="const a = try args<T>()" />.
		</P>
		<Heading at="custom-errors" title="Your own error" />
		<P>
			<M t="@hasOne" />, <M t="@address" /> and <M t="@constraint" /> take an error as
			their last argument. It is evaluated only when the check fails:
		</P>
		<Sample code={ERROR_ARG_CODE} />
		<P>
			The argument is a <M t="ProgramError" />, or a member of your own error enum,
			which the enum's converter turns into one:
		</P>
		<Sample code={ERROR_ENUM_CODE} />
		<Heading at="order" title="Order of checks" />
		<P>
			Every field is verified by its type first. Then each field's decorators run in
			declaration order and, inside one field, in Anchor's order whatever order you wrote
			them in. The first failure is the answer.
		</P>
		<Heading at="refused" title="Refused at compile time" />
		<P>
			<M t="@seeds" /> without <M t="@bump" />, a <M t="@hasOne" /> that names something
			that is not a field, a token decorator on a field that is not a token account: each
			is a compile error that names the struct and the field.
		</P>
	</>;
}

export function Pdas(): NeonNode {
	return <>
		<Title tone={tone.core} title="PDAs" />
		<Lede t={"Seeds are a list written where they are used. The same list checks an address, " +
			"creates the account and signs for it."} />
		<Heading at="constraint" title="Checking a PDA" />
		<P>
			<M t="@seeds" /> with a bare <M t="@bump" /> finds the canonical address and compares
			it with the account's key:
		</P>
		<Sample code={VAULT_CODE} />
		<Heading at="seeds" title="What a seed can be" />
		<Table>
			<Head a="SEED" b="BYTES" />
			<Row a={PET_SEED} b="The string's bytes" />
			<Row a="[bump], a uint8[N]" b="The bytes in place" />
			<Row a="mint, x.maker.key()" b="A Pubkey's 32 bytes" />
			<Row a="x.maker" b="An account's key" />
			<Row a="leBytes(a.seed)" b="An integer, little-endian, as to_le_bytes() in Rust" />
		</Table>
		<P>
			A bare integer or a boolean is a compile error that names the seed's position and
			type. The runtime takes 16 seeds of 32 bytes; a search for the bump takes 15,
			because the bump is the sixteenth.
		</P>
		<Heading at="deriving" title="Deriving in a handler" />
		<P>
			For an address decided at run time, <M t="findProgramAddress" /> returns the key and
			the bump. <M t="pda" /> and <M t="pdaWithBump" /> check a <M t="Mutable<T>" /> or a{" "}
			<M t="Delegated<T>" /> against a list; for any other account, compare the key:
		</P>
		<Sample code={DERIVE_CODE} />
		<P>
			<M t="findProgramAddress" /> answers for the program that is running. In a test,
			outside an instruction, there is none yet and the address it returns is not
			yours. Derive there with the program named:
		</P>
		<Sample code={TEST_DERIVE_CODE} />
		<Heading at="creating" title="Creating an account at a PDA" />
		<P>
			<M t="createPda<T>" /> is Anchor's <M t="init" /> with seeds. It finds the bump,
			signs with the seeds, creates the account and writes the discriminator:
		</P>
		<Sample code={CREATE_CODE} />
		<Heading at="stored-bump" title="Storing the bump" />
		<P>
			Store the bump in the account and name it later. The check then hashes once instead
			of searching:
		</P>
		<Sample code={STORED_CODE} />
		<Heading at="folded" title="Literal seeds cost nothing" />
		<P>
			When every seed is a literal and the program id is declared, the address and its
			bump are computed by the compiler. The check on chain is one key compare: 9
			compute units in a measured program, against 348 for a seed that is an account.
		</P>
		<P>
			The address is then a constant of the build. The same file deployed under
			another id refuses every such account with 2006, so rebuild with{" "}
			<M t="-d:programId=" /> for each id you deploy to.
		</P>
	</>;
}

export function Cpi(): NeonNode {
	return <>
		<Title tone={tone.core} title="Cross-program calls" />
		<Lede t={"A CPI is a function call. Signing with a PDA wraps that call with the seeds."} />
		<Heading at="transfer" title="Moving lamports" />
		<P>
			<M t="transfer" /> calls the System program:
		</P>
		<Sample code={TRANSFER_CODE} />
		<P>
			The System program moves lamports only out of an account it owns that holds no
			data, and only when that account signed: a wallet, or an empty PDA signed for
			with <M t="signed" />. An account your program owns pays out without a CPI. The
			program moves the lamports itself:
		</P>
		<Sample code={DEBIT_CODE} />
		<Heading at="signing" title="Signing with a PDA" />
		<P>
			<M t="signed(call, seeds)" /> takes the unsigned call as you would write it and the
			seed list, bump included. It replaces{" "}
			<M t="CpiContext::new(..).with_signer(seeds)" />. A list of lists signs for several PDAs:
		</P>
		<Sample code={SIGNED_CODE} />
		<Heading at="tokens" title="Token calls" />
		<P>
			<M t="std/solana/token" /> has the mint and token-account layouts and the typed
			calls: <M t="transferTokens" />, <M t="closeTokenAccount" />,{" "}
			<M t="createAssociatedFor" />.
		</P>
		<Sample code={TOKEN_CODE} />
		<P>
			The program you call must be among the instruction's accounts, as for any CPI
			on Solana: the token program for a transfer, the associated token program too
			when you create an associated account.
		</P>
		<Heading at="raw-invoke" title="Any other program" />
		<P>
			<M t="invoke" /> takes the program, the account list and the instruction bytes. The
			arrays are sized from the list you write and live on the stack, so a CPI takes
			nothing from the heap:
		</P>
		<Sample code={INVOKE_CODE} />
	</>;
}
