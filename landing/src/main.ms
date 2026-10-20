import { element } from "../../../neon/src/macros/ui/element";
import { publishWindow } from "../../../neon/src/render/environment";
import { hydrate, render } from "../../../neon/src/render/host";
import { HostNode } from "../../../neon/src/render/hostTypes";
import { NeonNode } from "../../../neon/src/render/node";
import { domHost, documentBody } from "../../../neon/src/platform/browser/dom";
import { createBrowserRoutingHistory, followLinks } from "../../../neon/src/platform/browser/routingHistory";
import { RouterProvider, createRouter } from "../../../neon/src/navigation/router";
import { NotFound } from "./notFound";
import { routes } from "./routes";

extern class HTMLElement {
	replaceChildren(): void;
}

extern function servedWidth(): number from "(Number(document.getElementById('served')?.dataset.width ?? 0))";
extern function servedRoot(): HTMLElement from "(document.getElementById('served'))";
extern function realWidth(): number from "(innerWidth)";
extern function realHeight(): number from "(innerHeight)";

const opened = createRouter(routes, createBrowserRoutingHistory());

function page(): NeonNode {
	return opened.ok ? element(<RouterProvider router={opened.value} />) : element(<NotFound />);
}

const host = domHost();
const servedAt = servedWidth();

if (servedAt === 0) {
	render(page(), host, documentBody());
} else {
	const root = servedRoot();
	publishWindow(servedAt, 0);
	try {
		hydrate(page(), host, root as unknown as HostNode);
	} catch (error) {
		console.error(`the served page was rebuilt: ${error}`);
		root.replaceChildren();
		render(page(), host, root as unknown as HostNode);
	}
	publishWindow(realWidth(), realHeight());
}
if (opened.ok) {
	const router = opened.value;
	followLinks((url: string): boolean => router.navigate(url));
}
