import { gfxSetup, fbWidth, fbHeight } from "../../void/src/sokol/gpu";
import { Vec4, vec3, eulerQuat } from "../../void/src/math/math3d";
import { RenderState } from "../../void/src/gpu/state";
import {
	MATERIAL_UNIFORM_LENGTH,
	VERTEX_UNIFORM_LENGTH,
	LIGHT_UNIFORM_LENGTH,
} from "../../void/src/void3d/gpu3d";
import { DrawContext, DrawItem } from "../../void/src/void3d/draw";
import { GltfData, GltfError, loadGlb } from "../../void/src/void3d/gltf";
import {
	GltfAssets,
	GltfSceneError,
	addGltfAssets,
	addGltfNodes,
	closeGltfAssets,
} from "../../void/src/void3d/gltfScene";
import {
	Transform3D,
	Scene3D,
	NodeId3D,
	LightError,
	SceneError,
	LightKind,
	addGroup,
	addLightNode,
	remove,
	setLocal,
	findByName,
	setAmbient,
	setLightPower,
	refresh,
	collectLights,
	NO_NODE_ID,
} from "../../void/src/void3d/scene";
import { setExposure } from "../../void/src/void3d/renderer";
import { Camera3D, ProjectionKind, CameraView, CameraError } from "../../void/src/void3d/camera";
import {
	AnimationError,
	Interpolation,
	ObjectAnimation,
	addTrack,
	bindTracks,
	setFrame,
	syncPose,
} from "../../void/src/void3d/animation";
import {
	ForwardRenderer,
	ForwardError,
	FORWARD_OUTLINE_UNIFORM_LENGTH,
	renderFrame,
	setOutlineBlend,
	setOutlineSettings,
} from "../../void/src/void3d/forwardRenderer";

@include("../../void/src/sokol/bridge.h");
@include("./mechHost.h");
@compile("./mechHost.c");
extern function mechFileSize(name: cstring): int64;
extern function mechFileRead(name: cstring, out: Span<uint8>): int32;
extern function mechScrollProgress(): float64;
extern function mechPageProgress(): float64;
extern function mechReady(): void;
extern function mechNow(): float64;
extern function mechFetchStage(stage: int32): void;
extern function mechStageArrived(stage: int32): int32;
extern function mechTuned(name: cstring, low: float64, high: float64, preset: float64): float64;
extern function voidRun(w: int32, h: int32, init: () => void, frame: () => void): void;

struct UnfoldTrack {
	name: string;
	keys: float64[];
}

struct UnfoldClip {
	frames: int32;
	fovY: float64;
	camera: float64[];
	tracks: UnfoldTrack[];
}

struct Turning {
	node: NodeId3D;
	keys: float64[];
	beat: int32;
	rate: float32;
	swing: float32;
	step: float32;
	every: float32;
}

