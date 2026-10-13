"""Exports the mech or its chest core for mechView.ms, as <name>.glb in the subset void3d's loader
reads: one primitive per mesh, no emission, each core group joined into meshes under 65536
vertices with its materials' colours in COLOR_0, because the driver's buffer pool holds 128
buffers. A ratio is the share of the core's triangles kept; a core export also writes
coreUnfold.json, the scroll timeline's keys per group and for the camera.

Run: Blender -b ../assets/gundamRecessedCore.blend -P exportCore.py -- <name> <body | ratio>
"""

import json
import math
import struct
import sys
from pathlib import Path

import bpy
import numpy

SCROLL_FRAMES = (1, 128)
SHARP_ANGLE = math.radians(30)
NAME, WHAT = sys.argv[-2:]
RATIO = 1.0 if WHAT == "body" else float(WHAT)
TEXTURE_SIDE = 2048
BODY_GAMMA, BODY_LIFT = 0.7, 0.1
MECH = "futuristic+mecha+3d+model"
here = Path(__file__).parent
scene = bpy.context.scene

for material in bpy.data.materials:
    if not material.node_tree:
        continue
    for node in material.node_tree.nodes:
        if node.type != "BSDF_PRINCIPLED":
            continue
        strength = node.inputs["Emission Strength"]
        glow = node.inputs["Emission Color"]
        if strength.default_value > 0 and max(glow.default_value[:3]) > 0 and not glow.is_linked:
            node.inputs["Base Color"].default_value = glow.default_value
            strength.default_value = 0

bpy.ops.object.select_all(action="DESELECT")
mech = bpy.data.objects[MECH]
bpy.context.view_layer.objects.active = mech
mech.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.separate(type="MATERIAL")
bpy.ops.object.mode_set(mode="OBJECT")

