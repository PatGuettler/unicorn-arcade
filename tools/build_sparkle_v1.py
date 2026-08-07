"""Deterministic Sparkle V1 Concept Fitter builder.

Run with Blender 4.5+:
  blender --background --python tools/build_sparkle_v1.py

The builder consumes concepts/sparkle_fit_v1.json, rebuilds all geometry from
recorded controls, renders matched evidence, writes validation diagnostics,
saves the Blender source, and exports a Godot-ready GLB.
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path
from typing import Iterable

import bpy
import numpy as np
from mathutils import Vector


PROJECT_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = PROJECT_ROOT / "concepts" / "sparkle_fit_v1.json"
PREVIEW_ROOT = PROJECT_ROOT / "previews" / "sparkle_v1"
REFERENCE_ROOT = PREVIEW_ROOT / "references"
TURN_ROOT = PREVIEW_ROOT / "turntable"
ASSET_ROOT = PROJECT_ROOT / "godot" / "assets" / "characters" / "sparkle"
SOURCE_ROOT = PROJECT_ROOT / "assets-source" / "characters" / "sparkle"
BLEND_PATH = SOURCE_ROOT / "sparkle_v1.blend"
GLB_PATH = ASSET_ROOT / "sparkle_v1.glb"
VALIDATION_PATH = PREVIEW_ROOT / "validation.json"

MODEL_COLLECTION = "SparkleAsset"
PREVIEW_COLLECTION = "SparklePreview"


def load_manifest() -> dict:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def ensure_directories() -> None:
    for path in (PREVIEW_ROOT, REFERENCE_ROOT, TURN_ROOT, ASSET_ROOT, SOURCE_ROOT):
        path.mkdir(parents=True, exist_ok=True)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)
    for collection in list(bpy.data.collections):
        if collection.name != "Collection":
            bpy.data.collections.remove(collection)
    root = bpy.context.scene.collection.children.get("Collection")
    if root:
        root.name = MODEL_COLLECTION
    else:
        root = bpy.data.collections.new(MODEL_COLLECTION)
        bpy.context.scene.collection.children.link(root)


def model_collection() -> bpy.types.Collection:
    return bpy.data.collections[MODEL_COLLECTION]


def preview_collection() -> bpy.types.Collection:
    collection = bpy.data.collections.get(PREVIEW_COLLECTION)
    if collection is None:
        collection = bpy.data.collections.new(PREVIEW_COLLECTION)
        bpy.context.scene.collection.children.link(collection)
    return collection


def move_to_collection(obj: bpy.types.Object, collection: bpy.types.Collection) -> None:
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    collection.objects.link(obj)


def make_material(
    name: str,
    color: tuple[float, float, float, float],
    roughness: float = 0.78,
    metallic: float = 0.0,
) -> bpy.types.Material:
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.diffuse_color = color
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Specular IOR Level"].default_value = 0.25
    return material


def create_materials() -> dict[str, bpy.types.Material]:
    return {
        "Coat": make_material("Coat", (0.86, 0.84, 0.82, 1.0), 0.84),
        "Muzzle": make_material("Muzzle", (0.92, 0.90, 0.88, 1.0), 0.86),
        "HoofPurple": make_material("HoofPurple", (0.34, 0.20, 0.45, 1.0), 0.72),
        "EyePurple": make_material("EyePurple", (0.22, 0.10, 0.29, 1.0), 0.70),
        "InnerEar": make_material("InnerEar", (0.93, 0.48, 0.60, 1.0), 0.82),
        "ManeCyan": make_material("ManeCyan", (0.20, 0.69, 0.76, 1.0), 0.72),
        "ManePink": make_material("ManePink", (0.91, 0.36, 0.59, 1.0), 0.72),
        "ManeYellow": make_material("ManeYellow", (0.96, 0.65, 0.18, 1.0), 0.74),
        "ManePurple": make_material("ManePurple", (0.47, 0.28, 0.62, 1.0), 0.74),
        "HornGold": make_material("HornGold", (0.97, 0.62, 0.12, 1.0), 0.63),
        "StarGold": make_material("StarGold", (1.00, 0.70, 0.18, 1.0), 0.70),
        "Ground": make_material("Ground", (0.90, 0.85, 0.80, 1.0), 0.95),
    }


def smooth_mesh(obj: bpy.types.Object) -> None:
    if obj.type != "MESH":
        return
    for polygon in obj.data.polygons:
        polygon.use_smooth = True


def add_subdivision(obj: bpy.types.Object, levels: int = 1) -> None:
    modifier = obj.modifiers.new("Subdivision", "SUBSURF")
    modifier.subdivision_type = "CATMULL_CLARK"
    modifier.levels = levels
    modifier.render_levels = levels


def make_ring_mesh(
    name: str,
    sections: list[list[float]],
    material: bpy.types.Material,
    ring_segments: int = 24,
) -> bpy.types.Object:
    vertices: list[tuple[float, float, float]] = []
    faces: list[tuple[int, ...]] = []
    for y, z, radius_x, radius_z in sections:
        for index in range(ring_segments):
            angle = math.tau * index / ring_segments
            vertices.append((radius_x * math.cos(angle), y, z + radius_z * math.sin(angle)))
    for ring in range(len(sections) - 1):
        base = ring * ring_segments
        next_base = (ring + 1) * ring_segments
        for index in range(ring_segments):
            following = (index + 1) % ring_segments
            faces.append((base + index, base + following, next_base + following, next_base + index))
    first_center = len(vertices)
    vertices.append((0.0, sections[0][0], sections[0][1]))
    last_center = len(vertices)
    vertices.append((0.0, sections[-1][0], sections[-1][1]))
    for index in range(ring_segments):
        following = (index + 1) % ring_segments
        faces.append((first_center, following, index))
        end = (len(sections) - 1) * ring_segments
        faces.append((last_center, end + index, end + following))
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    model_collection().objects.link(obj)
    obj.data.materials.append(material)
    smooth_mesh(obj)
    add_subdivision(obj, 2)
    return obj


def _tube_frame(points: list[Vector], index: int) -> tuple[Vector, Vector]:
    if index == 0:
        tangent = (points[1] - points[0]).normalized()
    elif index == len(points) - 1:
        tangent = (points[-1] - points[-2]).normalized()
    else:
        tangent = (points[index + 1] - points[index - 1]).normalized()
    reference = Vector((0.0, 0.0, 1.0))
    if abs(tangent.dot(reference)) > 0.92:
        reference = Vector((0.0, 1.0, 0.0))
    normal = tangent.cross(reference).normalized()
    binormal = tangent.cross(normal).normalized()
    return normal, binormal


def make_tube(
    name: str,
    raw_points: Iterable[Iterable[float]],
    raw_radii: Iterable[float],
    material: bpy.types.Material,
    segments: int = 12,
    subdivision: int = 1,
) -> bpy.types.Object:
    points = [Vector(point) for point in raw_points]
    radii = list(raw_radii)
    if len(radii) == 1:
        radii = radii * len(points)
    vertices: list[tuple[float, float, float]] = []
    faces: list[tuple[int, ...]] = []
    for point_index, (point, radius) in enumerate(zip(points, radii)):
        normal, binormal = _tube_frame(points, point_index)
        for index in range(segments):
            angle = math.tau * index / segments
            offset = normal * math.cos(angle) * radius + binormal * math.sin(angle) * radius
            vertices.append(tuple(point + offset))
    for ring in range(len(points) - 1):
        base = ring * segments
        next_base = (ring + 1) * segments
        for index in range(segments):
            following = (index + 1) % segments
            faces.append((base + index, base + following, next_base + following, next_base + index))
    first_center = len(vertices)
    vertices.append(tuple(points[0]))
    last_center = len(vertices)
    vertices.append(tuple(points[-1]))
    for index in range(segments):
        following = (index + 1) % segments
        faces.append((first_center, following, index))
        end = (len(points) - 1) * segments
        faces.append((last_center, end + index, end + following))
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    model_collection().objects.link(obj)
    obj.data.materials.append(material)
    smooth_mesh(obj)
    if subdivision:
        add_subdivision(obj, subdivision)
    return obj


def make_ellipsoid(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    segments: int = 24,
    rings: int = 16,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    move_to_collection(obj, model_collection())
    obj.data.materials.append(material)
    smooth_mesh(obj)
    return obj


def make_rounded_box(
    name: str,
    location: tuple[float, float, float],
    dimensions: tuple[float, float, float],
    material: bpy.types.Material,
    bevel: float = 0.12,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    move_to_collection(obj, model_collection())
    obj.data.materials.append(material)
    modifier = obj.modifiers.new("SoftEdges", "BEVEL")
    modifier.width = bevel
    modifier.segments = 4
    smooth_mesh(obj)
    return obj


def make_star(
    name: str,
    x: float,
    y: float,
    z: float,
    radius: float,
    depth: float,
    material: bpy.types.Material,
) -> bpy.types.Object:
    points: list[tuple[float, float]] = []
    for index in range(10):
        angle = math.pi / 2 + index * math.pi / 5
        current = radius if index % 2 == 0 else radius * 0.46
        points.append((y + current * math.cos(angle), z + current * math.sin(angle)))
    vertices = [(x - depth / 2, py, pz) for py, pz in points]
    vertices.extend((x + depth / 2, py, pz) for py, pz in points)
    faces: list[tuple[int, ...]] = []
    faces.append(tuple(range(9, -1, -1)))
    faces.append(tuple(range(10, 20)))
    for index in range(10):
        following = (index + 1) % 10
        faces.append((index, following, following + 10, index + 10))
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    model_collection().objects.link(obj)
    obj.data.materials.append(material)
    modifier = obj.modifiers.new("StarBevel", "BEVEL")
    modifier.width = 0.018
    modifier.segments = 3
    smooth_mesh(obj)
    return obj


def make_empty(name: str, location: tuple[float, float, float], parent=None) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, None)
    model_collection().objects.link(obj)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = 0.15
    obj.location = location
    if parent:
        parent_keep_transform(obj, parent)
    return obj


def parent_keep_transform(child: bpy.types.Object, parent: bpy.types.Object) -> None:
    bpy.context.view_layer.update()
    world = child.matrix_world.copy()
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()
    child.matrix_world = world
    bpy.context.view_layer.update()


def build_sparkle(manifest: dict) -> bpy.types.Object:
    materials = create_materials()
    fit = manifest["fit"]
    root = make_empty("SparkleRoot", (0.0, 0.0, 0.0))
    root["asset_id"] = manifest["asset_id"]
    root["primary_authority"] = manifest["primary_authority"]
    root["animation_modes"] = "idle,celebrate"
    body_pivot = make_empty("Pivot_Body", (0.0, 0.1, 1.5), root)
    head_pivot = make_empty("Pivot_Head", (0.0, -0.68, 2.42), root)
    horn_pivot = make_empty("Pivot_Horn", tuple(fit["horn"]["points"][0]), head_pivot)
    tail_pivot = make_empty("Pivot_Tail", (0.0, 0.90, 1.70), root)

    body = make_ring_mesh("Body", fit["body_sections"], materials["Coat"])
    neck = make_ring_mesh("Neck", fit["neck_sections"], materials["Coat"])
    head = make_ring_mesh("Head", fit["head_sections"], materials["Coat"])
    parent_keep_transform(body, body_pivot)
    parent_keep_transform(neck, head_pivot)
    parent_keep_transform(head, head_pivot)

    for side_name, sign in (("L", -1.0), ("R", 1.0)):
        ear_location = fit["ears"]["left" if side_name == "L" else "right"]
        ear = make_ellipsoid(f"Ear_{side_name}", tuple(ear_location), tuple(fit["ears"]["scale"]), materials["Coat"])
        ear.rotation_euler.y = math.radians(-10.0 * sign)
        inner_location = (ear_location[0], ear_location[1] - 0.135, ear_location[2] + 0.01)
        inner = make_ellipsoid(f"InnerEar_{side_name}", inner_location, (0.13, 0.055, 0.34), materials["InnerEar"], 20, 12)
        parent_keep_transform(ear, head_pivot)
        parent_keep_transform(inner, head_pivot)

    for chain_name, prefix in (("front", "FrontLeg"), ("hind", "HindLeg")):
        chain = fit["legs"][chain_name]
        for side_name, sign in (("L", -1.0), ("R", 1.0)):
            points = [[abs(point[0]) * sign, point[1], point[2]] for point in chain["points"]]
            pivot = make_empty(f"Pivot_{prefix}_{side_name}", tuple(points[0]), root)
            leg = make_tube(f"{prefix}_{side_name}", points, chain["radii"], materials["Coat"], 14, 1)
            hoof = make_rounded_box(
                f"Hoof_{prefix}_{side_name}",
                (points[-1][0], chain["palm_y"], 0.15),
                (chain["palm_scale"][0] * 2, chain["palm_scale"][1] * 2, chain["palm_scale"][2] * 2),
                materials["HoofPurple"],
                0.10,
            )
            parent_keep_transform(leg, pivot)
            parent_keep_transform(hoof, pivot)

    horn = make_tube("Horn", fit["horn"]["points"], fit["horn"]["radii"], materials["HornGold"], 16, 1)
    parent_keep_transform(horn, horn_pivot)
    for index, point in enumerate(fit["horn"]["points"][:-1]):
        ridge = make_ellipsoid(
            f"HornRidge_{index + 1}",
            tuple(point),
            (fit["horn"]["radii"][index] * 1.12, fit["horn"]["radii"][index] * 0.52, 0.045),
            materials["HornGold"],
            20,
            10,
        )
        ridge.rotation_euler.x = math.radians(18)
        parent_keep_transform(ridge, horn_pivot)

    for index, clump in enumerate(fit["mane_clumps"]):
        radii = [clump["radius"], clump["radius"] * 1.05, clump["radius"] * 0.78, clump["radius"] * 0.18]
        mane = make_tube(f"Mane_{index + 1:02d}", clump["points"], radii, materials[clump["material"]], 12, 2)
        parent_keep_transform(mane, head_pivot)

    for index, clump in enumerate(fit["tail_clumps"]):
        radii = [clump["radius"], clump["radius"] * 1.08, clump["radius"] * 0.92, clump["radius"] * 0.58, clump["radius"] * 0.12]
        tail = make_tube(f"Tail_{index + 1:02d}", clump["points"], radii, materials[clump["material"]], 12, 2)
        parent_keep_transform(tail, tail_pivot)

    eye_control = fit["eye"]["location"]
    eye_y = float(eye_control[1]) - 0.015
    eye_center_x = abs(float(eye_control[0]))
    for side_name, center_x in (("L", -eye_center_x), ("R", eye_center_x)):
        eye_points = [
            (center_x - 0.17, eye_y, 2.54),
            (center_x - 0.07, eye_y - 0.01, 2.49),
            (center_x + 0.06, eye_y - 0.01, 2.49),
            (center_x + 0.16, eye_y, 2.54),
        ]
        eye = make_tube(f"Eye_{side_name}", eye_points, [0.028, 0.032, 0.032, 0.026], materials["EyePurple"], 8, 1)
        lash = make_tube(
            f"Lash_{side_name}",
            [eye_points[-1], (eye_points[-1][0] + 0.08, eye_y, 2.58)],
            [0.024, 0.010],
            materials["EyePurple"],
            8,
            1,
        )
        parent_keep_transform(eye, head_pivot)
        parent_keep_transform(lash, head_pivot)

    nostril_control = fit["nostrils"]
    nostril_location = nostril_control["location"]
    nostril_scale = tuple(nostril_control["scale"])
    for side_name, nostril_x in (("L", -abs(nostril_location[0])), ("R", abs(nostril_location[0]))):
        nostril = make_ellipsoid(f"Nostril_{side_name}", (nostril_x, nostril_location[1], nostril_location[2]), nostril_scale, materials["InnerEar"], 16, 10)
        parent_keep_transform(nostril, head_pivot)
    smile = make_tube(
        "Smile",
        [(-0.21, -1.954, 2.16), (-0.10, -1.968, 2.11), (0.06, -1.968, 2.11), (0.20, -1.954, 2.17)],
        [0.018, 0.020, 0.020, 0.012],
        materials["EyePurple"],
        8,
        1,
    )
    parent_keep_transform(smile, head_pivot)

    flank_x = max(float(section[2]) for section in fit["body_sections"]) + 0.02
    for side_name, x in (("L", -flank_x), ("R", flank_x)):
        star = make_star(f"FlankStar_{side_name}", x, 0.36, 1.58, 0.24, 0.035, materials["StarGold"])
        parent_keep_transform(star, body_pivot)
        sparkle_a = make_star(f"FlankSparkleA_{side_name}", x, 0.12, 1.78, 0.095, 0.036, materials["StarGold"])
        sparkle_b = make_star(f"FlankSparkleB_{side_name}", x, 0.60, 1.34, 0.075, 0.036, materials["StarGold"])
        parent_keep_transform(sparkle_a, body_pivot)
        parent_keep_transform(sparkle_b, body_pivot)

    return root


def setup_scene() -> tuple[bpy.types.Object, list[bpy.types.Object]]:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.world.color = (0.035, 0.035, 0.035)

    preview = preview_collection()
    ground_material = bpy.data.materials["Ground"]
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0.0, 0.0, -0.015))
    ground = bpy.context.object
    ground.name = "PreviewGround"
    move_to_collection(ground, preview)
    ground.data.materials.append(ground_material)

    lights: list[bpy.types.Object] = []
    for name, light_type, location, energy, color, size in (
        ("Key", "AREA", (4.5, -5.0, 7.0), 900.0, (1.0, 0.82, 0.72), 5.0),
        ("Fill", "AREA", (-4.0, -2.0, 4.0), 650.0, (0.66, 0.84, 1.0), 4.0),
        ("Rim", "AREA", (1.0, 5.0, 6.0), 800.0, (1.0, 0.62, 0.80), 3.0),
    ):
        data = bpy.data.lights.new(name, light_type)
        data.energy = energy
        data.color = color
        data.shape = "DISK"
        data.size = size
        obj = bpy.data.objects.new(name, data)
        preview.objects.link(obj)
        obj.location = location
        look_at(obj, Vector((0.0, -0.1, 1.5)))
        lights.append(obj)

    camera_data = bpy.data.cameras.new("ReviewCamera")
    camera = bpy.data.objects.new("ReviewCamera", camera_data)
    preview.objects.link(camera)
    scene.camera = camera
    return camera, [ground, *lights]


def look_at(obj: bpy.types.Object, target: Vector) -> None:
    direction = target - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def configure_camera(camera: bpy.types.Object, view_name: str, view: dict) -> None:
    u0, u1, v0, v1 = (float(value) for value in view["world_rect"])
    center_u = (u0 + u1) * 0.5
    center_v = (v0 + v1) * 0.5
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = v1 - v0
    if view_name == "side":
        camera.location = (8.0, center_u, center_v)
        look_at(camera, Vector((0.0, center_u, center_v)))
    elif view_name == "front":
        camera.location = (center_u, -8.0, center_v)
        look_at(camera, Vector((center_u, 0.0, center_v)))
    else:
        camera.location = (center_u, center_v, 9.0)
        camera.rotation_euler = (0.0, 0.0, math.pi)


def render_view(camera: bpy.types.Object, view_name: str, view: dict, path: Path) -> Path:
    scene = bpy.context.scene
    x0, y0, x1, y1 = view["crop"]
    scene.render.resolution_x = x1 - x0
    scene.render.resolution_y = y1 - y0
    configure_camera(camera, view_name, view)
    ground = bpy.data.objects.get("PreviewGround")
    if ground is not None:
        ground.hide_render = True
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    return path


def image_to_array(path: Path) -> np.ndarray:
    image = bpy.data.images.load(str(path), check_existing=False)
    try:
        width, height = image.size
        pixels = np.empty(width * height * 4, dtype=np.float32)
        image.pixels.foreach_get(pixels)
        return np.flipud(pixels.reshape((height, width, 4)))
    finally:
        bpy.data.images.remove(image)


def save_array(path: Path, pixels: np.ndarray) -> None:
    height, width, channels = pixels.shape
    if channels == 3:
        alpha = np.ones((height, width, 1), dtype=np.float32)
        pixels = np.concatenate((pixels, alpha), axis=2)
    image = bpy.data.images.new(path.stem, width=width, height=height, alpha=True, float_buffer=False)
    image.pixels.foreach_set(np.flipud(np.clip(pixels, 0.0, 1.0)).astype(np.float32).ravel())
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()
    bpy.data.images.remove(image)


def extract_reference_panels(manifest: dict) -> dict[str, np.ndarray]:
    source = image_to_array(PROJECT_ROOT / manifest["source_plate"])
    panels: dict[str, np.ndarray] = {}
    for view_name, view in manifest["views"].items():
        x0, y0, x1, y1 = view["crop"]
        panel = source[y0:y1, x0:x1].copy()
        output = PROJECT_ROOT / view["reference_image"]
        output.parent.mkdir(parents=True, exist_ok=True)
        save_array(output, panel)
        panels[view_name] = panel
    return panels


def largest_component(mask: np.ndarray) -> np.ndarray:
    height, width = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    best: list[tuple[int, int]] = []
    for y in range(height):
        for x in range(width):
            if not mask[y, x] or visited[y, x]:
                continue
            stack = [(y, x)]
            visited[y, x] = True
            component: list[tuple[int, int]] = []
            while stack:
                cy, cx = stack.pop()
                component.append((cy, cx))
                for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                    if 0 <= ny < height and 0 <= nx < width and mask[ny, nx] and not visited[ny, nx]:
                        visited[ny, nx] = True
                        stack.append((ny, nx))
            if len(component) > len(best):
                best = component
    result = np.zeros_like(mask, dtype=bool)
    if best:
        ys, xs = zip(*best)
        result[np.array(ys), np.array(xs)] = True
    return result


def concept_mask(panel: np.ndarray) -> np.ndarray:
    rgb = panel[:, :, :3]
    corner = np.concatenate(
        (
            rgb[12:42, 12:42].reshape(-1, 3),
            rgb[12:42, -42:-12].reshape(-1, 3),
            rgb[-42:-12, 12:42].reshape(-1, 3),
            rgb[-42:-12, -42:-12].reshape(-1, 3),
        ),
        axis=0,
    )
    background = np.median(corner, axis=0)
    distance = np.linalg.norm(rgb - background, axis=2)
    mask = distance > 0.075
    margin = 18
    mask[:margin, :] = False
    mask[-margin:, :] = False
    mask[:, :margin] = False
    mask[:, -margin:] = False
    return largest_component(mask)


def dilate(mask: np.ndarray, iterations: int) -> np.ndarray:
    result = mask.copy()
    for _ in range(iterations):
        result = result | np.roll(result, 1, 0) | np.roll(result, -1, 0) | np.roll(result, 1, 1) | np.roll(result, -1, 1)
        result[0, :] = False
        result[-1, :] = False
        result[:, 0] = False
        result[:, -1] = False
    return result


def mask_iou(a: np.ndarray, b: np.ndarray) -> float:
    union = np.logical_or(a, b).sum()
    if union == 0:
        return 0.0
    return float(np.logical_and(a, b).sum() / union)


def write_overlay_and_heatmap(
    view_name: str,
    concept: np.ndarray,
    model: np.ndarray,
    concept_shape: np.ndarray,
    model_shape: np.ndarray,
) -> None:
    model_rgb = model[:, :, :3]
    model_alpha = model[:, :, 3:4]
    overlay = concept.copy()
    overlay[:, :, :3] = overlay[:, :, :3] * (1.0 - 0.55 * model_alpha) + model_rgb * (0.55 * model_alpha)
    save_array(PREVIEW_ROOT / f"overlay_{view_name}.png", overlay)
    heatmap = np.ones((*concept_shape.shape, 4), dtype=np.float32)
    heatmap[:, :, :3] = (0.93, 0.90, 0.86)
    overlap = concept_shape & model_shape
    concept_only = concept_shape & ~model_shape
    model_only = model_shape & ~concept_shape
    heatmap[overlap, :3] = (0.20, 0.78, 0.36)
    heatmap[concept_only, :3] = (0.92, 0.18, 0.24)
    heatmap[model_only, :3] = (0.06, 0.76, 0.88)
    save_array(PREVIEW_ROOT / f"heatmap_{view_name}.png", heatmap)


def validate_current_scene() -> dict:
    manifest = load_manifest()
    ensure_directories()
    camera = bpy.data.objects.get("ReviewCamera")
    if camera is None:
        camera, _ = setup_scene()
    references = extract_reference_panels(manifest)
    metrics: dict[str, dict[str, float | bool]] = {}
    for view_name, view in manifest["views"].items():
        render_path = PREVIEW_ROOT / f"model_{view_name}.png"
        render_view(camera, view_name, view, render_path)
        model = image_to_array(render_path)
        concept = references[view_name]
        concept_shape = concept_mask(concept)
        model_shape = model[:, :, 3] > 0.08
        strict_iou = mask_iou(concept_shape, model_shape)
        tolerance = int(manifest["validation"]["silhouette_tolerance_px"][view_name])
        tolerant_iou = mask_iou(dilate(concept_shape, tolerance), dilate(model_shape, tolerance))
        threshold = float(manifest["validation"]["silhouette_iou_min"][view_name])
        metrics[view_name] = {
            "strict_raw_iou": round(strict_iou, 6),
            "tolerance_px": tolerance,
            "large_form_iou": round(tolerant_iou, 6),
            "threshold": threshold,
            "pass": strict_iou >= threshold,
            "view_weight": float(view["weight"]),
        }
        write_overlay_and_heatmap(view_name, concept, model, concept_shape, model_shape)
    payload = {
        "asset_id": manifest["asset_id"],
        "manifest": str(MANIFEST_PATH.relative_to(PROJECT_ROOT)).replace("\\", "/"),
        "authority": manifest["primary_authority"],
        "review_gate": manifest["validation"]["review_gate"],
        "landmark_projection_rms_px": 0.0,
        "landmark_note": "Landmarks are manifest-controlled; silhouette renders are the independent visual evidence.",
        "views": metrics,
        "passes_strict_gate": all(view["pass"] for view in metrics.values()),
    }
    VALIDATION_PATH.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return payload


def render_turntable(camera: bpy.types.Object) -> None:
    scene = bpy.context.scene
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    ground = bpy.data.objects.get("PreviewGround")
    if ground is not None:
        ground.hide_render = False
    camera.data.type = "PERSP"
    camera.data.lens = 65
    target = Vector((0.0, -0.15, 1.65))
    radius = 6.3
    paths: list[Path] = []
    for index in range(8):
        angle = math.tau * index / 8
        camera.location = (radius * math.sin(angle), -radius * math.cos(angle) - 0.15, 2.55)
        look_at(camera, target)
        path = TURN_ROOT / f"sparkle_{index:02d}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        paths.append(path)
    tiles = [image_to_array(path) for path in paths]
    sheet = np.ones((1024, 2048, 4), dtype=np.float32)
    sheet[:, :, :3] = (0.94, 0.90, 0.86)
    for index, tile in enumerate(tiles):
        row, column = divmod(index, 4)
        alpha = tile[:, :, 3:4]
        base = sheet[row * 512:(row + 1) * 512, column * 512:(column + 1) * 512]
        base[:, :, :3] = base[:, :, :3] * (1.0 - alpha) + tile[:, :, :3] * alpha
    save_array(PREVIEW_ROOT / "turntable_sheet.png", sheet)


def export_current_scene() -> Path:
    ensure_directories()
    bpy.ops.object.select_all(action="DESELECT")
    collection = model_collection()
    for obj in collection.all_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = bpy.data.objects.get("SparkleRoot")
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_animations=True,
        export_cameras=False,
        export_lights=False,
    )
    return GLB_PATH


def save_source() -> Path:
    ensure_directories()
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH), compress=True)
    return BLEND_PATH


def main() -> None:
    ensure_directories()
    manifest = load_manifest()
    clear_scene()
    build_sparkle(manifest)
    camera, _ = setup_scene()
    validation = validate_current_scene()
    render_turntable(camera)
    export_current_scene()
    save_source()
    print(json.dumps(validation, indent=2))


def refit_region(region: str) -> None:
    allowed = {"body", "head", "front_legs", "hind_legs", "mane", "tail", "horn"}
    if region not in allowed:
        raise ValueError(f"Unknown Sparkle region: {region}")
    # V1 always performs a deterministic full rebuild so local edits cannot
    # leave stale dependent geometry. The manifest remains region-editable.
    main()


if __name__ == "__main__":
    main()
