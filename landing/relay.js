const RPC = "https://api.devnet.solana.com";
const PROGRAM = "7PQcxszNYMSBRWWAxzCXHRPVnbiDLpiHMkMGs3sg8hcM";
const COUNTER = "6CumMagVwySYHLxeZNpYJ3YXbfmK615wRaC9cj2uNXgP";
const SYSTEM = "11111111111111111111111111111111";
const ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const PKCS8_ED25519 = [48, 46, 2, 1, 0, 48, 5, 6, 3, 43, 101, 112, 4, 34, 4, 32];
const CREATE = [0x18, 0x1e, 0xc8, 0x28, 0x05, 0x1c, 0x07, 0x77];
const INCREMENT = [0x0b, 0x12, 0x68, 0x09, 0x68, 0xae, 0x3b, 0x21];
const CALLS = {
	increment: { key: "RELAY_AUTHORITY", data: INCREMENT },
	stranger: { key: "RELAY_STRANGER", data: INCREMENT },
	create: { key: "RELAY_AUTHORITY", data: CREATE },
};

function decode(text) {
	let n = 0n;
	for (const ch of text) {
		const digit = ALPHABET.indexOf(ch);
		if (digit < 0) { throw new Error(`relay: ${text} is not base58`); }
		n = n * 58n + BigInt(digit);
	}
	const out = [];
	while (n > 0n) { out.unshift(Number(n & 255n)); n >>= 8n; }
	while (out.length < 32) { out.unshift(0); }
	return out;
}

function encode(bytes) {
	let n = 0n;
	for (const b of bytes) { n = n * 256n + BigInt(b); }
	let out = "";
	while (n > 0n) { out = ALPHABET[Number(n % 58n)] + out; n /= 58n; }
	for (const b of bytes) { if (b !== 0) { break; } out = "1" + out; }
	return out;
}

async function rpc(method, params) {
	const reply = await (await fetch(RPC, {
		method: "POST",
		headers: { "content-type": "application/json" },
		body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }),
	})).json();
	if (reply.error) { throw new Error(`devnet: ${method} answered ${JSON.stringify(reply.error)}`); }
	return reply.result;
}

async function signerOf(env, name) {
	const secret = env[name];
	if (!secret) { throw new Error(`relay: the Worker has no ${name} secret`); }
	const bytes = JSON.parse(secret);
	const key = await crypto.subtle.importKey(
		"pkcs8", new Uint8Array([...PKCS8_ED25519, ...bytes.slice(0, 32)]), { name: "Ed25519" }, false, ["sign"],
	);
	return { address: encode(bytes.slice(32, 64)), key };
}

async function counterState() {
	const { value } = await rpc("getAccountInfo", [COUNTER, { encoding: "base64", commitment: "confirmed" }]);
	if (value === null) { return { authority: "", count: "" }; }
	const data = Uint8Array.from(atob(value.data[0]), ch => ch.charCodeAt(0));
	const count = new DataView(data.buffer).getBigUint64(40, true);
	return { authority: encode(data.subarray(8, 40)), count: count.toString() };
}

export function messageOf(signer, op, blockhash) {
	const create = op === "create";
	const keys = create ? [signer, COUNTER, SYSTEM, PROGRAM] : [signer, COUNTER, PROGRAM];
	const accounts = create ? [0, 1, 2] : [0, 1];
	const data = CALLS[op].data;
	return new Uint8Array([
		1, 0, keys.length - 2, keys.length, ...keys.flatMap(decode), ...decode(blockhash),
		1, keys.length - 1, accounts.length, ...accounts, data.length, ...data,
	]);
}

export async function signedCall(env, op, blockhash) {
	const signer = await signerOf(env, CALLS[op].key);
	const message = messageOf(signer.address, op, blockhash);
	const signature = new Uint8Array(await crypto.subtle.sign("Ed25519", signer.key, message));
	const wire = new Uint8Array([1, ...signature, ...message]);
	return { signature: encode(signature), wire: btoa(String.fromCharCode(...wire)) };
}

async function settled(signature) {
	for (let tries = 0; tries < 30; tries++) {
		const found = await rpc("getTransaction", [signature, { commitment: "confirmed", maxSupportedTransactionVersion: 0 }]);
		if (found !== null) { return found; }
		await new Promise(resolve => setTimeout(resolve, 1000));
	}
	throw new Error(`${signature} did not confirm within 30 s`);
}

function failureOf(meta) {
	if (meta.err === null) { return ""; }
	if (meta.logMessages.some(line => / already in use/.test(line))) { return "the counter account exists already"; }
	return meta.logMessages.findLast(line => / failed: /.test(line)) ?? JSON.stringify(meta.err);
}

async function signed(op, blockhash) {
	const reply = await fetch("/api/sign", { method: "POST", body: JSON.stringify({ op, blockhash }) });
	const body = await reply.json().catch(() => ({ failure: `the relay answered ${reply.status}` }));
	if (body.failure) { throw new Error(body.failure); }
	return body;
}

async function call(op) {
	const before = await counterState();
	const { value: { blockhash } } = await rpc("getLatestBlockhash", [{ commitment: "confirmed" }]);
	const { signature, wire } = await signed(op, blockhash);
	await rpc("sendTransaction", [wire, { encoding: "base64", skipPreflight: true }]);
	const { meta } = await settled(signature);
	const after = await counterState();
	return {
		op, signature, ok: meta.err === null, failure: failureOf(meta),
		code: meta.err?.InstructionError?.[1]?.Custom ?? -1,
		units: meta.computeUnitsConsumed ?? 0, before: before.count, after: after.count,
	};
}

const failed = error => JSON.stringify({ failure: error.message });

export function readCounter(done) {
	counterState().then(state => JSON.stringify({ program: PROGRAM, ...state }), failed).then(done);
}

export function sendCall(op, done) {
	call(op).then(reply => JSON.stringify(reply), failed).then(done);
}

function json(body, status = 200) {
	return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

export async function relay(request, env) {
	const { pathname } = new URL(request.url);
	try {
		if (pathname === "/api/sign" && request.method === "POST") {
			const ip = request.headers.get("cf-connecting-ip") ?? "local";
			if (!(await env.CALLS.limit({ key: ip })).success) {
				return json({ failure: "Too many calls from here; try again in a minute" }, 429);
			}
			const { op, blockhash } = await request.json();
			if (!CALLS[op]) { return json({ failure: `relay: no call named ${op}` }, 400); }
			return json(await signedCall(env, op, blockhash));
		}
		return json({ failure: `relay: no route ${request.method} ${pathname}` }, 404);
	} catch (error) {
		return json({ failure: error.message }, 500);
	}
}
