import { respond } from "./out/server.js";
import { relay } from "./relay.js";

const PACKED = /^\/msc\/msc\.(wasm|data)$/;

export default {
	async fetch(request, env) {
		const url = new URL(request.url);
		if (url.pathname.startsWith("/api/")) { return relay(request, env); }
		const packed = PACKED.exec(url.pathname);
		if (packed !== null) {
			const asset = await env.ASSETS.fetch(new URL(url.pathname + ".br", url));
			const headers = new Headers(asset.headers);
			headers.set("content-type", packed[1] === "wasm" ? "application/wasm" : "application/octet-stream");
			headers.set("content-encoding", "br");
			return new Response(asset.body, { status: asset.status, headers, encodeBody: "manual" });
		}
		const page = await respond(request, await (await env.ASSETS.fetch(new URL("/", url))).text());
		if (page.status === 404) {
			const asset = await env.ASSETS.fetch(request);
			if (asset.status !== 404) { return asset; }
		}
		return page;
	},
};
