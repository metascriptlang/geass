import { element } from "../../../neon/src/macros/ui/element";
import { publishWindow } from "../../../neon/src/render/environment";
import { SsrMarkup, renderToMarkup } from "../../../neon/src/render/ssr";
import { createRequestRoutingHistory } from "../../../neon/src/navigation/routingHistory";
import { RouterProvider, createRouter } from "../../../neon/src/navigation/router";
import { NotFound } from "./notFound";
import { routes } from "./routes";

export interface Served {
	status: int32;
	location: string | null;
	markup: SsrMarkup;
}

export function page(path: string, width: number): Served {
	publishWindow(width, 0);
	const opened = createRouter(routes, createRequestRoutingHistory(path));
	if (!opened.ok) { return { status: 400, location: null, markup: renderToMarkup(element(<NotFound />)) }; }
	const router = opened.value;
	try {
		const response = router.response();
		if (response.location !== null) { return { status: response.status, location: response.location, markup: { html: "", css: "", head: "" } }; }
		return { status: response.status, location: null, markup: renderToMarkup(element(<RouterProvider router={router} />)) };
	} finally {
		router.dispose();
	}
}
