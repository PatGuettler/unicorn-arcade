"""Render the six authored unicorn GLBs into Marketplace-ready transparent PNGs.

Run from the repository root:
  blender --background --python tools/render_unicorn_marketplace_portraits.py
"""

from pathlib import Path
import math
import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "godot" / "assets" / "characters" / "unicorns"
OUTPUT_DIR = SOURCE_DIR / "thumbnails"
MODELS = {
    "sparkle": "unicorn_sparkle_v1.glb",
    "rainbow": "unicorn_rainbow_v1.glb",
    "star": "unicorn_star_v1.glb",
    "cloud": "unicorn_cloud_v1.glb",
    "dream": "unicorn_dreamer_v1.glb",
    "mystic": "unicorn_mystic_v1.glb",
}


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.materials, bpy.data.meshes, bpy.data.cameras, bpy.data.lights):
        for block in collection:
            collection.remove(block)


def model_bounds():
    points = []
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        for corner in obj.bound_box:
            points.append(obj.matrix_world @ Vector(corner))
    if not points:
        raise RuntimeError("Imported GLB contains no mesh objects")
    minimum = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    maximum = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return minimum, maximum


def projected_span(camera):
    points = []
    inverse_camera = camera.matrix_world.inverted()
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        for corner in obj.bound_box:
            points.append(inverse_camera @ (obj.matrix_world @ Vector(corner)))
    return max(
        max(point.x for point in points) - min(point.x for point in points),
        max(point.y for point in points) - min(point.y for point in points),
    )


def point_camera(camera, target):
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()


def add_area(location, energy, size, target):
    data = bpy.data.lights.new("PortraitArea", "AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    light = bpy.data.objects.new("PortraitArea", data)
    bpy.context.collection.objects.link(light)
    light.location = location
    light.rotation_euler = (target - light.location).to_track_quat("-Z", "Y").to_euler()


def render_portrait(model_id, source_path, output_path):
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=str(source_path))
    minimum, maximum = model_bounds()
    center = (minimum + maximum) * 0.5
    span = maximum - minimum
    largest = max(span.x, span.y, span.z)
    target = Vector((center.x, center.y, minimum.z + span.z * 0.54))

    camera_data = bpy.data.cameras.new("MarketplacePortraitCamera")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = largest * 1.42
    camera = bpy.data.objects.new("MarketplacePortraitCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = target + Vector((-largest * 2.25, -largest * 2.75, largest * 1.35))
    point_camera(camera, target)

    # Fit the actual camera-plane silhouette instead of the largest world axis.
    # This fills a 112px card portrait while retaining a 11% safety margin for
    # horns, hooves, tails, and Mystic's wing silhouette.
    camera_data.ortho_scale = projected_span(camera) / 0.78
    bpy.context.scene.camera = camera

    add_area(target + Vector((-largest * 1.7, -largest * 1.8, largest * 2.4)), 1200, largest * 2.1, target)
    add_area(target + Vector((largest * 2.0, -largest * 0.5, largest * 1.2)), 800, largest * 1.7, target)
    add_area(target + Vector((largest * 0.2, largest * 2.0, largest * 1.8)), 1000, largest * 1.8, target)

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.resolution_percentage = 100
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.render.filepath = str(output_path)
    bpy.ops.render.render(write_still=True)


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for model_id, filename in MODELS.items():
        render_portrait(model_id, SOURCE_DIR / filename, OUTPUT_DIR / (model_id + ".png"))


if __name__ == "__main__":
    main()
