import { Accessor } from "../../../../neon/src/core/signal";
import { Head } from "../../../../neon/src/render/head";
import { NeonNode } from "../../../../neon/src/render/node";

const SITE = "https://geass.metascriptlang.org";

export function PageTitle(props: { title: string }): NeonNode {
	return <Head>
		<title>{props.title}</title>
		<meta property="og:title" content={props.title} />
	</Head>;
}

export function PageAbout(props: { about: string }): NeonNode {
	return <Head>
		<meta name="description" content={props.about} />
		<meta property="og:description" content={props.about} />
	</Head>;
}

export function PagePlace(props: { path: Accessor<string> }): NeonNode {
	return <Head>
		<link rel="canonical" href={SITE + props.path()} />
		<meta property="og:url" content={SITE + props.path()} />
		<meta property="og:type" content="website" />
		<meta name="twitter:card" content="summary" />
	</Head>;
}

export function PageHead(props: { about: string; path: Accessor<string> }): NeonNode {
	return <>
		<PageAbout about={props.about} />
		<PagePlace path={props.path} />
	</>;
}
