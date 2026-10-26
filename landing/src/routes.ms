import { RouteSectionProps } from "../../../neon/src/navigation/route";
import { LayoutProps, RouteComponent, Routes, createRoutes } from "../../../neon/src/navigation/router";
import { publishWindow } from "../../../neon/src/render/environment";
import { lazyModule } from "../../../neon/src/render/lazy";
import { NeonNode } from "../../../neon/src/render/node";
import { getRequestEvent } from "../../../neon/src/render/serve";
import { Docs, DocsArticle, knownPage } from "./docs";
import { Home } from "./home";
import { NotFound } from "./notFound";

async function loadPlayground(): Promise<RouteComponent> {
	const m = await import("./playground");
	return m.Playground;
}

const Playground = lazyModule<RouteSectionProps<Map<string, string>, unknown>>("playground", loadPlayground);

export const PHONE = 390;
export const DESKTOP = 1440;

export function servedWidth(): number {
	const event = getRequestEvent();
	return event !== null && (event.request.headers.get("user-agent") ?? "").includes("Mobi") ? PHONE : DESKTOP;
}

export function Site(props: LayoutProps): NeonNode {
	if (getRequestEvent() !== null) { publishWindow(servedWidth(), 0); }
	return props.children;
}

export const routes: Routes = createRoutes([
	{ path: "/", layout: Site, children: [
		{ path: "/", component: Home },
		{ path: "/playground", component: Playground },
		{ path: "/docs", layout: Docs, children: [
			{ path: "/", component: DocsArticle },
			{ path: "/:page", component: DocsArticle, guard: knownPage },
		] },
		{ path: "*", status: 404, component: NotFound },
	] },
]);
