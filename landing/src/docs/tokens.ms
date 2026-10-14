import { NeonNode } from "../../../../neon/src/render/node";
import {
	Head, Heading, Lede, M, P, Row, Sample, Subheading, Table, Title, tone,
} from "../ui/prose";

const IMPORT_CODE = "import {
  InterfaceMint,
  InterfaceTokenAccount,
  Mint,
  TokenAccount,
  closeTokenAccount,
  createAssociatedFor,
  expectAssociated,
  transferTokens,
} from \"std/solana/token\";";
const REFUND_CODE = "export struct RefundAccounts {
  maker: WritableSigner;
  mintA: External<Mint>;
  @associated(mintA, maker) makerAtaA: ExternalMutable<TokenAccount>;
  @seeds(\"escrow\", maker, leBytes(escrow.seed)) @bump(escrow.bump) @hasOne(maker) @hasOne(mintA)
  escrow: Mutable<Escrow>;
  @associated(mintA, escrow) vault: ExternalMutable<TokenAccount>;
  tokenProgram: Account;
  systemProgram: Program<System>;
}";
const READ_CODE = "const held = (try x.vault.read()).amount;";
const EXPECT_CODE = "const _tokenProgram = try expectAddress(x.tokenProgram.key(), x.mint.owner());
const destination = try x.destination.read();
const _destinationMint = try expectTokenMint(destination, escrow.mintA);
const _destinationOwner = try expectTokenOwner(destination, x.owner.key());";
const MINT_PDA_CODE = "const mint = x.mint.asAccount();
const mintBump = try createMintPda(
  x.authority, x.mint, [\"mint\"], TOKEN_PROGRAM_ID, 6, mint.key(), null,
);";
const ASSOCIATED_CODE = "const escrowAccount = made.asMutable().asAccount();
const _vaultMade = try createAssociatedFor(
  x.maker,
  x.vault,
  escrowAccount,
  x.mintA,
  x.systemProgram,
  x.tokenProgram,
);
const _vaultKey = try expectAssociated(
  x.vault.key(),
  escrowAccount.key(),
  x.mintA,
);
const vault = try externalMutable<TokenAccount>(5);";
const MINT_TO_CODE = "const _minted = try signed(
  mintTokens(x.mint, x.destination, x.mint.asAccount(), amount),
  [\"mint\", [config.mintBump]],
);";
const TRANSFER_CODE = "const _paid = try transferTokens(
  x.takerAtaB,
  x.makerAtaB,
  x.mintB,
  x.taker.asAccount(),
  receive,
);
const held = (try x.vault.read()).amount;
const _released = try signed(
  transferTokens(x.vault, x.takerAtaA, x.mintA, escrowAccount, held),
  [\"escrow\", escrow.maker, leBytes(escrow.seed), [escrow.bump]],
);";
const CLOSE_CODE = "const _vaultClosed = try signed(
  closeTokenAccount(x.vault, x.maker.asWritable(), escrowAccount),
  [\"escrow\", escrow.maker, leBytes(escrow.seed), [escrow.bump]],
);";
const PIN_CODE = "@constraint(mint.owner() == TOKEN_2022_PROGRAM_ID)
mint: External<InterfaceMint>;";
const MEMBER_CODE = "import { groupMemberPointer, tokenGroupMember } from \"std/solana/token\";

const mintAccount = x.mint.asAccount();
const pointer = mintAccount.groupMemberPointer();
const member = mintAccount.tokenGroupMember();
if (!pointer.ok || !member.ok) { return Result.err(ProgramError.invalidAccountData()); }";

export function Tokens(): NeonNode {
	return <>
		<Title tone={tone.core} title="Tokens" />
		<Lede t={"A mint and a token account are fields of the accounts struct. A token instruction " +
			"is a function call."} />
		<Heading at="module" title="One module, two token programs" />
		<P>
			<M t="std/solana/token" /> replaces the <M t="anchor_spl" /> crates. The program
			markers, the decorators and the ids <M t="TOKEN_PROGRAM_ID" />,{" "}
			<M t="TOKEN_2022_PROGRAM_ID" /> and <M t="ASSOCIATED_TOKEN_PROGRAM_ID" /> come
			from <M t="std/solana" />.
		</P>
		<Sample code={IMPORT_CODE} />
		<P>
			A transfer, a mint or a burn takes no token program: it sends to the program
			that owns the mint. A close sends to the program that owns the token account.
			Each refuses an owner that is neither Token nor Token-2022. With the interface
			types below, one handler serves both programs. <M t="createMintPda" /> and{" "}
			<M t="createAssociatedFor" /> take the token program as an argument;{" "}
			<M t="createTokenAccount" /> uses the mint's.
		</P>
		<Heading at="fields" title="Mints and token accounts" />
		<Sample code={REFUND_CODE} />
		<Table>
			<Head a="FIELD TYPE" b="WHAT IT PROVES" />
			<Row a="External<Mint>" b="Owned by Token, exactly 82 bytes, an initialized mint" />
			<Row
				a="External<TokenAccount>"
				b="Owned by Token, exactly 165 bytes, an initialized or frozen token account"
			/>
			<Row
				a="External<InterfaceMint>"
				b={"Owned by Token or Token-2022, an initialized mint, " +
					"no extension that changes a transfer"}
			/>
			<Row
				a="External<InterfaceTokenAccount>"
				b={"Owned by either program, initialized or frozen, " +
					"no extension that holds back an amount"}
			/>
			<Row a="ExternalMutable<…>" b="The same, and writable" />
			<Row a="Program<Token>" b="The key is that program, and it is executable" />
			<Row
				a="tokenProgram: Account"
				b="Nothing. A CPI needs its program among the accounts"
			/>
		</Table>
		<P>
			<M t="Mint" /> and <M t="TokenAccount" /> are Anchor's <M t="Account<Mint>" /> and{" "}
			<M t="Account<TokenAccount>" />; the interface types are its{" "}
			<M t="InterfaceAccount" />. A wrong owner fails with 3007, bytes that are not that
			layout with 3003, and an extension an interface type does not accept with 4200.
		</P>
		<Subheading at="reading" title="Reading the fields" />
		<P>
			Token layouts are packed, so <M t="read()" /> returns a decoded copy with public
			fields, where your own accounts give a pointer:
		</P>
		<Sample code={READ_CODE} />
		<P>
			A token account has two owners. <M t="x.vault.owner()" /> is the token program;
			the <M t="owner" /> field of what <M t="read()" /> returns is the wallet that holds
			the tokens.
		</P>
		<Heading at="checks" title="Checking a token account" />
		<Table>
			<Head a="DECORATOR" b="FAILS WITH" />
			<Row a="@tokenMint(mint)" b="2014 when the account is of another mint" />
			<Row a="@tokenAuthority(key)" b="2015 when another wallet holds it" />
			<Row
				a="@associated(mint, wallet)"
				b="2015 for the wallet, then 2009 when the address is not the associated one"
			/>
		</Table>
		<P>
			<M t="@associated" /> derives the address under the mint's own token program.
		</P>
		<Subheading at="calls" title="The checks as calls" />
		<P>
			The same checks exist as calls, for a handler that learns the key late:
		</P>
		<Sample code={EXPECT_CODE} />
		<P>
			<M t="expectAssociated" /> answers 3014 where the decorator answers 2009. There is no
			decorator for <M t="mint::decimals" />, <M t="mint::authority" /> or{" "}
			<M t="token::token_program" />; read the mint and compare.
		</P>
		<Heading at="create-mint" title="Creating a mint" />
		<P>
			<M t="createMintPda" /> creates the account at the PDA of the seeds, initializes the
			mint and returns the bump:
		</P>
		<Sample code={MINT_PDA_CODE} />
		<P>
			The last two arguments are the mint authority and the freeze authority. Here the
			mint is its own authority, so only the program can mint.
		</P>
		<Heading at="create-account" title="Creating a token account" />
		<P>
			<M t="createAssociatedFor" /> creates the associated token account of a wallet. The
			new account arrives as a <M t="Writable" />, so prove it once it exists.{" "}
			<M t="externalMutable<TokenAccount>(5)" /> is that proof by position: 5 is the
			index of the vault among the instruction's accounts.
		</P>
		<Sample code={ASSOCIATED_CODE} />
		<P>
			Pass the associated token program among the instruction's accounts for this
			call; an <M t="Account" /> field is enough.{" "}
			<M t="createAssociatedTokenIdempotent" /> is <M t="init_if_needed" /> for an
			associated account. It takes the same six accounts as plain{" "}
			<M t="Account" /> values, each passed with <M t="asAccount()" />.
		</P>
		<Heading at="mint-to" title="Minting" />
		<Sample code={MINT_TO_CODE} />
		<Heading at="transfer" title="Transferring" />
		<P>
			<M t="transferTokens" /> reads the decimals from the mint and sends{" "}
			<M t="TransferChecked" />. The authority is a signer of the transaction, or a PDA
			under <M t="signed" />:
		</P>
		<Sample code={TRANSFER_CODE} />
		<Heading at="close" title="Closing a token account" />
		<P>
			The rent goes to a <M t="Writable" />; the maker of <M t="RefundAccounts" /> is
			a <M t="WritableSigner" />, so it passes with <M t="asWritable()" />:
		</P>
		<Sample code={CLOSE_CODE} />
		<Heading at="token-2022" title="Token-2022 and extensions" />
		<P>
			An <M t="External<InterfaceMint>" /> accepts a mint of either program. To accept
			one, constrain the owner of the mint:
		</P>
		<Sample code={PIN_CODE} />
		<P>
			An interface type accepts only the extensions that leave a transfer and a balance
			as they read: metadata, groups, the close authority, interest-bearing and scaled
			UI amounts on a mint; immutable owner, memo transfer and the CPI guard on a token
			account. A transfer fee, a transfer hook, a permanent delegate, a pause switch, a
			default state, non-transferable or confidential transfers fail with 4200 before
			the handler runs.
		</P>
		<P>
			<M t="mintExtension(kind)" /> and <M t="tokenAccountExtension(kind)" /> are
			methods of an <M t="Account" />. They take a member of{" "}
			<M t="ExtensionType" /> from <M t="std/solana/token" /> and return the bytes of
			that extension, or an error when the account does not carry it. Two are decoded
			for you, the group member pointer and the group member, here for a field{" "}
			<M t="mint: External<InterfaceMint>" />:
		</P>
		<Sample code={MEMBER_CODE} />
		<Heading at="from-anchor" title="Anchor to Geass" />
		<Table>
			<Head a="ANCHOR" b="GEASS" />
			<Row
				a="Account<Mint>, Account<TokenAccount>"
				b="External<Mint>, External<TokenAccount>"
			/>
			<Row
				a="InterfaceAccount<Mint>, InterfaceAccount<TokenAccount>"
				b="External<InterfaceMint>, External<InterfaceTokenAccount>"
			/>
			<Row a="#[account(mut)] on a token account" b="ExternalMutable<TokenAccount>" />
			<Row a="mint.supply, token.amount" b="read().supply, read().amount" />
			<Row a="token::mint = mint" b="@tokenMint(mint)" />
			<Row a="token::authority = wallet" b="@tokenAuthority(wallet)" />
			<Row a="associated_token::mint, ::authority" b="@associated(mint, wallet)" />
			<Row a="init with mint::decimals and seeds" b="createMintPda(…)" />
			<Row a="init with associated_token::…" b="createAssociatedFor(…)" />
			<Row
				a="token::transfer_checked(cpi, n, decimals)"
				b="transferTokens(from, to, mint, authority, n)"
			/>
			<Row a="token::mint_to(cpi, n)" b="mintTokens(mint, to, authority, n)" />
			<Row a=".with_signer(seeds)" b="signed(call, seeds)" />
			<Row a="get_extension::<T>()" b="mintExtension(kind)" />
		</Table>
		<Heading at="not-yet" title="Not there yet" />
		<P>
			<M t="burnTokens" />, <M t="approveDelegate" />, <M t="revokeDelegate" />,{" "}
			<M t="setAuthorityOf" /> and <M t="createTokenAccount" /> exist; there is no call
			for freeze, thaw or wrapped SOL, and those go through <M t="invoke" />. The
			transfer is always the checked one. <M t="transferTokens" /> sends exactly four
			accounts, so the extra accounts of a transfer hook cannot be passed.
		</P>
		<P>
			A mint with a transfer fee or a transfer hook is refused by the interface types,
			not handled: accepting one is a change to the std, not a handler option. There
			is no fixture that builds a mint or a token account for a test; a test writes
			those bytes itself.
		</P>
	</>;
}
