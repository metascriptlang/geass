import { NeonNode } from "../../../../neon/src/render/node";
import {
	Head, Heading, L, Lede, M, Note, P, Row, Sample, Subheading, Table, Title, Warning, tone,
} from "../ui/prose";

const INIT_CODE = "$ msc init counter
$ cd counter";
const KEYGEN_CODE = "$ solana-keygen new --no-bip39-passphrase -o target/deploy/counter-keypair.json
$ solana address -k target/deploy/counter-keypair.json
BoPYRB7dosWryTV6q7HgHj5SkgtQczT2aLbuixC2EgmD";
const CONFIG_CODE = "import { BuildConfig } from \"std/build\";

const config: BuildConfig = {
  root: \"src/index.ms\",
  defines: {
    programId: \"BoPYRB7dosWryTV6q7HgHj5SkgtQczT2aLbuixC2EgmD\",
    programKeypair: \"target/deploy/counter-keypair.json\",
  },
  fmt: {
    useTabs: true,
  },
};

export default config;";
const PROGRAM_CODE = "import {
  Discriminator, Mutable, Program, ProgramError, Pubkey, Signer, System, Writable, WritableSigner,
  accountDiscriminator, accounts, bump, createPda, failWith, instruction, seeds,
} from \"std/solana\";

export struct Counter {
  authority: Pubkey;
  count: uint64;
  bump: uint8;
  pad: uint8[7];
}

