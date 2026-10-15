import { accessor } from "../../../neon/src/core/signal";
import { useWindowScrollPosition, useWindowScrollRange } from "../../../neon/src/api/pageScroll";

const position = useWindowScrollPosition();
const range = useWindowScrollRange();

export const pageShare = accessor((): number => range().y > 0 ? position().y / range().y : 0);

export function unit(value: number): number {
	return Math.min(1, Math.max(0, value));
}

export function shareFrom(start: number, span: number): number {
	return unit((pageShare() - start) / span);
}
