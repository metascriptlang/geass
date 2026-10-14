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

extern function pagePath(): string from "(location.pathname.replace(/\\/+$/, ''))";
extern function servedWidth(): number from "(Number(document.getElementById('served')?.dataset.width ?? 0))";
extern function servedRoot(): HTMLElement from "(document.getElementById('served'))";
extern function realWidth(): number from "(innerWidth)";
extern function realHeight(): number from "(innerHeight)";

const path = pagePath();
const routed = createDocsSite(createBrowserRoutingHistory());
const docs: DocsSite | null = routed.ok ? routed.value : null;

function page(): NeonNode {
	return path === "" ? element(<Home />)
		: atPlayground(path) ? element(<Playground />)
		: docs !== null ? element(<Docs site={docs as DocsSite} />)
		: element(<NotFound />);
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
if (docs !== null) { followLinks((docs as DocsSite).open); }
