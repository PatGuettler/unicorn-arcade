import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def connected_component_count(mesh):
    vertex_count = len(mesh.vertices)
    if vertex_count == 0:
        return 0
    parent = list(range(vertex_count))

    def find(index):
        while parent[index] != index:
            parent[index] = parent[parent[index]]
            index = parent[index]
        return index

    def union(a, b):
        root_a = find(a)
        root_b = find(b)
        if root_a != root_b:
            parent[root_b] = root_a

    for edge in mesh.edges:
        union(edge.vertices[0], edge.vertices[1])
    return len({find(index) for index in range(vertex_count)})


def world_bounds(obj):
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    minimum = Vector((min(point.x for point in points), min(point.y for point in points), min(point.z for point in points)))
    maximum = Vector((max(point.x for point in points), max(point.y for point in points), max(point.z for point in points)))
    return minimum, maximum


def vec(value):
    return [round(float(component), 6) for component in value]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    script_args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    args = parser.parse_args(script_args)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    result = bpy.ops.import_scene.gltf(filepath=str(Path(args.input).resolve()))
    if "FINISHED" not in result:
        raise RuntimeError(f"GLB import failed: {result}")

    meshes = []
    scene_min = Vector((math.inf, math.inf, math.inf))
    scene_max = Vector((-math.inf, -math.inf, -math.inf))
    for obj in sorted((item for item in bpy.context.scene.objects if item.type == "MESH"), key=lambda item: item.name):
        minimum, maximum = world_bounds(obj)
        scene_min.x = min(scene_min.x, minimum.x)
        scene_min.y = min(scene_min.y, minimum.y)
        scene_min.z = min(scene_min.z, minimum.z)
        scene_max.x = max(scene_max.x, maximum.x)
        scene_max.y = max(scene_max.y, maximum.y)
        scene_max.z = max(scene_max.z, maximum.z)
        meshes.append({
            "name": obj.name,
            "mesh": obj.data.name,
            "vertices": len(obj.data.vertices),
            "edges": len(obj.data.edges),
            "polygons": len(obj.data.polygons),
            "loose_components": connected_component_count(obj.data),
            "location": vec(obj.location),
            "dimensions": vec(obj.dimensions),
            "bounds_min": vec(minimum),
            "bounds_max": vec(maximum),
            "materials": [slot.material.name if slot.material else None for slot in obj.material_slots],
        })

    report = {
        "input": str(Path(args.input).resolve()),
        "scene_object_count": len(bpy.context.scene.objects),
        "mesh_object_count": len(meshes),
        "scene_bounds_min": vec(scene_min) if meshes else None,
        "scene_bounds_max": vec(scene_max) if meshes else None,
        "scene_dimensions": vec(scene_max - scene_min) if meshes else None,
        "materials": sorted(material.name for material in bpy.data.materials),
        "images": sorted(({
            "name": image.name,
            "size": [int(image.size[0]), int(image.size[1])],
            "packed_bytes": int(image.packed_file.size) if image.packed_file else 0,
        } for image in bpy.data.images), key=lambda item: item["name"]),
        "meshes": meshes,
    }
    Path(args.output).write_text(json.dumps(report, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
