import { element } from "../../../neon/src/macros/ui/element";
import { publishWindow } from "../../../neon/src/render/environment";
import { hydrate, render } from "../../../neon/src/render/host";
import { HostNode } from "../../../neon/src/render/hostTypes";
import { NeonNode } from "../../../neon/src/render/node";
import { domHost, documentBody } from "../../../neon/src/platform/browser/dom";
import { createBrowserRoutingHistory, followLinks } from "../../../neon/src/platform/browser/routingHistory";
import { Docs, DocsSite, createDocsSite } from "./docs";
import { Home } from "./home";
import { NotFound } from "./notFound";
import { Playground, atPlayground } from "./playground";

extern class HTMLElement {
	replaceChildren(): void;
}

extern function pagePath(unused: int32): string from "(#, location.pathname.replace(/\\/+$/, ''))";
extern function servedWidth(unused: int32): number
	from "(#, Number(document.getElementById('served')?.dataset.width ?? 0))";
extern function servedRoot(unused: int32): HTMLElement from "(#, document.getElementById('served'))";
extern function realWidth(unused: int32): number from "(#, innerWidth)";
extern function realHeight(unused: int32): number from "(#, innerHeight)";

const path = pagePath(0);
const routed = createDocsSite(createBrowserRoutingHistory());
const docs: DocsSite | null = routed.ok ? routed.value : null;

function page(): NeonNode {
	return path === "" ? element(<Home />)
		: atPlayground(path) ? element(<Playground />)
		: docs !== null ? element(<Docs site={docs as DocsSite} />)
		: element(<NotFound />);
}

const host = domHost();
const servedAt = servedWidth(0);

if (servedAt === 0) {
	render(page(), host, documentBody());
} else {
	const root = servedRoot(0);
	publishWindow(servedAt, 0);
	try {
		hydrate(page(), host, root as unknown as HostNode);
	} catch (error) {
		console.error(`the served page was rebuilt: ${error}`);
		root.replaceChildren();
		render(page(), host, root as unknown as HostNode);
	}
	publishWindow(realWidth(0), realHeight(0));
}
if (docs !== null) { followLinks((docs as DocsSite).open); }
