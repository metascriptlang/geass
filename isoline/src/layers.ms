import { Accessor } from "../../../neon/src/core/signal";
import { For } from "../../../neon/src/macros/ui/flow";
import { G, Polygon, Svg } from "../../../neon/src/components/svg/elements";
import { NeonNode } from "../../../neon/src/render/node";
import { Bounds, Vec3, boundsOf, points } from "./iso";

const CELL = 12;
const DEPTH = 48;
const THICK = 6;
const GAP = 10;
const LIFT = 10;
const STROKE = 0.9;
const RAISED = `translate(0 ${-LIFT})`;

export interface LayersPalette {
	plate: string;
	line: string;
}

export interface LayersProps {
	groups: int32[];
	columns: int32;
	tones: string[];
	lit: Accessor<number>;
	palette: LayersPalette;
	label: string;
}

struct Face {
	group: int32;
	shade: number;
	corners: number[];
}

struct Layer {
	groups: int32[];
	faces: Face[];
}

const HEX = "0123456789abcdef";

function channel(hex: string, at: int32): number {
	const digits = hex.toLowerCase();
	return HEX.indexOf(digits.charAt(1 + at * 2)) * 16 + HEX.indexOf(digits.charAt(2 + at * 2));
}

function mix(under: string, over: string, share: number): string {
	let out = "#";
	for (let at = 0; at < 3; at++) {
		const value = Math.round(channel(under, at) * (1 - share) + channel(over, at) * share);
		out += value.toString(16).padStart(2, "0");
	}
	return out;
}

function box(x0: number, x1: number, y0: number, y1: number, z0: number, z1: number): Vec3[] {
	return [
		{ x: x0, y: y0, z: z0 }, { x: x1, y: y0, z: z0 },
		{ x: x1, y: y1, z: z0 }, { x: x0, y: y1, z: z0 },
		{ x: x0, y: y0, z: z1 }, { x: x1, y: y0, z: z1 },
		{ x: x1, y: y1, z: z1 }, { x: x0, y: y1, z: z1 },
	];
}

function layersOf(groups: int32[], columns: int32): Layer[] {
	if (columns <= 0 || groups.length === 0) {
		throw new Error(`Layers: ${groups.length} cells in rows of ${columns} draw nothing`);
	}
	const rows = Math.ceil(groups.length / columns);
	const layers: Layer[] = [];
	for (let row = rows - 1; row >= 0; row--) {
		const z = (rows - 1 - row) * (THICK + GAP);
		const cells = groups.slice(row * columns, Math.min(groups.length, (row + 1) * columns));
		const faces: Face[] = [];
		for (let at = 0; at < cells.length; at++) {
			const x0 = at * CELL;
			const x1 = x0 + CELL;
			faces.push({ group: cells[at], shade: 0.32, corners: points([
				{ x: x0, y: 0, z: z + THICK }, { x: x1, y: 0, z: z + THICK },
				{ x: x1, y: DEPTH, z: z + THICK }, { x: x0, y: DEPTH, z: z + THICK },
			]) });
			faces.push({ group: cells[at], shade: 0.2, corners: points([
				{ x: x0, y: DEPTH, z }, { x: x1, y: DEPTH, z },
				{ x: x1, y: DEPTH, z: z + THICK }, { x: x0, y: DEPTH, z: z + THICK },
			]) });
		}
		const end = cells.length * CELL;
		faces.push({ group: cells[cells.length - 1], shade: 0.12, corners: points([
			{ x: end, y: 0, z }, { x: end, y: DEPTH, z },
			{ x: end, y: DEPTH, z: z + THICK }, { x: end, y: 0, z: z + THICK },
		]) });
		layers.push({ groups: cells, faces });
	}
	return layers;
}

function viewOf(cells: number, columns: number): Bounds {
	const rows = Math.ceil(cells / columns);
	return boundsOf(box(0, columns * CELL, 0, DEPTH, 0, rows * (THICK + GAP) - GAP + LIFT), 2);
}

export function layersHeight(cells: number, columns: number): number {
	const view = viewOf(cells, columns);
	return view.bottom - view.top;
}

function fillOf(props: LayersProps, face: Face): string {
	return mix(props.palette.plate, props.tones[face.group], face.shade);
}

export function Layers(props: LayersProps): NeonNode {
	const layers = layersOf(props.groups, props.columns);
	const view = viewOf(props.groups.length, props.columns);
	const width = view.right - view.left;
	const height = view.bottom - view.top;
	const shown = (face: Face): boolean => props.lit() === face.group;
	return <Svg
		width={width}
		height={height}
		viewBox={`${view.left} ${view.top} ${width} ${height}`}
		accessibilityLabel={props.label}
	>
		<For each={layers}>
			{(layer: Layer): NeonNode => <G
				transform={layer.groups.includes(props.lit() as int32) ? RAISED : "translate(0 0)"}
			>
				<For each={layer.faces}>
					{(face: Face): NeonNode => <Polygon
						points={face.corners}
						fill={shown(face) ? fillOf(props, face) : props.palette.plate}
						stroke={shown(face) ? props.tones[face.group] : props.palette.line}
						strokeWidth={STROKE}
						strokeLinejoin="round"
					/>}
				</For>
			</G>}
		</For>
	</Svg>;
}
