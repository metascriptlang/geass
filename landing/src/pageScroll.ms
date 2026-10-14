import { createSignal } from "../../../neon/src/core/signal";

extern function whenScrolled(report: (share: number) => void): void
	from "((report) => { if (typeof document === 'undefined') { return; } const read = () => { const range = document.documentElement.scrollHeight - innerHeight; report(range > 0 ? scrollY / range : 0); }; addEventListener('scroll', read, { passive: true }); read(); })(#)";

const [share, setShare] = createSignal<number>(0);
whenScrolled((value: number): void => { setShare(value); });

export const pageShare = share;

export function unit(value: number): number {
	return Math.min(1, Math.max(0, value));
}

export function shareFrom(start: number, span: number): number {
	return unit((share() - start) / span);
}
