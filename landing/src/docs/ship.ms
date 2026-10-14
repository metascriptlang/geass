import { NeonNode } from "../../../../neon/src/render/node";
import {
	Head, Heading, L, Lede, M, P, Row, Sample, Table, Title, tone,
} from "../ui/prose";

const TEST_CODE = "when (testBuild) {
  import {
    Pubkey, SYSTEM_PROGRAM_ID, declaredProgramId, findProgramAddressOf, instructionDiscriminator,
  } from \"std/solana\";
  import { HostAccount, run } from \"std/solana/host\";

  function holder(key: Pubkey, lamports: uint64, signer: boolean): HostAccount {
    return {
      key: key, owner: SYSTEM_PROGRAM_ID, lamports: lamports, data: [],
      signer: signer, writable: true, executable: false,
    };
  }

  function initAccounts(): HostAccount[] {
    let payer = Pubkey.zero();
    payer.bytes[0] = 1;
    const counter = findProgramAddressOf(declaredProgramId(), [\"counter\"]);
    if (!counter.ok) { return []; }
    const system = {
      ...holder(SYSTEM_PROGRAM_ID, 1, false),
      owner: Pubkey.zero(), writable: false, executable: true,
    };
    return [holder(payer, 10000000000, true), holder(counter.value.key, 0, false), system];
  }

  function initData(): uint8[] {
    const tag = instructionDiscriminator(\"Init\");
    const bytes: uint8[] = [];
    for (let i = 0; i < 8; i++) { bytes.push(tag.bytes[i]); }
    return bytes;
  }

  test \"init creates the counter\" {
    const accounts = initAccounts();
    assert run(declaredProgramId(), accounts, initData(), entry).result == 0;
    assert accounts[1].owner == declaredProgramId() && accounts[1].data[8] == 42;
  }

  test \"a counter off the address is refused\" {
    const accounts = initAccounts();
    accounts[1].key.bytes[31] = accounts[1].key.bytes[31] ^ 1;
    const code = ProgramError.constraintSeeds().code;
    assert run(declaredProgramId(), accounts, initData(), entry).result == code;
  }

  test \"an unsigned payer is refused\" {
    const accounts = initAccounts();
    accounts[0].signer = false;
    const code = ProgramError.accountNotSigner().code;
    assert run(declaredProgramId(), accounts, initData(), entry).result == code;
  }
}";
const TEST_RUN_CODE = "$ msc test program.ms --tests-in-dir
 Test Files  1 passed (1)
      Tests  3 passed (3)";
const CLOCK_CODE = "import { invocations, logs, setClock, signerIs } from \"std/solana/host\";

setClock({
  slot: 7, epochStartTimestamp: 0, epoch: 0, leaderScheduleEpoch: 0,
  unixTimestamp: 1700000000,
});";
const LITESVM_INSTALL_CODE = "$ npm install litesvm@1.4.1 @solana/kit";
const LITESVM_HEAD_CODE = "import { createHash } from \"node:crypto\";
import { LiteSVM } from \"litesvm\";
import {
  AccountRole, address, appendTransactionMessageInstruction, createKeyPairSignerFromPrivateKeyBytes,
  createTransactionMessage, getProgramDerivedAddress, lamports, pipe,
  setTransactionMessageFeePayerSigner, setTransactionMessageLifetimeUsingBlockhash,
  signTransactionMessageWithSigners,
} from \"@solana/kit\";

const program = address(\"B7ihZyoXZ1fwAY3TugkiFJ6SXkzJwMuQrxrekBaSmn32\");
const programPath = \"out/counter.so\";
const SYSTEM = address(\"11111111111111111111111111111111\");";
const HOST_ACCOUNT_CODE = "export struct HostAccount {
  key: Pubkey;
  owner: Pubkey;
  lamports: uint64;
  data: uint8[];
  signer: boolean;
  writable: boolean;
  executable: boolean;
}";
const ASSERT_ERROR_CODE = "const zero = makeAccounts(7);
assert run(programKey(), zero, makeData(7, 0, 300), entry).result ==
  ProgramError.userError(0).code;";
const ASSERT_CPI_CODE = "const made = makeAccounts(7);
assert run(programKey(), made, makeData(7, 600, 300), entry).result == 0;
const created = invocations();
assert created.length == 3 && created[0].signers == 1 && created[1].signers == 0;
assert signerIs(created[0], 0, escrowSeeds(7));";
const ONE_HANDLER_CODE = "function beginEntry(): void {
  const result = resortBegin();
  if (!result.ok) { failWith(result.error); }
}

