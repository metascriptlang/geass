import { Routes, createRoutes } from "../../../neon/src/navigation/router";
import { Docs, DocsArticle, knownPage } from "./docs";
import { Home } from "./home";
import { NotFound } from "./notFound";
import { Playground } from "./playground";

export const routes: Routes = createRoutes([
	{ path: "/", component: Home },
	{ path: "/playground", component: Playground },
	{ path: "/docs", layout: Docs, children: [
		{ path: "/", component: DocsArticle },
		{ path: "/:page", component: DocsArticle, guard: knownPage },
	] },
	{ path: "*", status: 404, component: NotFound },
]);
