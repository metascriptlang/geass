import { element } from "../../../neon/src/macros/ui/element";
import { publishWindow } from "../../../neon/src/render/environment";
import { SsrMarkup, renderToMarkup } from "../../../neon/src/render/ssr";
import { createRequestRoutingHistory } from "../../../neon/src/navigation/routingHistory";
import { Docs, createDocsSite } from "./docs";
import { Home } from "./home";
import { NotFound } from "./notFound";
import { Playground, atPlayground } from "./playground";

extern function serve(page: (path: string, width: number) => SsrMarkup, lost: () => SsrMarkup): void
	from "(globalThis.geassPage = #, globalThis.geassNotFound = #)";

function page(path: string, width: number): SsrMarkup {
	publishWindow(width, 0);
	if (path === "") { return renderToMarkup(element(<Home />)); }
	if (atPlayground(path)) { return renderToMarkup(element(<Playground />)); }
	const site = createDocsSite(createRequestRoutingHistory(path));
	if (!site.ok) { return { html: "", css: "", head: "" }; }
	const docs = site.value;
	try {
		return renderToMarkup(element(<Docs site={docs} />));
	} finally {
		docs.dispose();
	}
}

function notFoundPage(): SsrMarkup {
	return renderToMarkup(element(<NotFound />));
}

serve(page, notFoundPage);
