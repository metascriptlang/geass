extern function voidRun(w: int32, h: int32, init: () => void, frame: () => void): void;

export function runMech(init: () => void, frame: () => void): void {
	voidRun(960, 960, init, frame);
}
