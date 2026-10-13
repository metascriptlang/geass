import "./out/server.js";

const PHONE = 390;
const DESKTOP = 1440;

export default {
	async fetch(request, env) {
		const url = new URL(request.url);
		const path = url.pathname.replace(/\/+$/, "");
		const shell = () => env.ASSETS.fetch(new URL("/", url));

		const width = /Mobi/.test(request.headers.get("user-agent") ?? "") ? PHONE : DESKTOP;
		const hit = globalThis.geassPage(path, width);
		if (hit.html === "") {
			const asset = await env.ASSETS.fetch(request);
			if (asset.status !== 404) { return asset; }
		}

		const page = hit.html === "" ? globalThis.geassNotFound() : hit;
		const html = (await (await shell()).text())
			.replace("</head>", () => `${page.head}<style>${page.css}</style></head>`)
			.replace("<body>", () => `<body><div id="served" data-width="${width}">${page.html}</div>`);
		return new Response(html, {
			status: hit.html === "" ? 404 : 200,
			headers: { "content-type": "text/html; charset=utf-8" },
		});
	},
};