const MATERIAL_ROOM: int32 = 24;
const KEY_WIDTH: int32 = 7;
const CAMERA_WIDTH: int32 = 5;
const EASE: float32 = 0.12;
const INTRO_HOLD_MS: float64 = 1200.0;
const CORE_SPIN_MS: float64 = 1100.0;
const CORE_SPIN: float32 = 0.5 * (Math.PI as float32);
const OVERSHOOT: float32 = 1.70158;
const CORE_AXIS_HEIGHT: float32 = 0.52;
const STEP_SECONDS: float32 = 0.7;
const DARK_AMBIENT: float32 = 0.1;
const LIT_AMBIENT: float32 = 0.7;
const DARK_SUN: float32 = 1.15;
const LIT_SUN: float32 = 0.42;
const DARK_EXPOSURE: float32 = -0.7;
const LIT_FROM: float32 = 0.1;
const LIT_BY: float32 = 0.64;
const BEATS: int32 = 6;
const BEAT_PARTS: string[][] = [["05"], ["07", "08"], ["06"], ["09", "10", "11", "12", "13"], ["02", "04"], ["03"]];
const BEAT_FROM: float32[] = [0.185, 0.285, 0.385, 0.485, 0.585, 0.685];
const BEAT_SPAN: float32 = 0.06;
const CLOSING_FROM: float32 = 0.82;
const CLOSING_SPAN: float32 = 0.15;
const FRONT_DISTANCE: float32 = 2.4;
const FRONT_HEIGHT: float32 = 0.52;
const BEAT_FIRST_FRAME: float32[] = [51.0, 59.0, 67.0, 70.0, 73.0, 91.0];
const BEAT_LAST_FRAME: float32[] = [93.0, 99.0, 105.0, 108.0, 116.0, 122.0];
const DAYLIGHT_FROM: float64 = 0.84;
const SKETCH_MS: float64 = 900.0;
const NOT_YET: float64 = -1.0;
const FIRST_LOOK: int32 = 1;
const FULL_CORE: int32 = 2;
let SEE_THROUGH: Vec4 = { x: 0.0, y: 0.0, z: 0.0, w: 0.0 };
let context: DrawContext = DrawContext.withUniformCapacity(
	FORWARD_OUTLINE_UNIFORM_LENGTH + MATERIAL_UNIFORM_LENGTH * MATERIAL_ROOM,
);
let forward: ForwardRenderer = createForward();
let scene: Scene3D = Scene3D.create(context);
let items: Vec<DrawItem> = [];
let model: NodeId3D = NO_NODE_ID;
let core: NodeId3D = NO_NODE_ID;
let cameraBlock: Vec<float32> = new Array(VERTEX_UNIFORM_LENGTH);
let lights: Vec<float32> = new Array(LIGHT_UNIFORM_LENGTH);
let progress: float32 = 0.0;
let paged: float32 = 0.0;
let cameraKeys: float64[] = [];
let fovY: float32 = 0.5;
let readyAt: float64 = NOT_YET;
let coreSettledAt: float64 = NOT_YET;
let frames: int32 = 1;
let unfolds: Vec<ObjectAnimation> = [];
let turning: Vec<Turning> = [];
let sun: NodeId3D = NO_NODE_ID;
let sketched: float32 = 0.0;
let framedAt: float64 = NOT_YET;

function stillUnfold(): ObjectAnimation {
	return ObjectAnimation.forClock({
		frameCount: 1,
		sampling: 24.0,
		speed: 1.0,
		frame: 0.0,
		loop: false,
		pause: true,
		interpolation: Interpolation.Linear,
	});
}

function createForward(): ForwardRenderer {
	let created: Result<ForwardRenderer, ForwardError> = ForwardRenderer.create(context, SEE_THROUGH);
	if (created.ok) { return created.value; }
	unreachable;
}

function stop(message: string): void {
	console.log(`mech view: ${message}`);
	unreachable;
}

function readFile(name: cstring): uint8[] {
	const size: int64 = mechFileSize(name);
	if (size <= 0) { stop(`${name} could not be read`); }
	let bytes: uint8[] = new Array(size as int32);
	if (mechFileRead(name, bytes) == 0) { stop(`${name} was cut short`); }
	return bytes;
}

