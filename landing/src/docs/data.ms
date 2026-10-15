import { NeonNode } from "../../../../neon/src/render/node";
import { Head, Heading, Lede, M, P, Row, Sample, Table, Title, tone } from "../ui/prose";

const DECLARE_CODE = "export struct Escrow {
  seed: uint64;
  maker: Pubkey;
  mintA: Pubkey;
  mintB: Pubkey;
  receive: uint64;
  bump: uint8;
}

export function discriminator(this typeof Escrow): Discriminator {
  return @comptime { return accountDiscriminator(\"Escrow\"); };
}";
const LIFECYCLE_CODE = "const oracle = try create<Oracle>(x.payer, x.oracle.asWritable());

const made = try createPda<Counter>(x.payer, x.target, [\"counter\", x.payer]);
const _grown = try realloc(made.asMutable(), 148, x.payer);

const _escrowClosed = try close(x.escrow, x.maker.asWritable());";
const ERROR_CODE = "export enum EscrowError {
  ZeroAmount,
}

export converter escrowError(error: EscrowError): ProgramError {
  return ProgramError.userError(error as uint32);
}";
const RAISE_CODE = "if (a.deposit == 0 || a.receive == 0) {
  return Result.err(EscrowError.ZeroAmount);
}";
const EVENT_CODE = "export struct Made {
  amount: uint64;
  maker: Pubkey;
  done: boolean;
}

const made: Made = { amount: a.deposit, maker: x.maker.key(), done: true };
emit<Made>(made);";

export function AccountData(): NeonNode {
	return <>
		<Title tone={tone.core} title="Account data" />
		<Lede t={"State is a fixed-size struct read in place. Creating, resizing and closing an " +
			"account are calls in the handler."} />
		<Heading at="declaring" title="Declaring an account type" />
		<P>
			A struct and one exported function. On chain the account is 8 bytes of
			discriminator followed by the struct, the layout Anchor's zero-copy accounts use.
			Declare it in a module the program and the client share:
		</P>
		<Sample code={DECLARE_CODE} />
		<P>
			The string must be the type's own name. A copy of another type's line is refused at
			the first use, and so is a hand-written discriminator.
		</P>
		<Heading at="field-types" title="Field types" />
		<Table>
			<Head a="METASCRIPT" b="RUST" />
			<Row a="uint8, uint16, uint32, uint64" b="u8, u16, u32, u64" />
			<Row a="int8, int16, int32, int64" b="i8, i16, i32, i64" />
			<Row a="float32, float64" b="f32, f64" />
			<Row a="boolean" b="bool, stored as one byte that must be 0 or 1" />
			<Row a="Pubkey" b="Pubkey / Address, 32 bytes" />
			<Row a="T[N]" b="[T; N]" />
			<Row a="an enum" b="The integer it is stored in, checked against its members" />
			<Row a="a nested struct" b="A nested #[repr(C)] struct" />
		</Table>
		<P>
			A <M t="string" />, a list that grows or a union is refused: a list is a fixed
			array with its length in a field beside it. There is no 128-bit integer. The
			layout is C's, and the IDL refuses padding between fields, so order them widest
			first or add a <M t="pad: uint8[N]" /> field.
		</P>
		<Heading at="lifecycle" title="Create, resize, close" />
		<P>
			<M t="create<T>" /> and <M t="createPda<T>" /> are Anchor's <M t="init" />: a new
			account is created, a prefunded one is topped up to rent exemption, and the
			discriminator is written last. There is no <M t="space" />: the size is 8 bytes
			plus the struct, and a struct is as long as C makes it, a multiple of its widest
			field. The <M t="Escrow" /> above has 113 bytes of fields in a 120-byte struct,
			so its account is 128 bytes. An account at a keypair address signs its own
			creation, so its
			field is a <M t="WritableSigner" /> passed with <M t="asWritable()" />.{" "}
			<M t="realloc" /> takes the new total size, moves only the rent difference and
			zeroes the new bytes.{" "}
			<M t="close" /> sends every lamport to the destination, empties the data and
			returns the account to the System program, so a revived account does not read
			as its old self. The destination is a <M t="Writable" />; a{" "}
			<M t="WritableSigner" /> passes with <M t="asWritable()" />:
		</P>
		<Sample code={LIFECYCLE_CODE} />
	</>;
}

export function ErrorsEvents(): NeonNode {
	return <>
		<Title tone={tone.core} title="Errors and events" />
		<Lede t={"Errors are an enum, events are a struct. Both reach clients with Anchor's numbers " +
			"and Anchor's bytes."} />
		<Heading at="errors" title="Your program's errors" />
		<P>
			Declare an enum and a converter to <M t="ProgramError" />. The first member is
			6000, as with <M t="#[error_code]" />:
		</P>
		<Sample code={ERROR_CODE} />
		<P>
			Return the enum member. The converter, imported where the handler is, turns it
			into the error the handler's <M t="Result" /> carries:
		</P>
		<Sample code={RAISE_CODE} />
		<P>
			A decorator's error argument takes the member the same way:
			<M t="@constraint(escrow.receive > 0, EscrowError.ZeroAmount)" />.
		</P>
		<Heading at="framework-errors" title="Framework errors" />
		<P>
			<M t="ProgramError" /> also carries the runtime's builtin errors and Anchor's own
			codes with Anchor v1's numbers, so a failed check reads the same in an explorer:
			2006 for seeds, 3007 for a wrong owner, 3010 for a missing signature.
		</P>
		<Heading at="events" title="Events" />
		<P>
			<M t="emit<E>(value)" /> logs the event's discriminator and its fields in Borsh, the
			line Anchor's <M t="emit!" /> writes and a validator prints as{" "}
			<M t="Program data:" />. The value is a local, its fields are sized integers,{" "}
			<M t="boolean" /> and <M t="Pubkey" />, and an event over 1,024 bytes with its
			discriminator is a compile error:
		</P>
		<Sample code={EVENT_CODE} />
	</>;
}
