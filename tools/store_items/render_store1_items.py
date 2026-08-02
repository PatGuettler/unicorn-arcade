import argparse
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output-dir", required=True)
    script_args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    return parser.parse_args(script_args)


def bounds(obj):
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    minimum = Vector(tuple(min(point[i] for point in points) for i in range(3)))
    maximum = Vector(tuple(max(point[i] for point in points) for i in range(3)))
    return minimum, maximum


def add_light(name, location, energy, size, target):
    data = bpy.data.lights.new(name=name, type="AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    light = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(light)
    light.location = location
    light.rotation_euler = (target - location).to_track_quat("-Z", "Y").to_euler()


def main():
    args = parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(Path(args.input).resolve()))
    objects = sorted((obj for obj in bpy.context.scene.objects if obj.type == "MESH"), key=lambda obj: obj.name)

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    if scene.world is None:
        scene.world = bpy.data.worlds.new("PreviewWorld")
    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.97, 0.97, 0.97, 1.0)
    background.inputs["Strength"].default_value = 0.18
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = -0.35

    camera_data = bpy.data.cameras.new("ItemCamera")
    camera = bpy.data.objects.new("ItemCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.data.type = "ORTHO"

    for obj in objects:
        for candidate in objects:
            candidate.hide_render = candidate != obj
        minimum, maximum = bounds(obj)
        center = (minimum + maximum) * 0.5
        dimensions = maximum - minimum
        radius = max(dimensions) * 3.0
        camera.location = center + Vector((radius * 0.55, -radius, radius * 0.28))
        camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
        camera.data.ortho_scale = max(dimensions.z, dimensions.x, dimensions.y) * 1.45

        for light in [item for item in bpy.context.scene.objects if item.type == "LIGHT"]:
            bpy.data.objects.remove(light, do_unlink=True)
        add_light("Key", center + Vector((-radius, -radius, radius)), 260, radius, center)
        add_light("Fill", center + Vector((radius, -radius * 0.4, radius * 0.4)), 90, radius, center)
        add_light("Rim", center + Vector((0, radius, radius)), 150, radius, center)

        catalog_id = obj.name.removesuffix("_mesh")
        scene.render.filepath = str(output_dir / f"{catalog_id}.png")
        bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    main()