function loadUnfold(): void {
	const text: uint8[] = readFile("coreUnfold.json");
	const clip: Result<UnfoldClip, string> = JSON.parse<UnfoldClip>(text.asString());
	if (!clip.ok) { stop(`the unfold clip was refused: ${clip.error}`); unreachable; }
	frames = clip.value.frames;
	unfolds = [];
	for (let beat = 0; beat < BEATS; beat++) {
		let still: ObjectAnimation = stillUnfold();
		still.clock.frameCount = frames;
		unfolds.push(still);
	}
	if ((clip.value.camera.length as int32) != clip.value.frames * CAMERA_WIDTH) {
		stop("the camera keys do not fit the clip");
	}
	cameraKeys = clip.value.camera;
	fovY = clip.value.fovY as float32;
	for (const track of clip.value.tracks) {
		let keys: Vec<Transform3D> = [];
		for (let i = 0; i < clip.value.frames; i++) {
			const at: int32 = i * KEY_WIDTH;
			keys.push({
				position: vec3(
					track.keys[at] as float32,
					track.keys[at + 1] as float32,
					track.keys[at + 2] as float32,
				),
				rotation: {
					x: track.keys[at + 3] as float32,
					y: track.keys[at + 4] as float32,
					z: track.keys[at + 5] as float32,
					w: track.keys[at + 6] as float32,
				},
				scale: vec3(1.0, 1.0, 1.0),
			});
		}
		let added: Result<int32, AnimationError> =
			addTrack(unfolds[beatOf(track.name)], track.name, keys);
		if (!added.ok) { stop(`track ${track.name} does not fit the clip`); }
	}
	for (let beat = 0; beat < BEATS; beat++) {
		let bound: Result<int32, AnimationError> = bindTracks(unfolds[beat], scene, model);
		if (!bound.ok) { stop("an unfold track names no node of the model"); }
	}
	turning = [];
	for (const track of clip.value.tracks) {
		turn(track, "02", 0.25, 0.0, 0.0, 1.0);
		turn(track, "03", 0.0, 0.0, 1.0472, 2.6);
		turn(track, "04", -0.12, 0.0, 0.0, 1.0);
		turn(track, "06", 0.9, 0.0, 0.0, 1.0);
		turn(track, "07", 0.0, 0.7, 0.0, 1.0);
		turn(track, "08", 0.0, 0.0, -0.7854, 1.7);
		turn(track, "10", -1.2, 0.0, 0.0, 1.0);
		turn(track, "11", 1.8, 0.0, 0.0, 1.0);
		turn(track, "12", 1.8, 0.0, 0.0, 1.0);
		turn(track, "13", 1.8, 0.0, 0.0, 1.0);
	}
}

function beatOf(name: string): int32 {
	for (let beat = 0; beat < BEATS; beat++) {
		for (const part of BEAT_PARTS[beat]) {
			if (name.startsWith(part)) { return beat; }
		}
	}
	stop(`${name} belongs to no beat`);
	unreachable;
}

function eased(along: float32): float32 {
	const share: float32 = along < 0.0 ? 0.0 : along > 1.0 ? 1.0 : along;
	return share * share * (3.0 - 2.0 * share);
}

function closing(): float32 {
	return (paged - CLOSING_FROM) / CLOSING_SPAN;
}

function beatFrame(beat: int32): float32 {
	const out: float32 = eased((paged - BEAT_FROM[beat]) / BEAT_SPAN);
	const back: float32 = eased(closing() * 2.0 - ((BEATS - 1 - beat) as float32) * 0.2);
	return BEAT_FIRST_FRAME[beat]
		+ (BEAT_LAST_FRAME[beat] - BEAT_FIRST_FRAME[beat]) * out * (1.0 - back);
}

function turn(
	track: UnfoldTrack, part: string, rate: float32, swing: float32, step: float32, every: float32,
): void {
	if (!track.name.startsWith(part)) { return; }
	let node: Result<NodeId3D, SceneError> = findByName(scene, model, track.name);
	if (!node.ok) { stop(`${track.name} is not in the model`); unreachable; }
	turning.push({ node: node.value, keys: track.keys, beat: beatOf(track.name), rate, swing, step, every });
}

function keyAt(keys: float64[], frame: float32, field: int32): float32 {
	const first: int32 = frame as int32;
	const last: int32 = frames - 1;
	const second: int32 = first < last ? first + 1 : last;
	const weight: float64 = (frame - (first as float32)) as float64;
	const a: float64 = keys[first * KEY_WIDTH + field];
	const b: float64 = keys[second * KEY_WIDTH + field];
	return (a + (b - a) * weight) as float32;
}

function turned(part: Turning, seconds: float32): float32 {
	const beat: float32 = seconds / part.every;
	const whole: float32 = Math.floor(beat) as float32;
	const within: float32 = (beat - whole) * part.every / STEP_SECONDS;
	return part.rate * seconds
		+ part.swing * (Math.sin(seconds * 0.8) as float32)
		+ part.step * (whole + sprung(within as float64));
}

function cameraAt(frame: float32, field: int32): float32 {
	const first: int32 = frame as int32;
	const last: int32 = frames - 1;
	const second: int32 = first < last ? first + 1 : last;
	const weight: float64 = (frame - (first as float32)) as float64;
	const a: float64 = cameraKeys[first * CAMERA_WIDTH + field];
	const b: float64 = cameraKeys[second * CAMERA_WIDTH + field];
	return (a + (b - a) * weight) as float32;
}

