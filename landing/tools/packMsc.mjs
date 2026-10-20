import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { brotliCompressSync, constants } from "node:zlib";

const from = process.argv[2] ?? `${homedir()}/.metascript/web/`;
const to = new URL("../public/msc/", import.meta.url);
mkdirSync(to, { recursive: true });
copyFileSync(from + "msc.js", new URL("msc.js", to));
for (const name of ["msc.wasm", "msc.data"]) {
	const packed = brotliCompressSync(readFileSync(from + name), { params: { [constants.BROTLI_PARAM_QUALITY]: 11 } });
	writeFileSync(new URL(name + ".br", to), packed);
}
console.log(readFileSync(`${homedir()}/.metascript/BUILD`, "utf8").match(/^web .*$/m)?.[0] ?? "~/.metascript/BUILD has no web line");
