import { page } from "./out/server.js";

const PHONE = 390;
const DESKTOP = 1440;
const PACKED = /^\/msc\/msc\.(wasm|data)$/;

export default {
	async fetch(request, env) {
		const url = new URL(request.url);
		const packed = PACKED.exec(url.pathname);
		if (packed !== null) {
			const asset = await env.ASSETS.fetch(new URL(url.pathname + ".br", url));
			const headers = new Headers(asset.headers);
			headers.set("content-type", packed[1] === "wasm" ? "application/wasm" : "application/octet-stream");
			headers.set("content-encoding", "br");
			return new Response(asset.body, { status: asset.status, headers, encodeBody: "manual" });
		}
		const width = /Mobi/.test(request.headers.get("user-agent") ?? "") ? PHONE : DESKTOP;
		const hit = page(url.pathname, width);
		if (hit.location !== null) { return Response.redirect(new URL(hit.location, url), hit.status); }
		if (hit.status === 404) {
			const asset = await env.ASSETS.fetch(request);
			if (asset.status !== 404) { return asset; }
		}

		const served = hit.markup;
		const html = (await (await env.ASSETS.fetch(new URL("/", url))).text())
			.replace("</head>", () => `${served.head}<style>${served.css}</style></head>`)
			.replace("<body>", () => `<body><div id="served" data-width="${width}">${served.html}</div>`);
		return new Response(html, {
			status: hit.status,
			headers: { "content-type": "text/html; charset=utf-8" },
		});
	},
};