function addModel(name: cstring): NodeId3D {
	const bytes: uint8[] = readFile(name);
	let data: Result<GltfData, GltfError> = loadGlb(bytes);
	if (!data.ok) { stop(`the model was refused: ${data.error.toString()}`); unreachable; }
	let assets: Result<GltfAssets, GltfSceneError> = addGltfAssets(
		context, data.value, { pass: RenderState.defaults(), block: [4.0, 0.0, 0.0, 0.0] },
	);
	if (!assets.ok) {
		stop(`the driver refused the model: ${assets.error.toString()}`);
		unreachable;
	}
	const group: NodeId3D = addGroup(scene, model, Transform3D.identity());
	let added: Result<int32, GltfSceneError> =
		addGltfNodes(scene, group, data.value, assets.value.bindings);
	if (!added.ok) { stop("the model's node did not enter the scene"); }
	closeGltfAssets(assets.value);
	return group;
}

function sprung(share: float64): float32 {
	if (share >= 1.0) { return 1.0; }
	const left: float32 = (share as float32) - 1.0;
	return 1.0 + (OVERSHOOT + 1.0) * left * left * left + OVERSHOOT * left * left;
}

function initMech(): void {
	gfxSetup();
	model = addGroup(scene, scene.rootId(), Transform3D.identity());
	mechFetchStage(FIRST_LOOK);
	sun = addLightNode(
		scene,
		scene.rootId(),
		{ ...Transform3D.identity(), rotation: eulerQuat(-0.5, 2.6, 0.0) },
		{
			kind: LightKind.Directional,
			color: vec3(1.0, 1.0, 1.0),
			radius: 0.0,
			power: DARK_SUN,
			priority: 0,
		},
	);
}