const outcome = run(programKey(), accounts, data, beginEntry);";
const LITESVM_CODE = "const svm = new LiteSVM();
svm.addProgramFromFile(program, programPath);
const payer = await createKeyPairSignerFromPrivateKeyBytes(new Uint8Array(32).fill(1));
svm.airdrop(payer.address, lamports(10_000_000_000n));

const [counter] = await getProgramDerivedAddress({ programAddress: program, seeds: [\"counter\"] });
const instruction = {
  programAddress: program,
  accounts: [
    { address: payer.address, role: AccountRole.WRITABLE_SIGNER, signer: payer },
    { address: counter, role: AccountRole.WRITABLE },
    { address: SYSTEM, role: AccountRole.READONLY },
  ],
  data: new Uint8Array(createHash(\"sha256\").update(\"global:init\").digest().subarray(0, 8)),
};
const message = pipe(
  createTransactionMessage({ version: 0 }),
  (m) => setTransactionMessageFeePayerSigner(payer, m),
  (m) => setTransactionMessageLifetimeUsingBlockhash(
    { blockhash: svm.latestBlockhash(), lastValidBlockHeight: 1000n }, m),
  (m) => appendTransactionMessageInstruction(instruction, m),
);
const result = svm.sendTransaction(await signTransactionMessageWithSigners(message));
console.log(`${result.computeUnitsConsumed()} CU`);";
const LITESVM_OUT_CODE = "Program B7ihZyoXZ1fwAY3TugkiFJ6SXkzJwMuQrxrekBaSmn32 consumed 1406 of 200000 compute units
Program B7ihZyoXZ1fwAY3TugkiFJ6SXkzJwMuQrxrekBaSmn32 success";
const IDL_CODE = "import { anchorIdl } from \"std/solana/idl\";
import { Escrow, EscrowError, EscrowOp, MakeArgs } from \"./layout\";
import { MakeAccounts, RefundAccounts, TakeAccounts } from \"./program\";

export function escrowIdl(): string {
  return anchorIdl<EscrowOp>({
    name: \"escrow\",
    Make: [MakeAccounts, MakeArgs],
    Take: [TakeAccounts],
    Refund: [RefundAccounts],
    accounts: [Escrow],
    events: [],
    errors: EscrowError,
  });
}

when (!testBuild) {
  console.log(escrowIdl());
}";
const IDL_RUN_CODE = "$ msc run idl.ms > escrow.json";
const CODAMA_INSTALL_CODE = "$ npm install codama@1.11.0 @codama/nodes-from-anchor @codama/renderers-js";
const IDL_OUT_CODE = "{\"name\":\"escrow\",\"writable\":true,\"pda\":{\"seeds\":[
  {\"kind\":\"const\",\"value\":[101,115,99,114,111,119]},
  {\"kind\":\"account\",\"path\":\"maker\"},
  {\"kind\":\"arg\",\"path\":\"seed\"}]}}";
const CODAMA_CODE = "import { rootNodeFromAnchor } from \"@codama/nodes-from-anchor\";
import { createFromRoot } from \"codama\";

const anchorIdl = JSON.parse(readFileSync(ANCHOR_IDL, \"utf8\"));
const root = rootNodeFromAnchor(anchorIdl);
writeFileSync(CODAMA_IDL, createFromRoot(root).getJson());";
const ANCHOR_CLIENT_CODE = "const idl = JSON.parse(readFileSync(idlPath, \"utf8\"));
const client = new Program(idl, { connection });

const built = await client.methods
  .make(new BN(seed), new BN(deposit), new BN(receive))
  .accountsStrict({
    maker: key(maker.address),
    mintA: key(mintA),
    mintB: key(mintB),
    makerAtaA: key(makerAtaA),
    escrow: key(escrow),
    vault: key(vault),
    associatedTokenProgram: key(ASSOCIATED),
    tokenProgram: key(TOKEN),
    systemProgram: key(SYSTEM),
  })
  .instruction();

const state = client.coder.accounts.decode(\"escrow\", Buffer.from(stored.data));";
const MS_CLIENT_CODE = "import {
  BorshWriter, Pubkey, decode, derivedAddressOf, instructionDiscriminator,
} from \"std/solana\";
import { Counter } from \"./layout\";

const program = Pubkey.parse(\"B7ihZyoXZ1fwAY3TugkiFJ6SXkzJwMuQrxrekBaSmn32\");
const counterSeed: uint8[] = [99, 111, 117, 110, 116, 101, 114];
if (program.ok) {
  const found = derivedAddressOf([counterSeed], program.value);
  if (found.ok) { console.log(`${found.value.key.toBase58()} bump ${found.value.bump}`); }
}

const data = BorshWriter.create()
  .discriminator(instructionDiscriminator(\"Add\"))
  .u64(500);

export function valueOf(stored: uint8[]): uint64 {
  const back = decode<Counter>(stored);
  return back.ok ? back.value.value : 0;
}";
const MS_CLIENT_RUN_CODE = "$ msc run --target=js client.ms";
const KIT_CLIENT_CODE = "import { createHash } from \"node:crypto\";
import { AccountRole, address } from \"@solana/kit\";

const programAddress = address(\"B7ihZyoXZ1fwAY3TugkiFJ6SXkzJwMuQrxrekBaSmn32\");
const snake = (name) => name.replace(/[A-Z]/g, (c, i) => (i ? \"_\" : \"\") + c.toLowerCase());
const instructionDiscriminator = (name) =>
  new Uint8Array(createHash(\"sha256\").update(`global:${snake(name)}`).digest().subarray(0, 8));
const joined = (...parts) => Uint8Array.from(parts.flatMap((part) => [...part]));
const u64 = (n) => {
  const bytes = new Uint8Array(8);
  new DataView(bytes.buffer).setBigUint64(0, BigInt(n), true);
  return bytes;
};
const signerOf = (signer) => ({ address: signer.address, role: AccountRole.READONLY_SIGNER, signer });
const writable = (key) => ({ address: key, role: AccountRole.WRITABLE });

const call = (name, accounts, ...args) => ({
  programAddress, accounts, data: joined(instructionDiscriminator(name), ...args),
});

const add = (authority, counter, amount) =>
  call(\"Add\", [signerOf(authority), writable(counter)], u64(amount));";
const BUILD_CODE = "$ msc build program.ms --os=solana --release --output=out/counter.so";
const ID_CODE = "const config = {
  defines: {
    programId: \"8JK1ZEmm83T8pHj4t59zsKp6meNW7GYhooWcRmh57ori\",
    programKeypair: \"target/deploy/counter-keypair.json\",
  },
};
export default config;";
const KEYPAIR_ERROR_CODE = "error: Macro 'instruction': the build declares programId B7ihZy…Smn32, but the deploy keypair '<project>/target/deploy/counter-keypair.json' is program 3Ldjuq…Z4Xp: set programId to 3Ldjuq…Z4Xp, or deploy with the keypair of B7ihZy…Smn32";
const KEYGEN_CODE = "$ solana-keygen new --no-bip39-passphrase -o target/deploy/counter-keypair.json
$ solana address -k target/deploy/counter-keypair.json";
const DEPLOY_CODE = "$ solana program deploy --program-id target/deploy/counter-keypair.json out/counter.so
Program Id: 8JK1ZEmm83T8pHj4t59zsKp6meNW7GYhooWcRmh57ori

$ solana program show 8JK1ZEmm83T8pHj4t59zsKp6meNW7GYhooWcRmh57ori
Owner: BPFLoaderUpgradeab1e11111111111111111111111
Data Length: 3344 (0xd10) bytes";

export function Testing(): NeonNode {
	return <>
		<Title tone={tone.build} title="Testing" />
		<Lede t={"Two layers. Tests written beside the program run its entry natively inside a " +
			"simulator of the runtime. The built program then runs in LiteSVM."} />
		<Heading at="host-tests" title="Tests beside the program" />
		<P>
			<M t="std/solana/host" /> is the simulator. <M t="run" /> builds the input the
			loader would, calls your entry, writes owner, lamports and data back into the same
			account list and returns the program's result. The <M t="when (testBuild)" /> block
			keeps the tests and their imports out of the program:
		</P>
		<P>
			This is the whole test of the counter from Getting started. Put it at the end
			of <M t="program.ms" />:
		</P>
		<Sample code={TEST_CODE} />
		<P>
			The account list is in the order of the accounts struct, the instruction data
			is the 8-byte discriminator followed by the arguments, and an account is a
			value you build:
		</P>
		<Sample code={HOST_ACCOUNT_CODE} />
		<P>
			Three things differ from a handler. Derive a PDA with{" "}
			<M t="findProgramAddressOf" /> and the program named, because outside{" "}
			<M t="run" /> no program is running. <M t="try" /> does not work inside a{" "}
			<M t="test" /> block today, so test <M t=".ok" />. And <M t="assert" /> belongs
			to the <M t="test" /> block itself, not to a helper function.
		</P>
		<Heading at="running" title="Running" />
		<P>
			<M t="--tests-in-dir" /> runs the tests of your directory. Without it,{" "}
			<M t="msc test" /> also runs the tests of every module the file imports, a few
			hundred of the standard library's. No validator starts in either case:
		</P>
		<Sample code={TEST_RUN_CODE} />
		<Heading at="simulator" title="What the simulator runs" />
		<P>
			System create, assign, transfer and allocate; Token and Token-2022 transfer,
			mint, burn, approve, revoke, set-authority, close and the initialization of an
			account or a mint; and the creation of an associated token account are executed.
			An instruction of those programs that the simulator does not model ends the run
			with <M t="NOT_SIMULATED" />. A CPI to any other program is recorded and answers
			success. Compute units are not metered here; measure them in LiteSVM.
		</P>
		<P>
			The simulator runs your program's checks and most of the runtime's: it refuses
			a System transfer out of an account that holds data, a signer that neither
			signed nor derives from the seeds you pass, and a program that spends lamports
			or writes data of an account it does not own. A CPI whose program is missing
			from the instruction's accounts still passes here and fails on chain. A green
			test proves your handler's logic; run every instruction in LiteSVM before you
			deploy.
		</P>
		<P>
			<M t="setClock" /> sets what <M t="clock()" /> reads, and <M t="logs()" /> returns
			the lines of the last run, an event's <M t="Program data:" /> among them:
		</P>
		<Sample code={CLOCK_CODE} />
		<Heading at="asserting" title="Asserting" />
		<P>A refusal is the error's code:</P>
		<Sample code={ASSERT_ERROR_CODE} />
		<P>
			<M t="invocations()" /> lists the CPIs of the last run, with their accounts, bytes
			and signer seeds. <M t="signerIs(call, index, seeds)" /> compares one signer of
			a call with a list of byte arrays, the bump as its last entry:
		</P>
		<Sample code={ASSERT_CPI_CODE} />
		<Heading at="one-handler" title="One handler at a time" />
		<P>
			<M t="run" /> takes any function, so a test can enter through one handler and skip
			the dispatch:
		</P>
		<Sample code={ONE_HANDLER_CODE} />
		<Heading at="litesvm" title="The program in LiteSVM" />
		<P>
			The second layer is Node: <M t="litesvm" /> 1.4.1 with <M t="@solana/kit" />. It
			loads the <M t=".so" /> and sends real transactions through the runtime a
			validator uses:
		</P>
		<Sample code={LITESVM_INSTALL_CODE} />
		<Sample code={LITESVM_HEAD_CODE} />
		<Sample code={LITESVM_CODE} />
		<Sample code={LITESVM_OUT_CODE} />
		<P>
			A program that consumes a few dozen units and creates nothing is one whose file
			lost its top-level <M t="entry()" /> call.{" "}
			<L to="/docs/program#entry" t="The entry" /> explains.
		</P>
		<Heading at="from-anchor" title="Anchor to Geass" />
		<Table>
			<Head a="ANCHOR" b="GEASS" />
			<Row
				a="anchor test"
				b="msc test program.ms --tests-in-dir, then a Node script on LiteSVM"
			/>
			<Row a="LiteSVM in Rust tests" b="The host simulator, in MetaScript" />
			<Row a="anchor test --profile" b="None. computeUnitsConsumed(), logComputeUnits()" />
			<Row a="anchor debugger, anchor coverage" b="None" />
			<Row a="the .so.debug file" b="out/counter.so.debug, the unstripped program" />
			<Row a="cargo check" b="msc check program.ms" />
		</Table>
	</>;
}

export function Clients(): NeonNode {
	return <>
		<Title tone={tone.build} title="Clients and IDL" />
		<Lede t={"The compiler writes an IDL from your types. Codama and Anchor's TypeScript client " +
			"read it, and the program's own declarations compile to JavaScript."} />
		<Heading at="idl" title="The IDL" />
		<P>
			<M t="anchorIdl<Op>(spec)" /> returns the IDL as a string built at compile time. Each
			key that is not <M t="name" />, <M t="address" />, <M t="accounts" />,{" "}
			<M t="events" /> or <M t="errors" /> is an instruction: its accounts struct, then
			its arguments struct when it has one. A member of the enum without an entry is a
			compile error. The name is the format, the JSON Anchor defined; no part of Anchor
			runs to produce it:
		</P>
		<Sample code={IDL_CODE} />
		<Sample code={IDL_RUN_CODE} />
		<P>
			<M t="idl.ms" /> imports the program, so running it also runs the top level of{" "}
			<M t="program.ms" />. Anything that file prints lands in the JSON; keep its top
			level to the <M t="entry()" /> call. A <M t="-d:programId=" /> override goes
			before the file name.
		</P>
		<Heading at="idl-contents" title="What it holds" />
		<P>
			Instructions with their discriminators, each account's <M t="writable" /> and{" "}
			<M t="signer" /> flags, the fixed address of a <M t="Program<P>" /> field, PDA
			seeds, argument types, account types as zero-copy structs and errors from 6000.
			The escrow account of <M t="make" /> comes out as:
		</P>
		<Sample code={IDL_OUT_CODE} />
		<P>
			A seed the format cannot express drops the <M t="pda" /> of that account. There
			are no doc strings and no constants, an associated token account carries no{" "}
			<M t="pda" />, and an error's message is its member name.
		</P>
		<Heading at="codama" title="Codama" />
		<P>
			Codama reads the file through its Anchor adapter. With <M t="codama" /> 1.11.0
			the escrow comes out as a Codama tree of 3 instructions, 1 account, 1 PDA and 1
			error:
		</P>
		<Sample code={CODAMA_INSTALL_CODE} />
		<Sample code={CODAMA_CODE} />
		<P>
			<M t="@codama/renderers-js" /> turns that tree into a TypeScript client for{" "}
			<M t="@solana/kit" />.
		</P>
		<Heading at="anchor-client" title="Anchor's TypeScript client" />
		<P>
			<M t="@coral-xyz/anchor" /> 0.31.1 builds every instruction of the escrow from that
			file and decodes its account:
		</P>
		<Sample code={ANCHOR_CLIENT_CODE} />
		<Heading at="metascript-client" title="A client in MetaScript" />
		<P>
			Declare account types in a module the program and the client share. On the
			JavaScript target and on your own machine, <M t="std/solana" /> has the same{" "}
			<M t="Pubkey" />, the discriminators, PDA derivation, a Borsh writer and reader
			and the account codec, which checks what the program checks. The{" "}
			<M t="bytes" /> of a <M t="BorshWriter" /> are the instruction data; sending is
			your RPC library's job. For a counter whose <M t="Counter" /> struct is in{" "}
			<M t="layout.ms" /> and whose <M t="Add" /> instruction takes one <M t="uint64" />:
		</P>
		<Sample code={MS_CLIENT_CODE} />
		<Sample code={MS_CLIENT_RUN_CODE} />
		<P>
			The build writes <M t="out/debug/client.js" />, an ES module a bundler imports
			like any other.
		</P>
		<Heading at="kit-client" title="By hand" />
		<P>
			An instruction is a discriminator and Borsh fields, so a client on{" "}
			<M t="@solana/kit" /> is short. The discriminator is the first 8 bytes of the
			SHA-256 of <M t="global:" /> and the instruction's name in snake_case. The same{" "}
			<M t="Add" />, which takes the authority's signature and the counter:
		</P>
		<Sample code={KIT_CLIENT_CODE} />
		<Heading at="not-yet" title="Not there yet" />
		<P>
			The compiler generates no client and writes no Codama file itself. The
			conversion above is a script of yours.
		</P>
	</>;
}

export function Deploying(): NeonNode {
	return <>
		<Title tone={tone.build} title="Deploying" />
		<Lede t={"The build writes an ordinary program file. The Solana CLI deploys it."} />
		<Heading at="build" title="The build" />
		<Sample code={BUILD_CODE} />
		<P>
			<M t="out/counter.so" /> is the stripped program and{" "}
			<M t="out/counter.so.debug" /> the unstripped copy. The program is sBPF v3, so it
			needs a validator of Agave 4.0 or later. The build needs Anza's platform tools;{" "}
			<L to="/docs#solana-toolchain" t="Getting started" /> installs them.
		</P>
		<P>
			Run the built file in LiteSVM before a first deploy.{" "}
			<L to="/docs/testing#litesvm" t="Testing" /> has the script, and{" "}
			<L to="/docs/security#limitations" t="Known limitations" /> lists what a green
			test does not prove today.
		</P>
		<Heading at="program-id" title="The program id" />
		<P>
			The id in <M t="build.ms" /> is read at build time: by PDAs whose seeds are all
			literals, by the IDL and by <M t="declaredProgramId()" /> in tests. Owner checks
			and signatures use the id the program runs under.
		</P>
		<Sample code={ID_CODE} />
		<Heading at="keypair" title="The deploy keypair" />
		<P>
			The program's address is the public key of a keypair file. Create it once and
			put the address it prints in <M t="programId" />:
		</P>
		<Sample code={KEYGEN_CODE} />
		<P>
			With <M t="programKeypair" /> the build reads the public half of the keypair file
			and stops when it is not the declared id:
		</P>
		<Sample code={KEYPAIR_ERROR_CODE} />
		<P>Keep the keypair file out of version control.</P>
		<Heading at="deploy" title="Deploying" />
		<Sample code={DEPLOY_CODE} />
		<Heading at="from-anchor" title="Anchor to Geass" />
		<Table>
			<Head a="ANCHOR" b="GEASS" />
			<Row a="anchor build" b="msc build program.ms --os=solana --release" />
			<Row a="anchor idl build" b="msc run idl.ms > program.json" />
			<Row a="anchor deploy" b="solana program deploy" />
			<Row a="anchor keys sync" b="programKeypair: the build stops, you edit the id" />
			<Row a="declare_id!" b="programId in build.ms, or -d:programId=" />
			<Row a="[programs.<cluster>]" b="One id per build" />
			<Row a="Anchor.toml" b="build.ms" />
			<Row a="anchor verify, --verifiable" b="None" />
		</Table>
	</>;
}
