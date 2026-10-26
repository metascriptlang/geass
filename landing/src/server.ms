import { NeonNode } from "../../../neon/src/render/node";
import { App, DocumentProps, Served, serve } from "../../../neon/src/render/serve";
import { rawHtml } from "../../../neon/src/render/ssr";
import { NotFound } from "./notFound";
import { Site, routes, servedWidth } from "./routes";

function shell(template: string): (props: DocumentProps) => NeonNode {
	const html = template.indexOf("<html");
	const body = template.indexOf("<body>");
	if (html < 0 || body < 0) { throw new Error("the page shell has no <html> or no <body> to serve the page into"); }
	const opened = body + "<body>".length;
	return (props: DocumentProps): NeonNode => <>
		{rawHtml(template.slice(html, opened) + `<div id="served" data-width="${servedWidth()}">`)}
		{props.children}
		{rawHtml("</div>")}
		{props.scripts}
		{rawHtml(template.slice(opened))}
	</>;
}

function app(template: string): App {
	return { routes, notFound: <Site><NotFound /></Site>, client: "", document: shell(template) };
}

export function answer(path: string, userAgent: string, template: string): Promise<Served> {
	const headers = new Map<string, string>();
	headers.set("user-agent", userAgent);
	return serve(app(template), path, headers);
}

when (js) {
	import { Request, Response, fetchPage } from "../../../neon/src/render/serve";

	export function respond(request: Request, template: string): Promise<Response> {
		return fetchPage(app(template), request);
	}
}
