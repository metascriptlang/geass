const COS30 = Math.sqrt(3) / 2;

export struct Point {
	x: number;
	y: number;
}

export struct Vec3 {
	x: number;
	y: number;
	z: number;
}

export function project(at: Vec3): Point {
	return { x: (at.x - at.y) * COS30, y: (at.x + at.y) / 2 - at.z };
}

export function points(corners: Vec3[]): number[] {
	const flat: number[] = [];
	for (const corner of corners) {
		const seen = project(corner);
		flat.push(seen.x);
		flat.push(seen.y);
	}
	return flat;
}

export struct Bounds {
	left: number;
	top: number;
	right: number;
	bottom: number;
}

export function boundsOf(corners: Vec3[], margin: number): Bounds {
	const first = project(corners[0]);
	let box: Bounds = { left: first.x, top: first.y, right: first.x, bottom: first.y };
	for (const corner of corners) {
		const seen = project(corner);
		box.left = Math.min(box.left, seen.x);
		box.top = Math.min(box.top, seen.y);
		box.right = Math.max(box.right, seen.x);
		box.bottom = Math.max(box.bottom, seen.y);
	}
	return {
		left: box.left - margin,
		top: box.top - margin,
		right: box.right + margin,
		bottom: box.bottom + margin,
	};
}
