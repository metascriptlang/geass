import { NeonNode } from "../../../../neon/src/render/node";
import {
	Head, Heading, Lede, M, P, Row, Sample, Table, Title, tone,
} from "../ui/prose";

const IMPORT_CODE = "import {
  DELEGATION_PROGRAM_ID, Delegated, delegated, expectAddress, pdaWithBump, programAddress,
} from \"std/solana\";
import {
  DelegationAccounts,
  DelegationConfig,
  MAGIC_CONTEXT_ID,
  MAGIC_PROGRAM_ID,
  commit,
  commitAndUndelegate,
  delegate,
  isUndelegateCallback,
  onValidator,
  undelegate,
} from \"std/solana/magicblock\";";
const DELEGATE_ACCOUNTS_CODE = "export struct DelegatePetAccounts {
  payer: WritableSigner;
  config: Owned<Config>;
  delegated: Mutable<PetAccount>;
  ownerProgram: Account;
  buffer: Writable;
  delegationRecord: Writable;
  delegationMetadata: Writable;
  delegationProgram: Account;
  systemProgram: Program<System>;
}";
const DELEGATE_CODE = "const request: DelegationAccounts = {
  payer: x.payer.asAccount(),
  delegated: x.delegated.asAccount(),
  ownerProgram: x.ownerProgram,
  buffer: x.buffer.asAccount(),
  delegationRecord: x.delegationRecord.asAccount(),
  delegationMetadata: x.delegationMetadata.asAccount(),
  systemProgram: x.systemProgram.asAccount(),
};
const _programs = try delegationPrograms(request, x.delegationProgram);
const derived = try programAddress([\"pet\", record.mint, [record.bump]]);
if (derived != request.delegated.key()) { return Result.err(ProgramError.constraintSeeds()); }
return delegate(request, [\"pet\", record.mint], record.bump, try validatorOf(config));";
const DELEGATE_CHECKS_CODE = "export function delegationPrograms(
  request: DelegationAccounts,
  delegationProgram: Account,
): Result<uint64, ProgramError> {
  if (request.ownerProgram.key() != programId()) {
    return Result.err(ProgramError.invalidProgramId());
  }
  if (delegationProgram.key() != DELEGATION_PROGRAM_ID) {
    return Result.err(ProgramError.invalidProgramId());
  }
  return Result.ok(0);
}

export function validatorOf(config: Readonly<Ptr<Config>>): Result<DelegationConfig, ProgramError> {
  if (config.validator.isZero()) { return Result.err(ProgramError.invalidArgument()); }
  return Result.ok(DelegationConfig.onValidator(config.validator));
}";
const COMMIT_ACCOUNTS_CODE = "export struct CommitPetAccounts {
  committer: Signer;
  pet: Mutable<PetAccount>;
  payer: Mutable<VrfPayer>;
  magicContext: Writable;
  magicFeeVault: Writable;
  magicProgram: Account;
  config: Owned<Config>;
}";
const COMMIT_CODE = "const _seeds = try pdaWithBump(x.pet, [\"pet\", record.mint], record.bump);
const _context = try expectAddress(x.magicContext.key(), MAGIC_CONTEXT_ID);
const _program = try expectAddress(x.magicProgram.key(), MAGIC_PROGRAM_ID);
const _payer = try pdaWithBump(x.payer, [\"vrf-payer\"], x.payer.data().bump);
const committed: Account[1] = [x.pet.asAccount()];
return signed(
  commit(
    x.payer.asAccount(), committed, x.magicContext.asAccount(), x.magicFeeVault.asAccount(),
  ),
  [\"vrf-payer\", [x.payer.data().bump]],
);";
const UNDELEGATE_CODE = "export struct UndelegationAccounts {
  delegated: Writable;
  buffer: Account;
  payer: Writable;
  systemProgram: Program<System>;
}

export function processUndelegation(): Result<uint64, ProgramError> {
  const data = instructionData();
  if (!isUndelegateCallback(data)) {
    return Result.err(ProgramError.instructionFallbackNotFound());
  }
  const x = try accounts<UndelegationAccounts>();
  return undelegate(x.delegated.asAccount(), x.buffer, x.payer.asAccount(), programId(), data);
}";
const DELEGATED_FIELD_CODE = "@seeds(\"pet\", pet.mint) @bump(pet.bump) pet: Delegated<PetAccount>;";
const UNPINNED_CODE = "error: Macro 'accounts': accounts<ReadAccounts>(): field 'counter' is a Delegated<T> with no @seeds/@bump or @address: any account the delegation program owns with T's layout would pass";
const EITHER_CODE = "function claimant(holder: Account): Result<Claimant, ProgramError> {
  if (holder.owner() == DELEGATION_PROGRAM_ID) {
    const pet = try delegated<PetAccount>(PET_INDEX);
    const record = pet.data();
    const _seeds = try pdaWithBump(pet, [\"pet\", record.mint], record.bump);
    return Result.ok(claimantOf(record));
  }
  const pet = try owned<PetAccount>(PET_INDEX);
  const record = pet.data();
  const derived = try programAddress([\"pet\", record.mint, [record.bump]]);
  if (derived != pet.key()) { return Result.err(ProgramError.constraintSeeds()); }
  return Result.ok(claimantOf(record));
}";

const VRF_IMPORT_CODE = "import { instructionDiscriminator, putU64 } from \"std/solana\";
import {
  RandomnessRequest, VRF_PROGRAM_ID, requestRandomness, verifyVrfCallback,
} from \"std/solana/vrf\";";
const REQUEST_CODE = "let argumentBytes: uint8[8] = [];
const _written = putU64(argumentBytes, 0, block.pendingRequest);
const request: RandomnessRequest = {
  payer: x.payer.asAccount(),
  programIdentity: x.programIdentity,
  oracleQueue: x.oracleQueue,
  systemProgram: x.systemProgram,
  slotHashes: x.slotHashes,
};
return signed(
  requestRandomness(
    request, callerSeedOf(block), seededDiscriminator(), x.block, argumentBytes,
  ),
  [\"vrf-payer\", [bump]],
);";
const DISCRIMINATOR_CODE = "export function seededDiscriminator(): uint64 {
  const discriminator: uint64 = @comptime { return instructionDiscriminator(\"Seeded\").word(); };
  return discriminator;
}";
const CALLBACK_TYPES_CODE = "export struct SeededAccounts {
  identity: Account;
  block: Mutable<Block>;
}

export struct SeededArgs {
  randomness: Pubkey;
  request: uint64;
}";
const CALLBACK_CODE = "export function seeded(): Result<uint64, ProgramError> {
  const callback = try args<SeededArgs>();
  const accountsOfCallback = try accounts<SeededAccounts>();
  const _verified = try verifyVrfCallback(accountsOfCallback.identity);
  const block = accountsOfCallback.block.data();
  if ((block.phase as Phase) != Phase.Seeding || callback.request != block.pendingRequest) {
    return Result.ok(0);
  }
  block.roundSeed = seedOf(callback.randomness);
  block.pendingRequest = 0;
  turnOrder(block.roundSeed, block.epoch, block.id, block.round as int32, block.turns);
  block.cursor = 0;
  block.phase = Phase.Acting as uint8;
  return Result.ok(block.roundSeed);
}";
const VRF_TEST_CODE = "const calls = invocations();
const request = calls[calls.length - 2];
assert request.program == VRF_PROGRAM_ID;
assert request.signers == 2;";

const CRANK_IMPORT_CODE = "import { AccountMeta, instructionDiscriminator, putU64 } from \"std/solana\";
import {
  CrankAccounts, CrankSchedule, HYDRA_PROGRAM_ID, cancelCrank, createCrank, crankAddress,
  crankSpent, once,
} from \"std/solana/hydra\";
import { MAGIC_PROGRAM_ID, MAGIC_VAULT_ID } from \"std/solana/magicblock\";";
const CRANK_CHECK_CODE = "export function checkedCrankAccounts(
  accounts: CrankAccounts,
  hydraProgram: Account,
  expected: Pubkey,
): Result<uint64, ProgramError> {
  if (hydraProgram.key() != HYDRA_PROGRAM_ID) {
    return Result.err(ProgramError.incorrectProgramId());
  }
  if (accounts.magicProgram.key() != MAGIC_PROGRAM_ID) {
    return Result.err(ProgramError.incorrectProgramId());
  }
  if (accounts.magicVault.key() != MAGIC_VAULT_ID) {
    return Result.err(ProgramError.invalidArgument());
  }
  if (accounts.crank.key() != expected) { return Result.err(ProgramError.invalidSeeds()); }
  return Result.ok(0);
}";
const CRANK_CREATE_CODE = "let data: uint8[16] = [];
const _sequenced = putU64(data, 8, seq);
let metas: AccountMeta[13] = [];
metas[0] = { key: sponsor, writable: true, signer: false };
metas[1] = { key: schedule.configKey, writable: false, signer: false };
const _named = putU64(
  data, 0, @comptime { return instructionDiscriminator(\"RoundStart\").word(); },
);
return signed(
  createCrank(schedule.cranks, seed, CrankSchedule.once(dueSlot), programId(), metas, data),
  [\"vrf-payer\", [bump]],
);";
const CRANK_SCHEDULE_CODE = "export struct CrankSchedule {
  startSlot: uint64;
  intervalSlots: uint64;
  remaining: uint64;
  priorityTip: uint64;
  computeUnits: uint32;
}";
const CRANK_FRESH_CODE = "if (seq + 1 != block.crankSeq) {
  return Result.err(hibernalError(HibernalError.StaleStep));
}
if (now.slot + 2 < block.dueSlot) { return Result.err(hibernalError(HibernalError.TooEarly)); }";
const SWEEP_CODE = "export function sweep(): Result<uint64, ProgramError> {
  const x = try accounts<SweepAccounts>();
  const bump = x.payer.data().bump;
  const _payer = try pdaWithBump(x.payer, [\"vrf-payer\"], bump);
  const sponsor = x.payer.asAccount();
  let cancelled: uint64 = 0;
  for (let index = SWEEP_CRANK_ACCOUNT; index < accountCount(); index++) {
    const crank = try account(index);
    const spent = try crankSpent(crank, sponsor.key());
    if (!spent) { continue; }
    const held: CrankAccounts = {
      sponsor: sponsor,
      crank: crank,
      magicVault: x.magicVault.asAccount(),
      magicProgram: x.magicProgram,
    };
    const _cancelled = try signed(cancelCrank(held), [\"vrf-payer\", [bump]]);
    cancelled = cancelled + 1;
  }
  return Result.ok(cancelled);
}";
const CRANK_TEST_CODE = "const created = calls[calls.length - 1];
assert created.program == HYDRA_PROGRAM_ID && created.signers == 1;
assert created.accounts[0].key == step[0].key && created.accounts[0].signer;
assert created.accounts[1].key == crankKey(0, 1);";

export function Rollups(): NeonNode {
	return <>
		<Title tone={tone.chain} title="MagicBlock rollups" />
		<Lede t={"A program hands an account to a MagicBlock ephemeral rollup, writes it there, and " +
			"takes it back."} />
		<P>
			Ephemeral rollups are MagicBlock's network, not part of Solana and not part of
			Geass. The delegation and Magic programs are MagicBlock's. What Geass ships is the
			binding, <M t="std/solana/magicblock" />, which builds their instructions and
			checks their accounts.
		</P>
		<P>
			The samples on these three pages are parts of one game that runs on the
			bindings, not whole programs. <M t="Config" />, <M t="PetAccount" /> and{" "}
			<M t="Block" /> are its account types. The bindings are tested in the host
			simulator only, which records these calls and executes none; prove your
			program on a MagicBlock devnet before you rely on it.
		</P>
		<Heading at="life" title="The life of a delegated account" />
		<P>
			The rollup runs the same program at the same id. While an account is delegated,
			the delegation program owns it on the base layer and your program owns it on the
			rollup.
		</P>
		<Table>
			<Head a="STEP" b="WHERE IT RUNS" />
			<Row a="Delegate" b="Base layer" />
			<Row a="Write" b="Rollup. An ordinary handler with a Mutable<T> field" />
			<Row a="Commit" b="Rollup. The state is written to the base layer" />
			<Row a="Commit and undelegate" b="Rollup. The account also goes back" />
			<Row
				a="ProcessUndelegation"
				b="Base layer. The delegation program calls your program"
			/>
		</Table>
		<Sample code={IMPORT_CODE} />
		<Heading at="delegating" title="Delegating" />
		<P>
			The account is a PDA of your program. <M t="delegate" /> takes the seven accounts
			of the hand-over, the seeds the account was created with, its bump and the
			validator:
		</P>
		<Sample code={DELEGATE_ACCOUNTS_CODE} />
		<Sample code={DELEGATE_CODE} />
		<P>
			It copies the data into a buffer, assigns the account to the delegation program
			under the account's own seeds and closes the buffer. A list of no seeds, or of more
			than eight, is a compile error.
		</P>
		<Heading at="delegate-checks" title="What you check yourself" />
		<P>
			<M t="delegate" /> refuses an owner program that is not this one. It proves
			neither that <M t="delegationProgram" /> is the delegation program nor that the
			account sits at the PDA of the seeds, so the handler does:
		</P>
		<Sample code={DELEGATE_CHECKS_CODE} />
		<P>
			<M t="DelegationConfig.onValidator(key)" /> names one rollup validator and{" "}
			<M t="DelegationConfig.anyValidator()" /> leaves it open.
		</P>
		<Heading at="committing" title="Committing" />
		<Sample code={COMMIT_ACCOUNTS_CODE} />
		<Sample code={COMMIT_CODE} />
		<P>
			<M t="commit" /> takes one account, a list, or a list with the validator's fee
			vault. <M t="commitAndUndelegate" /> has the same three forms. A call carries at
			most 14 accounts, 13 with the vault. The payer signed the transaction or is a PDA
			under <M t="signed" />. Neither call checks the context account or the Magic
			program; compare them with the constants as above.
		</P>
		<Heading at="undelegation" title="Coming back" />
		<P>
			After <M t="commitAndUndelegate" /> the delegation program calls your program on
			the base layer. The call carries the discriminator of{" "}
			<M t="process_undelegation" />, so the member of your instruction enum is named{" "}
			<M t="ProcessUndelegation" />:
		</P>
		<Sample code={UNDELEGATE_CODE} />
		<P>
			<M t="undelegate" /> creates the account again at its PDA and copies the buffer
			in. It refuses a buffer that did not sign, one the delegation program does not own
			or that is not the buffer of this account, and seeds that do not derive the
			account.
		</P>
		<Heading at="delegated" title="Reading a delegated account" />
		<P>
			On the base layer a delegated account is a <M t="Delegated<T>" />: the last state
			the rollup committed, read-only. Its owner must be the delegation program (3007
			otherwise), and
			the discriminator and size are checked as for <M t="Owned<T>" />.
		</P>
		<Sample code={DELEGATED_FIELD_CODE} />
		<P>
			The delegation program owns the delegated accounts of every program, so the type
			proves nothing about the address. A field without <M t="@seeds" /> and{" "}
			<M t="@bump" />, or <M t="@address" />, does not compile:
		</P>
		<Sample code={UNPINNED_CODE} />
		<P>A handler that takes the account in either state branches on the owner:</P>
		<Sample code={EITHER_CODE} />
		<Heading at="testing" title="Testing" />
		<P>
			The host simulator records every call to the delegation and Magic programs and
			executes none. After <M t="delegate" /> the simulator leaves the account owned
			by the delegation program with its data zeroed. A delegated account in a test is a{" "}
			<M t="HostAccount" /> whose owner is <M t="DELEGATION_PROGRAM_ID" />.
		</P>
		<Heading at="from-sdk" title="MagicBlock's Rust SDK to Geass" />
		<Table>
			<Head a="RUST SDK" b="GEASS" />
			<Row
				a="#[delegate] and a del field"
				b="Declare the buffer, record and metadata fields; call delegate(…)"
			/>
			<Row
				a="#[commit]"
				b="Declare magicContext and magicProgram; compare with the constants"
			/>
			<Row
				a="#[ephemeral]"
				b="Add ProcessUndelegation to the enum and write its handler"
			/>
			<Row a="delegate_account" b="delegate" />
			<Row a="commit_accounts" b="commit" />
			<Row a="commit_and_undelegate_accounts" b="commitAndUndelegate" />
			<Row a="undelegate_account" b="undelegate" />
		</Table>
	</>;
}

export function Randomness(): NeonNode {
	return <>
		<Title tone={tone.chain} title="MagicBlock VRF" />
		<Lede t={"A program asks MagicBlock's VRF oracle for 32 random bytes and receives them in an" +
			" instruction of its own."} />
		<P>
			The oracle, its queues and the VRF program are MagicBlock's, not Solana's and not
			Geass's. <M t="std/solana/vrf" /> is the binding that sends the request and
			proves who called back. It is tested in the host simulator only, where the
			request is recorded and no oracle answers. The samples are parts of a game,
			not whole programs.
		</P>
		<Heading at="requesting" title="Requesting" />
		<Sample code={VRF_IMPORT_CODE} />
		<P>
			<M t="requestRandomness" /> takes the five accounts of the request, 32 bytes of
			your choice as the caller seed, the discriminator of the instruction to call back,
			the accounts that instruction receives and its arguments. Here{" "}
			<M t="callerSeedOf" /> is the game's own function, 32 bytes that name the
			request:
		</P>
		<Sample code={REQUEST_CODE} />
		<P>
			<M t="programIdentity" /> is your program's PDA of the one seed{" "}
			<M t="identity" />. It signs the request, and the call adds its seeds itself. A
			payer that is a PDA signs through <M t="signed" />, as here. The call checks that
			the queue is writable and owned by the VRF program, not which queue it is:
			compare it with <M t="VRF_EPHEMERAL_QUEUE_ID" />,{" "}
			<M t="VRF_BASE_QUEUE_ID" /> or a key you store.
		</P>
		<Heading at="callback-id" title="Naming the callback" />
		<P>
			The callback is an ordinary member of the instruction enum. Its discriminator is
			computed at compile time:
		</P>
		<Sample code={DISCRIMINATOR_CODE} />
		<Heading at="callback" title="The callback" />
		<P>
			The oracle calls back with a signing identity account first, then the accounts you
			asked for. The data is the discriminator, the 32 random bytes, then your
			arguments:
		</P>
		<Sample code={CALLBACK_TYPES_CODE} />
		<Sample code={CALLBACK_CODE} />
		<P>
			<M t="verifyVrfCallback" /> proves the VRF program made the call: the identity
			signed, and its key is the PDA of <M t="identity" /> and your program id under
			the VRF program. It does not prove which request is being answered. Store a
			counter, send it as the argument and ignore an answer that does not match.
		</P>
		<Heading at="limits" title="Limits" />
		<P>
			A request with its callback accounts and arguments is at most 1,024 bytes. A
			longer one fails with <M t="InvalidInstructionData" /> before it is sent.
		</P>
		<Heading at="testing" title="Testing" />
		<P>
			The simulator records the request. Two signers are the identity and the payer
			PDA:
		</P>
		<Sample code={VRF_TEST_CODE} />
		<P>
			To test the callback, run it with an identity <M t="HostAccount" /> at that PDA
			and <M t="signer: true" />.
		</P>
	</>;
}

export function Cranks(): NeonNode {
	return <>
		<Title tone={tone.chain} title="MagicBlock cranks" />
		<Lede t={"A crank stores one instruction of your program. Hydra, MagicBlock's crank program," +
			" lets anyone trigger it on the rollup once the slot you name is due."} />
		<P>
			<M t="std/solana/hydra" /> binds Hydra's program on a MagicBlock ephemeral
			rollup; Hydra's base-layer program is not bound. The binding creates and cancels
			cranks; the scheduling is Hydra's. It is tested in the host simulator only, where a
			crank is recorded and never fires. The samples are parts of a game, not whole
			programs.
		</P>
		<Heading at="accounts" title="The accounts" />
		<Sample code={CRANK_IMPORT_CODE} />
		<P>
			<M t="CrankAccounts" /> is the sponsor, the crank, the Magic vault and the Magic
			program. The sponsor signs, pays the rent and is the crank's authority. The
			crank sits at <M t="crankAddress(sponsor, seed)" />. <M t="createCrank" /> derives
			nothing, so check all four:
		</P>
		<Sample code={CRANK_CHECK_CODE} />
		<Heading at="creating" title="Creating" />
		<P>
			The stored instruction is a program id, a list of accounts and data. The data
			starts with the discriminator of the instruction to run. Two of the thirteen
			accounts are shown:
		</P>
		<Sample code={CRANK_CREATE_CODE} />
		<P>
			A stored account cannot be a signer, and 136 bytes plus 33 for each account plus
			the data must fit in 944. Either fails with <M t="InvalidArgument" /> before the
			call.
		</P>
		<Heading at="schedule" title="The schedule" />
		<P>
			<M t="CrankSchedule.once(slot)" /> is one run with the compute ceiling of
			1,400,000 units. A repeating crank fills the fields itself; a{" "}
			<M t="remaining" /> of 0 means forever:
		</P>
		<Sample code={CRANK_SCHEDULE_CODE} />
		<Heading at="firing" title="When it fires" />
		<P>
			The instruction arrives with no signer, so anyone can send it. The handler proves
			from state that this run is the expected one and that it is due:
		</P>
		<Sample code={CRANK_FRESH_CODE} />
		<Heading at="sweeping" title="Cancelling" />
		<P>
			A crank stays after its last run. <M t="crankSpent" /> is true when Hydra owns the
			account, the sponsor is its authority and no run is left;{" "}
			<M t="cancelCrank" /> closes it and returns the rent:
		</P>
		<Sample code={SWEEP_CODE} />
		<Heading at="testing" title="Testing" />
		<P>The simulator records create and cancel as calls to Hydra:</P>
		<Sample code={CRANK_TEST_CODE} />
		<Heading at="schedule-task" title="The older scheduleTask" />
		<P>
			<M t="scheduleTask" /> of <M t="std/solana/magicblock" /> sends the Magic
			program's own task instruction. Its payer must have signed the transaction, so a
			PDA cannot pay. Use a crank.
		</P>
	</>;
}