export function discriminator(this typeof Counter): Discriminator {
  return @comptime { return accountDiscriminator(\"Counter\"); };
}

export enum CounterError {
  NotYourCounter,
}

export converter counterError(error: CounterError): ProgramError {
  return ProgramError.userError(error as uint32);
}

export struct CreateAccounts {
  payer: WritableSigner;
  counter: Writable;
  systemProgram: Program<System>;
}

export struct IncrementAccounts {
  authority: Signer;
  @seeds(\"counter\") @bump(counter.bump) counter: Mutable<Counter>;
}

function create(): Result<uint64, ProgramError> {
  const x = try accounts<CreateAccounts>();
  const made = try createPda<Counter>(x.payer, x.counter, [\"counter\"]);
  const counter = made.asMutable().data();
  counter.authority = x.payer.key();
  counter.count = 0;
  counter.bump = made.foundBump();
  return Result.ok(0);
}

function increment(): Result<uint64, ProgramError> {
  const x = try accounts<IncrementAccounts>();
  const counter = x.counter.data();
  if (counter.authority != x.authority.key()) {
    return Result.err(CounterError.NotYourCounter);
  }
  counter.count += 1;
  return Result.ok(0);
}

export enum CounterOp {
  Create,
  Increment,
}

export function dispatch(): Result<uint64, ProgramError> {
  return match (try instruction<CounterOp>()) {
    CounterOp.Create => create(),
    CounterOp.Increment => increment(),
  };
}

export function entry(): void {
  const result = dispatch();
  if (!result.ok) { failWith(result.error); }
}

when (!testBuild) {
  entry();
}";
const TEST_CODE = "import {
  Pubkey, SYSTEM_PROGRAM_ID, declaredProgramId, decode, findProgramAddressOf,
  instructionDiscriminator,
} from \"std/solana\";
import { HostAccount, run } from \"std/solana/host\";
import { Counter, entry } from \"./index\";

function wallet(id: uint8): HostAccount {
  let key = Pubkey.zero();
  key.bytes[0] = id;
  return {
    key: key, owner: SYSTEM_PROGRAM_ID, lamports: 1000000000, data: [],
    signer: true, writable: true, executable: false,
  };
}

function counterAccount(): HostAccount {
  const found = findProgramAddressOf(declaredProgramId(), [\"counter\"]);
  return {
    key: found.ok ? found.value.key : Pubkey.zero(), owner: SYSTEM_PROGRAM_ID, lamports: 0,
    data: [], signer: false, writable: true, executable: false,
  };
}

function systemProgram(): HostAccount {
  return {
    key: SYSTEM_PROGRAM_ID, owner: Pubkey.zero(), lamports: 1, data: [],
    signer: false, writable: false, executable: true,
  };
}

function call(name: string): uint8[] {
  const tag = instructionDiscriminator(name);
  const bytes: uint8[] = [];
  for (let i = 0; i < 8; i++) { bytes.push(tag.bytes[i]); }
  return bytes;
}

function countOf(account: HostAccount): uint64 {
  const counter = decode<Counter>(account.data);
  return counter.ok ? counter.value.count : 999;
}

test \"create, then increment twice\" {
  const created = [wallet(1), counterAccount(), systemProgram()];
  assert run(declaredProgramId(), created, call(\"Create\"), entry).result == 0;
  const incremented = [created[0], created[1]];
  assert run(declaredProgramId(), incremented, call(\"Increment\"), entry).result == 0;
  assert run(declaredProgramId(), incremented, call(\"Increment\"), entry).result == 0;
  assert countOf(incremented[1]) == 2;
}

test \"a stranger cannot increment\" {
  const created = [wallet(1), counterAccount(), systemProgram()];
  assert run(declaredProgramId(), created, call(\"Create\"), entry).result == 0;
  const stranger = [wallet(2), created[1]];
  assert run(declaredProgramId(), stranger, call(\"Increment\"), entry).result == 6000;
  assert countOf(stranger[1]) == 0;
}";
const TEST_RUN_CODE = "$ msc test src/index.test.ms --tests-in-dir
 Test Files  1 passed (1)
      Tests  2 passed (2)";
const BUILD_CODE = "$ msc build src/index.ms --os=solana --release --output=out/counter.so";
const WALLET_CODE = "$ solana config set --url devnet
$ solana-keygen new
$ solana airdrop 2";
const DEPLOY_CODE = "$ solana program deploy --program-id target/deploy/counter-keypair.json out/counter.so
Program Id: BoPYRB7dosWryTV6q7HgHj5SkgtQczT2aLbuixC2EgmD";
const NPM_CODE = "$ npm init -y
$ npm pkg set type=module
$ npm install @solana/kit";
const CLIENT_CODE = "import { createHash } from \"node:crypto\";
import { readFileSync } from \"node:fs\";
import { homedir } from \"node:os\";
import {
  AccountRole, address, appendTransactionMessageInstruction, createKeyPairSignerFromBytes,
  createSolanaRpc, createSolanaRpcSubscriptions, createTransactionMessage,
  getProgramDerivedAddress, pipe, sendAndConfirmTransactionFactory,
  setTransactionMessageFeePayerSigner, setTransactionMessageLifetimeUsingBlockhash,
  signTransactionMessageWithSigners,
} from \"@solana/kit\";

const rpc = createSolanaRpc(\"https://api.devnet.solana.com\");
const rpcSubscriptions = createSolanaRpcSubscriptions(\"wss://api.devnet.solana.com\");
const send = sendAndConfirmTransactionFactory({ rpc, rpcSubscriptions });

const program = address(\"BoPYRB7dosWryTV6q7HgHj5SkgtQczT2aLbuixC2EgmD\");
const system = address(\"11111111111111111111111111111111\");
const walletFile = readFileSync(`${homedir()}/.config/solana/id.json`, \"utf8\");
const wallet = await createKeyPairSignerFromBytes(new Uint8Array(JSON.parse(walletFile)));
const [counter] = await getProgramDerivedAddress({ programAddress: program, seeds: [\"counter\"] });

function instructionData(name: string): Uint8Array {
  return createHash(\"sha256\").update(`global:${name}`).digest().subarray(0, 8);
}

async function call(name: string, accounts: { address: string; role: AccountRole }[]) {
  const { value: blockhash } = await rpc.getLatestBlockhash().send();
  const message = pipe(
    createTransactionMessage({ version: 0 }),
    (m) => setTransactionMessageFeePayerSigner(wallet, m),
    (m) => setTransactionMessageLifetimeUsingBlockhash(blockhash, m),
    (m) => appendTransactionMessageInstruction(
      { programAddress: program, accounts, data: instructionData(name) }, m),
  );
  await send(await signTransactionMessageWithSigners(message), { commitment: \"confirmed\" });
}

const me = { address: wallet.address, role: AccountRole.WRITABLE_SIGNER, signer: wallet };
const writable = { address: counter, role: AccountRole.WRITABLE };
const existing = await rpc.getAccountInfo(counter, { encoding: \"base64\" }).send();
if (existing.value === null) {
  await call(\"create\", [me, writable, { address: system, role: AccountRole.READONLY }]);
}
await call(\"increment\", [me, writable]);

const stored = await rpc.getAccountInfo(counter, { encoding: \"base64\" }).send();
const bytes = Buffer.from(stored.value!.data[0], \"base64\");
console.log(`count = ${bytes.readBigUInt64LE(40)}`);";
const CLIENT_RUN_CODE = "$ node client.ts
count = 1
$ node client.ts
count = 2";

export function FirstProgram(): NeonNode {
	return <>
		<Title tone={tone.start} title="Your first program" />
		<Lede t={"Build a counter, test it on your machine, put it on Solana's devnet and call it " +
			"from TypeScript."} />
		<Heading at="goal" title="What you will build" />
		<P>
			A counter that lives on chain. Any wallet can create it once; after that only the
			wallet that created it can add one. It is small, but it has every part a real
			program has: state kept in an account, two instructions, a check on who is calling,
			a test and a client.
		</P>
		<P>
			You need <M t="msc" /> and the Solana CLI from{" "}
			<L to="/docs" t="Getting started" />, and Node 24 for the client at the end.
		</P>
		<Heading at="create" title="Create the project" />
		<Sample code={INIT_CODE} />
		<P>
			<M t="msc init" /> writes <M t="build.ms" />, the project's settings, and{" "}
			<M t="src/index.ms" />, where the program goes. A program on Solana lives at an
			address, and that address is the public key of a keypair you create once:
		</P>
		<Sample code={KEYGEN_CODE} />
		<P>
			Put the address it prints in <M t="build.ms" />, in place of the one below.
			With <M t="programKeypair" /> named too, the build stops when the two disagree:
		</P>
		<Sample code={CONFIG_CODE} />
		<P>The keypair is a private key. Keep it out of version control.</P>
		<Heading at="program" title="The whole program" />
		<P>Replace <M t="src/index.ms" /> with this. The next section reads it piece by piece.</P>
		<Sample code={PROGRAM_CODE} />
		<Heading at="reading" title="Reading it" />
		<P>
			Imports, functions, enums, <M t="const" /> and <M t="if" /> mean what they mean in
			TypeScript. What is new comes from Solana itself: where state lives, how a
			call says which accounts it touches, and how a program starts.
		</P>
		<Subheading at="the-account" title="The account" />
		<P>
			A Solana program keeps nothing between two calls. What it remembers, it writes
			into an account: storage on chain, with an address and a balance.{" "}
			<M t="Counter" /> describes the bytes of that account. It is a struct, not an
			interface: its fields sit in memory in the order you write them, with a size
			fixed at compile time, so the program reads the account in place instead of
			decoding a copy. <M t="uint64" /> and <M t="uint8" /> are integers of a fixed
			size, and a <M t="Pubkey" /> is a 32-byte address. <M t="pad" /> fills the
			struct to 48 bytes, so there is no hidden gap between fields.
		</P>
		<P>
			<M t="discriminator" /> marks the account with 8 bytes that say "this is a
			Counter", computed by the compiler from the type's name. Explorers and clients
			read the same 8 bytes.
		</P>
		<Subheading at="the-instructions" title="The instructions" />
		<P>
			An instruction is one call into your program, sent by a wallet in a transaction.
			The call lists the accounts it touches, and a struct names them in order. The
			type of each field is a check the account must pass before your code runs:
		</P>
		<Table>
			<Head a="FIELD" b="WHAT IT GUARANTEES" />
			<Row
				a="payer: WritableSigner"
				b="The wallet signed the transaction, and its balance may change: it pays for the counter"
			/>
			<Row a="counter: Writable" b="The account may be written. It does not exist yet" />
			<Row
				a="systemProgram: Program<System>"
				b="This is the System program, the one that creates accounts"
			/>
			<Row a="authority: Signer" b="This wallet signed the transaction" />
			<Row
				a="counter: Mutable<Counter>"
				b={"Owned by this program, holds a Counter and may be written. The decorators add: " +
					"it sits at the address of the seed \"counter\""}
			/>
		</Table>
		<P>
			<M t="accounts<T>()" /> runs those checks and hands you the accounts. When one
			fails, the instruction stops with an error code and nothing changes on chain.
		</P>
		<P>
			<M t="create" /> makes the counter with <M t="createPda" />. A PDA, a program
			derived address, is computed from your program's id and a list of seeds, here
			the word <M t="counter" />. It has no private key: only your program can sign
			for it, and that is how the program creates an account there. <M t="data()" />{" "}
			then gives you the account's bytes as a <M t="Counter" /> you write to directly.
		</P>
		<P>
			<M t="increment" /> compares the stored authority with the wallet that signed and
			refuses anyone else with your own error. <M t="NotYourCounter" /> is the first
			member of your error enum, so a client sees it as 6000, the number Anchor gives
			it too.
		</P>
		<P>
			A handler does not throw. It returns a <M t="Result" />:{" "}
			<M t="Result.ok(0)" /> when it worked, <M t="Result.err(...)" /> when it refuses.{" "}
			<M t="try" /> in front of a call passes a failure straight up and otherwise gives
			you the value. The <M t="converter" /> lets you return a{" "}
			<M t="CounterError" /> where a <M t="ProgramError" /> is expected.
		</P>
		<Subheading at="the-entry" title="The entry" />
		<P>
			<M t="CounterOp" /> names the two instructions.{" "}
			<M t="instruction<CounterOp>()" /> reads which one the transaction asked for, and{" "}
			<M t="match" /> calls its handler. A <M t="match" /> must cover every member, so
			an instruction without a handler does not compile.
		</P>
		<P>
			<M t="entry" /> runs the dispatch and reports a failure to the chain. The last
			three lines are where the program starts: the chain runs the top level of the
			file. <M t="when (!testBuild)" /> leaves the call out of test builds, so a test
			can call <M t="entry" /> itself.
		</P>
		<Warning>
			Keep the <M t="entry()" /> call. Without it, msc 0.3.3 still builds the program,
			and on chain it answers every instruction with success and does nothing.
		</Warning>
		<Subheading at="syntax" title="Syntax TypeScript lacks" />
		<Table>
			<Head a="YOU READ" b="IT MEANS" />
			<Row
				a="struct Counter { }"
				b="A value with a fixed layout in memory, field after field. Assigning it copies it"
			/>
			<Row a="uint64, uint8[7]" b="Sized integers, and an array of a fixed length" />
			<Row
				a="Result<uint64, ProgramError>"
				b="A value or an error, returned instead of thrown"
			/>
			<Row
				a="try call()"
				b="On an error, returns it from this function. Otherwise gives the value"
			/>
			<Row a="match (x) { A => ..., }" b="A switch that must cover every case" />
			<Row a="when (flag) { }" b="Decided by the compiler. The other branch is not built" />
			<Row a="@comptime { }" b="Runs in the compiler; the result is a constant" />
			<Row
				a="function f(this typeof Counter)"
				b="A function called as Counter.f(), declared outside the type"
			/>
			<Row
				a="converter"
				b="Turns one type into another wherever the second is expected"
			/>
			<Row a="@seeds(\"counter\")" b="A decorator: a check attached to one field" />
		</Table>
		<P>
			The rest of the language is in the{" "}
			<L to="https://metascriptlang.org/learn" t="MetaScript documentation" />.
		</P>
		<Heading at="test" title="Test it" />
		<P>
			Tests run on your machine against a simulator of the Solana runtime: no
			validator, no wallet, no SOL. Create <M t="src/index.test.ms" />:
		</P>
		<Sample code={TEST_CODE} />
		<P>
			<M t="run" /> calls your <M t="entry" /> the way the chain would: with the
			program id, the accounts in the order of the accounts struct, and the instruction
			data, which starts with the instruction's 8-byte discriminator. It writes the new
			balances and bytes back into the array you pass and returns 0 or the error code.
		</P>
		<Note>
			A struct is a value, so <M t="const b = a" /> copies it. That is why each test keeps
			its accounts in an array and reads the counter from the array that{" "}
			<M t="run" /> wrote to.
		</Note>
		<Sample code={TEST_RUN_CODE} />
		<P>
			<M t="--tests-in-dir" /> runs only the tests next to yours; without it,{" "}
			<M t="msc test" /> also runs the tests of the standard library modules you
			import. <L to="/docs/testing" t="Testing" /> covers the rest: CPIs, the clock,
			and what the simulator does not check.
		</P>
		<Heading at="build" title="Build it" />
		<Sample code={BUILD_CODE} />
		<P>
			<M t="out/counter.so" /> is the program: a few kilobytes of sBPF bytecode, the
			format the chain runs. The compiler writes C, and the clang of Anza's platform
			tools turns it into that file.
		</P>
		<Heading at="deploy" title="Deploy it to devnet" />
		<P>
			Devnet is Solana's public test network. Its SOL is free and worth nothing, so it
			is the place for a first deploy. Point the Solana CLI at it and give your wallet
			some SOL:
		</P>
		<Sample code={WALLET_CODE} />
		<P>
			<M t="solana-keygen new" /> writes your wallet to{" "}
			<M t="~/.config/solana/id.json" />; skip it if you have one. The airdrop is
			rate-limited, and when it refuses,{" "}
			<L to="https://faucet.solana.com" t="faucet.solana.com" /> hands out devnet SOL
			too. Then deploy:
		</P>
		<Sample code={DEPLOY_CODE} />
		<P>
			The program is stored in an account, so deploying costs its rent: about 0.03 SOL
			for this one. <M t="solana program show" /> and the id print what the chain holds.
		</P>
		<Heading at="call" title="Call it from TypeScript" />
		<P>
			A client sends a transaction with the program's address, the accounts in the
			order of the accounts struct, and the instruction's 8 bytes: the start of the
			SHA-256 of <M t="global:" /> and its name, as in Anchor. In the project folder:
		</P>
		<Sample code={NPM_CODE} />
		<P>
			Save this as <M t="client.ts" />, with your program's address in it:
		</P>
		<Sample code={CLIENT_CODE} />
		<Sample code={CLIENT_RUN_CODE} />
		<P>
			The first run creates the counter; every run adds one. The count is at byte 40 of
			the account, after the 8-byte discriminator and the 32-byte authority. Run it with
			another wallet and the transaction fails with{" "}
			<M t="Custom program error: #6000" />, your <M t="NotYourCounter" />.
		</P>
		<Note>
			Node 24 runs a <M t=".ts" /> file as it is, with a warning that type stripping is
			experimental. <L to="/docs/clients" t="Clients and IDL" /> generates a typed client
			from your program instead of writing the bytes by hand.
		</Note>
		<Heading at="next" title="Where to go next" />
		<Table>
			<Head a="TO" b="READ" />
			<Row a="Edit and run a counter in the browser" b="The Counter tab of the Playground" />
			<Row a="Learn the Solana words" b="Solana in five minutes" />
			<Row a="Map what you know from Anchor" b="Coming from Anchor" />
			<Row a="Check more, store more" b="Accounts, Account validation, Account data" />
			<Row a="Move SOL and tokens" b="Cross-program calls, Tokens" />
			<Row a="Fix an error" b="When you are stuck" />
		</Table>
		<P>
			<L to="/playground#counter" t="Open the counter in the Playground" />. Its
			scenario runs a stranger's increment too, and you can change a check and run it
			again.
		</P>
	</>;
}
