"""Packs a Wavefront OBJ and its base colour image into the GLB subset void3d's loader reads:
one buffer, float attributes, uint16 indices, one primitive, one embedded image.

Run: python3 objToGlb.py model.obj basecolor.jpg out.glb
"""

import json
import struct
import sys


def read_obj(path):
    positions, uvs, normals, corners, order, indices = [], [], [], {}, [], []
    with open(path) as source:
        for line in source:
            parts = line.split()
            if not parts:
                continue
            if parts[0] == "v":
                positions.append(tuple(float(x) for x in parts[1:4]))
            elif parts[0] == "vt":
                uvs.append((float(parts[1]), 1.0 - float(parts[2])))
            elif parts[0] == "vn":
                normals.append(tuple(float(x) for x in parts[1:4]))
            elif parts[0] == "f":
                face = []
                for corner in parts[1:]:
                    if corner not in corners:
                        corners[corner] = len(order)
                        order.append(tuple(int(i) - 1 for i in corner.split("/")))
                    face.append(corners[corner])
                for i in range(1, len(face) - 1):
                    indices += [face[0], face[i], face[i + 1]]
    if len(order) > 65536:
        sys.exit("%d vertices do not fit uint16 indices" % len(order))
    return ([positions[p] for p, _, _ in order], [normals[n] for _, _, n in order],
            [uvs[t] for _, t, _ in order], indices)


def main():
    obj, image_path, out_path = sys.argv[1:4]
    positions, normals, uvs, indices = read_obj(obj)
    data, views, accessors = bytearray(), [], []

    def view(payload, target=None):
        while len(data) % 4:
            data.append(0)
        entry = {"buffer": 0, "byteOffset": len(data), "byteLength": len(payload)}
        if target is not None:
            entry["target"] = target
        views.append(entry)
        data.extend(payload)
        return len(views) - 1

    def floats(rows, kind):
        flat = [v for row in rows for v in row]
        accessor = {"bufferView": view(struct.pack("<%df" % len(flat), *flat), 34962),
                    "componentType": 5126, "count": len(rows), "type": kind}
        if kind == "VEC3":
            accessor["min"] = [min(r[i] for r in rows) for i in range(3)]
            accessor["max"] = [max(r[i] for r in rows) for i in range(3)]
        accessors.append(accessor)
        return len(accessors) - 1

    attributes = {"POSITION": floats(positions, "VEC3"), "NORMAL": floats(normals, "VEC3"),
                  "TEXCOORD_0": floats(uvs, "VEC2")}
    accessors.append({"bufferView": view(struct.pack("<%dH" % len(indices), *indices), 34963),
                      "componentType": 5123, "count": len(indices), "type": "SCALAR"})
    with open(image_path, "rb") as image:
        image_view = view(image.read())
    while len(data) % 4:
        data.append(0)
    document = {
        "asset": {"version": "2.0", "generator": "objToGlb.py"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": "mech", "mesh": 0}],
        "meshes": [{"primitives": [{"attributes": attributes, "indices": len(accessors) - 1,
                                    "material": 0}]}],
        "materials": [{"name": "basecolor", "pbrMetallicRoughness": {
            "baseColorTexture": {"index": 0}, "metallicFactor": 0.0}}],
        "textures": [{"source": 0, "sampler": 0}],
        "samplers": [{"magFilter": 9729, "minFilter": 9729, "wrapS": 33071, "wrapT": 33071}],
        "images": [{"bufferView": image_view, "mimeType": "image/jpeg"}],
        "accessors": accessors,
        "bufferViews": views,
        "buffers": [{"byteLength": len(data)}],
    }
    text = json.dumps(document, separators=(",", ":")).encode("utf-8")
    text += b" " * (-len(text) % 4)
    chunks = (struct.pack("<II", len(text), 0x4E4F534A) + text
              + struct.pack("<II", len(data), 0x004E4942) + bytes(data))
    with open(out_path, "wb") as out:
        out.write(struct.pack("<III", 0x46546C67, 2, 12 + len(chunks)) + chunks)
    print(out_path, 12 + len(chunks), "bytes,", len(positions), "vertices,",
          len(indices) // 3, "triangles, bounds", attributes and accessors[0]["min"],
          accessors[0]["max"])


if __name__ == "__main__":
    main()
