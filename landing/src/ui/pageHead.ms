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
		<meta property="og:image" content={SITE + "/og.jpg"} />
		<meta property="og:image:width" content="1200" />
		<meta property="og:image:height" content="630" />
		<meta property="og:image:alt" content="Geass, MetaScript for Solana: the mech bust" />
		<meta name="twitter:card" content="summary_large_image" />
	</Head>;
}

export function PageHead(props: { about: string; path: Accessor<string> }): NeonNode {
	return <>
		<PageAbout about={props.about} />
		<PagePlace path={props.path} />
	</>;
}
