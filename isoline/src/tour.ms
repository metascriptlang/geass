import { Accessor, createSignal } from "../../../neon/src/core/signal";
import { onSettled } from "../../../neon/src/core/effect";

export function createTour(stops: number, every: number): [Accessor<number>, (at: number) => void] {
	const [shown, setShown] = createSignal<number>(0);
	let held = false;
	onSettled((): (() => void) | null => {
		let running = true;
		const step = (): void => {
			if (!running || held) { return; }
			setShown((shown() + 1) % stops);
			setTimeout(step, every);
		};
		setTimeout(step, every);
		return (): void => { running = false; };
	});
	return [shown, (at: number): void => {
		held = true;
		setShown(at);
	}];
}