function frameMech(): void {
	if (readyAt == NOT_YET) {
		const first: int32 = mechStageArrived(FIRST_LOOK);
		if (first < 0) { stop("the mech did not load"); }
		if (first == 0) { return; }
		addModel("body.glb");
		core = addModel("coreLite.glb");
		loadUnfold();
		console.log("mech view: model loaded");
		readyAt = mechNow();
		mechReady();
		mechFetchStage(FULL_CORE);
	}
	const arrived: int32 = coreSettledAt == NOT_YET ? mechStageArrived(FULL_CORE) : 0;
	if (arrived != 0) {
		if (arrived > 0) {
			remove(scene, core);
			core = addModel("coreDetail.glb");
			loadUnfold();
			console.log("mech view: detailed core loaded");
		}
		const shown: float64 = readyAt + INTRO_HOLD_MS;
		coreSettledAt = mechNow() > shown ? mechNow() : shown;
	}
	const since: float64 = coreSettledAt == NOT_YET ? 0.0 : mechNow() - coreSettledAt;
	const angle: float32 = CORE_SPIN * (sprung(since / CORE_SPIN_MS) - 1.0);
	setLocal(scene, core, {
		...Transform3D.identity(),
		position: vec3(
			CORE_AXIS_HEIGHT * (Math.sin(angle) as float32),
			CORE_AXIS_HEIGHT * (1.0 - (Math.cos(angle) as float32)),
			0.0,
		),
		rotation: eulerQuat(0.0, 0.0, angle),
	});
	const page: float64 = mechPageProgress();
	const now: float64 = mechNow();
	const stroke: float32 = (framedAt == NOT_YET ? 0.0 : (now - framedAt) / SKETCH_MS) as float32;
	const inked: float32 = sketched + (page > DAYLIGHT_FROM ? stroke : -stroke);
	sketched = inked < 0.0 ? 0.0 : inked > 1.0 ? 1.0 : inked;
	framedAt = now;
	const shade: float32 = mechTuned("line shade", 0.02, 0.98, 0.35) as float32;
	setOutlineSettings(forward, {
		color: {
			x: shade + 0.01,
			y: shade,
			z: shade - 0.01,
			w: mechTuned("line strength", 0.0, 1.0, 1.0) as float32,
		},
		pixelWidth: mechTuned("line width, px", 1.0, 6.0, 2.0) as float32,
		depthThreshold: Math.pow(10.0, mechTuned("depth edge, 10^x", -5.0, -1.0, -3.56)) as float32,
		normalThreshold: mechTuned("crease, normal dot", 0.0, 1.0, 0.8) as float32,
	});
	setOutlineBlend(forward, Math.max(eased(sketched), mechTuned("drawn (0 follows scroll)", 0.0, 1.0, 0.0) as float32));
	progress += ((mechScrollProgress() as float32) - progress) * EASE;
	paged += ((page as float32) - paged) * EASE;
	const frame: float32 = progress * ((frames - 1) as float32);
	for (let beat = 0; beat < BEATS; beat++) {
		let framed: Result<float64, AnimationError> =
			setFrame(unfolds[beat].clock, beatFrame(beat) as float64);
		if (!framed.ok) { unreachable; }
		let posed: Result<int32, AnimationError> = syncPose(unfolds[beat], scene);
		if (!posed.ok) { stop("the unfold pose was refused"); }
	}
	const along: float32 = (progress - LIT_FROM) / (LIT_BY - LIT_FROM);
	const share: float32 = along < 0.0 ? 0.0 : along > 1.0 ? 1.0 : along;
	const lit: float32 = share * share * (3.0 - 2.0 * share);
	const ambient: float32 = DARK_AMBIENT + (LIT_AMBIENT - DARK_AMBIENT) * lit;
	setAmbient(scene, vec3(ambient, ambient, ambient + 0.02));
	setLightPower(scene, sun, DARK_SUN + (LIT_SUN - DARK_SUN) * lit);
	setExposure(forward.core, DARK_EXPOSURE * (1.0 - lit));
	const seconds: float32 = ((mechNow() - readyAt) / 1000.0) as float32;
	for (const part of turning) {
		const at: float32 = beatFrame(part.beat);
		const z: float32 = keyAt(part.keys, at, 5);
		const w: float32 = keyAt(part.keys, at, 6);
		const unfolded: float32 = 2.0 * (Math.atan2(z, w) as float32);
		setLocal(scene, part.node, {
			...Transform3D.identity(),
			position: vec3(keyAt(part.keys, at, 0), keyAt(part.keys, at, 1), keyAt(part.keys, at, 2)),
			rotation: eulerQuat(0.0, 0.0, unfolded + turned(part, seconds)),
		});
	}
	refresh(scene, items);
	let collected: Result<int32, LightError> = collectLights(scene, lights);
	if (!collected.ok) { unreachable; }
	const front: float32 = eased(closing());
	const swung: float32 = cameraAt(frame, 3);
	const yaw: float32 = swung * (1.0 - front);
	const reach: float32 = cameraAt(frame, 0) / (Math.sin(swung) as float32);
	const pivot: float32 = cameraAt(frame, 2) - reach * (Math.cos(swung) as float32);
	const distance: float32 = reach + (FRONT_DISTANCE - reach) * front;
	let camera: Camera3D = {
		position: front <= 0.0
			? vec3(cameraAt(frame, 0), cameraAt(frame, 1), cameraAt(frame, 2))
			: vec3(
				distance * (Math.sin(yaw) as float32),
				cameraAt(frame, 1) + (FRONT_HEIGHT - cameraAt(frame, 1)) * front,
				pivot * (1.0 - front) + distance * (Math.cos(yaw) as float32),
			),
		yaw: yaw,
		pitch: cameraAt(frame, 4),
		nearPlane: 0.1,
		farPlane: 20.0,
		projection: { kind: ProjectionKind.Perspective, fovY: fovY },
	};
	let view: Result<CameraView, CameraError> = camera.resolve(fbWidth(), fbHeight());
	if (!view.ok) { return; }
	view.value.writeCameraBlock(cameraBlock);
	let drawn: Result<int32, ForwardError> =
		renderFrame(forward, items, cameraBlock, lights, fbWidth(), fbHeight());
	if (!drawn.ok) { stop(`the frame was refused: ${drawn.error.toString()}`); }
}

function main(): int32 {
	voidRun(960, 960, initMech, frameMech);
	return 0;
}

main();
