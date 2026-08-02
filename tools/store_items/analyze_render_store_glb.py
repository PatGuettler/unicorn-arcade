import argparse
import json
import math
import sys
from collections import defaultdict
from pathlib import Path

import bpy
from mathutils import Vector


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output-dir", required=True)
    script_args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    return parser.parse_args(script_args)


def world_bounds(objects):
    points = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    minimum = Vector(tuple(min(point[i] for point in points) for i in range(3)))
    maximum = Vector(tuple(max(point[i] for point in points) for i in range(3)))
    return minimum, maximum


def component_report(obj):
    mesh = obj.data
    parent = list(range(len(mesh.vertices)))

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

    groups = defaultdict(list)
    for vertex in mesh.vertices:
        groups[find(vertex.index)].append(vertex.index)

    reports = []
    for indices in groups.values():
        coords = [obj.matrix_world @ mesh.vertices[index].co for index in indices]
        minimum = Vector(tuple(min(point[i] for point in coords) for i in range(3)))
        maximum = Vector(tuple(max(point[i] for point in coords) for i in range(3)))
        center = (minimum + maximum) * 0.5
        reports.append({
            "vertex_count": len(indices),
            "center": [round(float(v), 6) for v in center],
            "bounds_min": [round(float(v), 6) for v in minimum],
            "bounds_max": [round(float(v), 6) for v in maximum],
            "dimensions": [round(float(v), 6) for v in maximum - minimum],
        })
    reports.sort(key=lambda item: item["vertex_count"], reverse=True)
    return reports


def add_area_light(name, location, energy, size, target):
    data = bpy.data.lights.new(name=name, type="AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    light = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(light)
    light.location = location
    light.rotation_euler = (target - light.location).to_track_quat("-Z", "Y").to_euler()


def render_view(scene, camera, location, target, path, orthographic_scale):
    camera.location = location
    camera.rotation_euler = (target - location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = orthographic_scale
    scene.render.filepath = str(path)
    scene.render.film_transparent = False
    bpy.ops.render.render(write_still=True)


def main():
    args = parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(Path(args.input).resolve()))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("No meshes imported")

    minimum, maximum = world_bounds(meshes)
    center = (minimum + maximum) * 0.5
    dimensions = maximum - minimum

    reports = []
    for obj in meshes:
        reports.extend(component_report(obj))
    (output_dir / "components.json").write_text(json.dumps({
        "component_count": len(reports),
        "components": reports,
    }, indent=2), encoding="utf-8")

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1536
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    if scene.world is None:
        scene.world = bpy.data.worlds.new("InspectionWorld")
    scene.world.color = (1.0, 1.0, 1.0)
    scene.view_settings.look = "AgX - Medium High Contrast"

    camera_data = bpy.data.cameras.new("InspectionCamera")
    camera = bpy.data.objects.new("InspectionCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera

    radius = max(dimensions) * 2.4
    add_area_light("Key", center + Vector((-radius * 0.7, -radius, radius)), 1400, radius, center)
    add_area_light("Fill", center + Vector((radius, -radius * 0.5, radius * 0.3)), 900, radius, center)
    add_area_light("Rim", center + Vector((0, radius, radius)), 1100, radius, center)

    scale = max(dimensions.z * 1.18, dimensions.x / 1.5 * 1.18)
    render_view(scene, camera, center + Vector((0, -radius, 0)), center, output_dir / "front.png", scale)
    render_view(scene, camera, center + Vector((radius * 0.55, -radius, radius * 0.25)), center, output_dir / "angle.png", scale * 1.1)
    render_view(scene, camera, center + Vector((0, radius, 0)), center, output_dir / "rear.png", scale)


if __name__ == "__main__":
    main()