def base_colour(material):
    shader = next(n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    return tuple(shader.inputs["Base Color"].default_value)


def split_vertices(mesh):
    return len({(loop.vertex_index, tuple(round(c, 4) for c in normal.vector))
                for loop, normal in zip(mesh.loops, mesh.corner_normals)})


def crease(mesh):
    imported = mesh.attributes.get("custom_normal")
    if imported:
        mesh.attributes.remove(imported)
    mesh.polygons.foreach_set("use_smooth", [True] * len(mesh.polygons))
    mesh.set_sharp_from_angle(angle=SHARP_ANGLE)


paint = bpy.data.materials.new("Geass | painted")
core = bpy.data.objects["GEASS_CORE"]
joined = []
for group in core.children:
    parts = [child for child in group.children if child.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.hide_set(False)
        part.select_set(True)
        part.modifiers.new("kept", "DECIMATE").ratio = RATIO
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.convert(target="MESH")
    chunks, room = [], 0
    for part in parts:
        mesh = part.data
        crease(mesh)
        colours = mesh.color_attributes.new("paint", "FLOAT_COLOR", "CORNER")
        shades = [base_colour(slot.material) for slot in part.material_slots]
        for polygon in mesh.polygons:
            for loop in polygon.loop_indices:
                colours.data[loop].color = shades[polygon.material_index]
        mesh.color_attributes.active_color = colours
        mesh.materials.clear()
        mesh.materials.append(paint)
        count = split_vertices(mesh)
        if not chunks or room + count > 65000:
            chunks.append([])
            room = 0
        chunks[-1].append(part)
        room += count
    for chunk in chunks:
        bpy.ops.object.select_all(action="DESELECT")
        for part in chunk:
            part.select_set(True)
        bpy.context.view_layer.objects.active = chunk[0]
        if len(chunk) > 1:
            bpy.ops.object.join()
        joined.append(chunk[0])

bpy.ops.object.select_all(action="DESELECT")
if WHAT == "body":
    for piece in [o for o in scene.objects if o.type == "MESH" and o.name.startswith(MECH)]:
        crease(piece.data)
        piece.select_set(True)
    for image in bpy.data.images:
        if max(image.size) > TEXTURE_SIDE:
            image.scale(TEXTURE_SIDE, TEXTURE_SIDE)
        if not image.size[0]:
            continue
        pixels = numpy.empty(image.size[0] * image.size[1] * 4, dtype=numpy.float32)
        image.pixels.foreach_get(pixels)
        colour = pixels.reshape(-1, 4)[:, :3]
        colour[:] = BODY_LIFT + (1.0 - BODY_LIFT) * colour ** BODY_GAMMA
        image.pixels.foreach_set(pixels)
else:
    for piece in [core, *core.children, *joined]:
        piece.select_set(True)

camera_keys = []
for frame in range(SCROLL_FRAMES[0], SCROLL_FRAMES[1] + 1):
    scene.frame_set(frame)
    matrix = scene.camera.matrix_world
    eye, look = matrix.translation, -matrix.col[2].xyz
    camera_keys += [eye.x, eye.z, -eye.y, math.atan2(-look.x, look.y), -math.asin(look.z)]
scene.frame_set(SCROLL_FRAMES[0])
scene.frame_start, scene.frame_end = SCROLL_FRAMES
out = here / (NAME + ".glb")
bpy.ops.export_scene.gltf(
    filepath=str(out), export_format="GLB", use_selection=True, export_apply=True,
    export_animations=True, export_animation_mode="SCENE", export_force_sampling=True,
    export_frame_range=True, export_vertex_color="ACTIVE", export_all_vertex_colors=False,
    export_image_format="JPEG", export_image_quality=80, export_cameras=False, export_lights=False, export_yup=True)

raw = out.read_bytes()
json_length = struct.unpack_from("<I", raw, 12)[0]
document = json.loads(raw[20:20 + json_length])
binary = raw[20 + json_length + 8:]
assert not document.get("extensionsRequired"), document.get("extensionsRequired")
assert all(len(mesh["primitives"]) == 1 for mesh in document["meshes"])
assert not any("emissiveFactor" in material for material in document["materials"])


def floats(accessor_index, width):
    accessor = document["accessors"][accessor_index]
    view = document["bufferViews"][accessor["bufferView"]]
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    values = struct.unpack_from("<%df" % (accessor["count"] * width), binary, start)
    return [values[i:i + width] for i in range(0, len(values), width)]


frame_count = SCROLL_FRAMES[1] - SCROLL_FRAMES[0] + 1
channels = {}
for animation in document.get("animations", []):
    for channel in animation["channels"]:
        sampler = animation["samplers"][channel["sampler"]]
        keys = floats(sampler["output"], 4 if channel["target"]["path"] == "rotation" else 3)
        assert len(keys) == frame_count, (animation["name"], len(keys))
        channels.setdefault(channel["target"]["node"], {})[channel["target"]["path"]] = keys

tracks = []
for index, paths in sorted(channels.items()):
    node = document["nodes"][index]
    assert "scale" not in node and set(paths) <= {"translation", "rotation"}, node["name"]
    moves = paths.get("translation") or [node.get("translation", (0, 0, 0))] * frame_count
    turns = paths.get("rotation") or [node.get("rotation", (0, 0, 0, 1))] * frame_count
    tracks.append({"name": node["name"],
                   "keys": [round(v, 5) for move, turn in zip(moves, turns) for v in (*move, *turn)]})
names = [node.get("name") for node in document["nodes"]]
assert all(names.count(track["name"]) == 1 for track in tracks)
if tracks:
    (here / "coreUnfold.json").write_text(
        json.dumps({"frames": frame_count, "fovY": round(scene.camera.data.angle_y, 5),
                    "camera": [round(v, 5) for v in camera_keys], "tracks": tracks},
                   separators=(",", ":")))

payloads = [binary[view.get("byteOffset", 0):view.get("byteOffset", 0) + view["byteLength"]]
            for view in document["bufferViews"]]
for mesh in document["meshes"]:
    index = mesh["primitives"][0]["attributes"].get("COLOR_0")
    if index is None:
        continue
    accessor = document["accessors"][index]
    assert (accessor["componentType"], accessor["type"]) == (5123, "VEC4"), accessor
    shorts = struct.unpack_from("<%dH" % (accessor["count"] * 4), payloads[accessor["bufferView"]])
    rgb = [shorts[i] / 65535 for i in range(len(shorts)) if i % 4 != 3]
    payloads[accessor["bufferView"]] = struct.pack("<%df" % len(rgb), *rgb)
    accessor.update(componentType=5126, type="VEC3")
    accessor.pop("normalized", None)
packed = bytearray()
for view, payload in zip(document["bufferViews"], payloads):
    packed.extend(b"\0" * (-len(packed) % 4))
    view.update(byteOffset=len(packed), byteLength=len(payload))
    view.pop("byteStride", None)
    packed.extend(payload)
packed.extend(b"\0" * (-len(packed) % 4))
document["buffers"][0]["byteLength"] = len(packed)
text = json.dumps(document, separators=(",", ":")).encode()
text += b" " * (-len(text) % 4)
chunks = (struct.pack("<II", len(text), 0x4E4F534A) + text
          + struct.pack("<II", len(packed), 0x004E4942) + bytes(packed))
out.write_bytes(struct.pack("<III", 0x46546C67, 2, 12 + len(chunks)) + chunks)
print("CORE_EXPORT", out.stat().st_size, "bytes,", len(document["meshes"]), "meshes,",
      sum(document["accessors"][m["primitives"][0]["attributes"]["POSITION"]]["count"]
          for m in document["meshes"]), "vertices,", len(tracks), "tracks")
