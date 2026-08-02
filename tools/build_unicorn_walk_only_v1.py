"""Retarget the verified Meshy walk onto six supplied textured unicorn GLBs."""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = Path.home() / "Downloads"
ASSET_ROOT = PROJECT_ROOT / "godot" / "assets" / "characters" / "unicorns"
PREVIEW_ROOT = PROJECT_ROOT / "previews" / "unicorn_walk_only_v1"
REPORT_PATH = PREVIEW_ROOT / "build_report.json"
FPS = 24
FRAME_START = 1
FRAME_END = 25

VARIANTS = {
    "sparkle": "unicorn_sparkle_v1.glb",
    "rainbow": "unicorn_rainbow_v1.glb",
    "star": "unicorn_star_v1.glb",
    "cloud": "unicorn_cloud_v1.glb",
    "dream": "unicorn_dreamer_v1.glb",
    "mystic": "unicorn_mystic_v1.glb",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def look_at(obj: bpy.types.Object, target: Vector) -> None:
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def import_variant(variant: str) -> tuple[bpy.types.Object, bpy.types.Object, Path]:
    source_path = SOURCE_ROOT / f"{variant}.glb"
    if not source_path.exists():
        raise RuntimeError(f"Missing supplied source: {source_path}")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source_path))
    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    skinned = [
        obj for obj in bpy.context.scene.objects
        if obj.type == "MESH" and any(mod.type == "ARMATURE" for mod in obj.modifiers)
    ]
    if len(armatures) != 1 or len(skinned) != 1:
        raise RuntimeError(f"{variant}: expected one armature and one skinned mesh")
    armature = armatures[0]
    mesh = skinned[0]
    for pose_bone in armature.pose.bones:
        pose_bone.custom_shape = None
    for helper in [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and obj != mesh]:
        helper_data = helper.data
        bpy.data.objects.remove(helper, do_unlink=True)
        if helper_data.users == 0:
            bpy.data.meshes.remove(helper_data)
    armature.name = f"Unicorn{variant.title()}Rig"
    armature.data.name = f"Unicorn{variant.title()}RigData"
    mesh.name = f"Unicorn{variant.title()}Mesh"
    mesh.data.name = f"Unicorn{variant.title()}MeshData"
    for image in list(bpy.data.images):
        image.name = f"{variant}_{image.name.lower()}"
    armature["asset_id"] = f"unicorn_{variant}_v1"
    armature["variant_id"] = variant
    armature["source_sha256"] = sha256(source_path)
    return armature, mesh, source_path


def linear_chain(start: bpy.types.Bone) -> list[bpy.types.Bone]:
    chain = [start]
    current = start
    while len(current.children) == 1:
        current = current.children[0]
        chain.append(current)
    return chain


def discover_motion_map(armature: bpy.types.Object) -> dict[str, list[str]]:
    candidates: list[dict] = []
    for bone in armature.data.bones:
        if bone.parent is None or len(bone.parent.children) <= 1:
            continue
        chain = linear_chain(bone)
        if len(chain) < 3:
            continue
        points = [item.head_local for item in chain] + [chain[-1].tail_local]
        candidates.append({
            "bones": [item.name for item in chain],
            "mean_x": sum(point.x for point in points) / len(points),
            "mean_y": sum(point.y for point in points) / len(points),
            "max_abs_x": max(abs(point.x) for point in points),
            "min_z": min(point.z for point in points),
            "max_z": max(point.z for point in points),
        })

    legs = [
        item for item in candidates
        if item["min_z"] < 0.12 and item["max_abs_x"] > 0.07 and len(item["bones"]) >= 4
    ]
    tails = [
        item for item in candidates
        if item["min_z"] < 0.40 and item["mean_y"] > 0.25 and item["max_abs_x"] < 0.04
    ]
    if len(legs) != 4 or len(tails) != 1:
        raise RuntimeError(f"Motion-map discovery failed: legs={legs}, tails={tails}")

    motion_map: dict[str, list[str]] = {"tail": tails[0]["bones"]}
    for item in legs:
        longitudinal = "front" if item["mean_y"] < 0.0 else "hind"
        lateral = "left" if item["mean_x"] < 0.0 else "right"
        motion_map[f"{longitudinal}_{lateral}"] = item["bones"]
    if set(motion_map) != {"tail", "front_left", "front_right", "hind_left", "hind_right"}:
        raise RuntimeError(f"Incomplete motion map: {motion_map}")
    return motion_map


def clear_animation(armature: bpy.types.Object) -> None:
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    armature.animation_data_clear()
    armature.location = (0.0, 0.0, 0.0)
    for pose_bone in armature.pose.bones:
        pose_bone.rotation_mode = "XYZ"
        pose_bone.rotation_euler = (0.0, 0.0, 0.0)
        pose_bone.location = (0.0, 0.0, 0.0)
        pose_bone.scale = (1.0, 1.0, 1.0)


def key_rotation(armature: bpy.types.Object, bone_name: str, frame: int, x: float = 0.0, z: float = 0.0) -> None:
    pose_bone = armature.pose.bones[bone_name]
    pose_bone.rotation_mode = "XYZ"
    pose_bone.rotation_euler = (math.radians(x), 0.0, math.radians(z))
    pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame, group=bone_name)


def gait_values(t: float, phase: float, kind: str) -> list[float]:
    cycle = math.tau * (t - phase)
    wave = math.sin(cycle)
    lift = max(0.0, math.sin(cycle))
    settle = max(0.0, -math.sin(cycle))
    if kind == "front":
        return [18.0 * wave, -24.0 * lift + 3.0 * settle, 16.0 * lift, -8.0 * lift, 5.0 * lift]
    return [-17.0 * wave, 25.0 * lift - 3.0 * settle, -17.0 * lift, 9.0 * lift, -5.0 * lift]


def fit_angles(values: list[float], chain_length: int) -> list[float]:
    if chain_length == len(values):
        return values
    if chain_length == len(values) + 1:
        return [values[0] * 0.35] + values
    fitted: list[float] = []
    for index in range(chain_length):
        source = index * (len(values) - 1) / max(1, chain_length - 1)
        low = int(math.floor(source))
        high = min(len(values) - 1, low + 1)
        factor = source - low
        fitted.append(values[low] * (1.0 - factor) + values[high] * factor)
    return fitted


def author_walk(armature: bpy.types.Object, motion_map: dict[str, list[str]]) -> bpy.types.Action:
    clear_animation(armature)
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = FRAME_START
    scene.frame_end = FRAME_END
    armature.animation_data_create()
    action = bpy.data.actions.new("Walk")
    armature.animation_data.action = action
    action["looping"] = True
    action["gait"] = "stylized_four_beat_walk"

    phases = {
        "front_left": (0.00, "front"),
        "hind_right": (0.25, "hind"),
        "front_right": (0.50, "front"),
        "hind_left": (0.75, "hind"),
    }
    keyed_frames = list(range(FRAME_START, FRAME_END + 1, 3))
    if keyed_frames[-1] != FRAME_END:
        keyed_frames.append(FRAME_END)
    for frame in keyed_frames:
        t = (frame - FRAME_START) / (FRAME_END - FRAME_START)
        armature.location = (0.0, 0.0, 0.004 + 0.004 * math.cos(math.tau * 2.0 * t))
        armature.keyframe_insert(data_path="location", frame=frame, group="RootMotion")

        for chain_name, (phase, kind) in phases.items():
            chain = motion_map[chain_name]
            angles = fit_angles(gait_values(t, phase, kind), len(chain))
            for bone_name, angle in zip(chain, angles):
                key_rotation(armature, bone_name, frame, x=angle)

        tail = motion_map["tail"]
        tail_wave = math.sin(math.tau * (t - 0.12))
        tail_lift = math.sin(math.tau * 2.0 * (t - 0.08))
        for index, bone_name in enumerate(tail):
            factor = index / max(1, len(tail) - 1)
            clearance = 14.0 * (1.0 - factor) + 1.0 * factor
            key_rotation(
                armature, bone_name, frame,
                x=clearance + 1.4 * factor * tail_lift,
                z=(0.8 + 3.2 * factor) * tail_wave,
            )

    for curve in action.fcurves:
        for point in curve.keyframe_points:
            point.interpolation = "BEZIER"
            point.handle_left_type = "AUTO_CLAMPED"
            point.handle_right_type = "AUTO_CLAMPED"
    scene.frame_set(FRAME_START)
    return action


def setup_preview_scene(variant: str) -> bpy.types.Object:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_percentage = 100
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.look = "AgX - Medium High Contrast"
    world = bpy.data.worlds.new(f"{variant.title()}ReviewWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.006, 0.008, 0.03, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.2
    scene.world = world

    bpy.ops.mesh.primitive_plane_add(size=20, location=(0.0, 0.0, -0.008))
    ground = bpy.context.object
    ground.name = "ReviewGround"
    material = bpy.data.materials.new("ReviewGroundMaterial")
    material.diffuse_color = (0.06, 0.07, 0.14, 1.0)
    ground.data.materials.append(material)

    for name, location, energy, size, color in (
        ("ReviewKey", (3.5, -3.8, 5.0), 920.0, 4.0, (1.0, 0.86, 0.76)),
        ("ReviewFill", (-3.5, -2.0, 3.0), 620.0, 3.5, (0.58, 0.76, 1.0)),
        ("ReviewRim", (2.0, 4.0, 4.5), 820.0, 3.0, (0.92, 0.55, 1.0)),
    ):
        data = bpy.data.lights.new(name, "AREA")
        data.energy = energy
        data.shape = "DISK"
        data.size = size
        data.color = color
        light = bpy.data.objects.new(name, data)
        scene.collection.objects.link(light)
        light.location = location
        look_at(light, Vector((0.0, 0.0, 0.82)))

    camera_data = bpy.data.cameras.new("ReviewCamera")
    camera = bpy.data.objects.new("ReviewCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 2.18
    camera.location = (2.7, -2.7, 1.48)
    look_at(camera, Vector((0.0, -0.03, 0.82)))
    return camera


def render_review_frames(variant: str, camera: bpy.types.Object) -> list[str]:
    scene = bpy.context.scene
    paths: list[str] = []
    for frame in (1, 7, 13, 19):
        scene.frame_set(frame)
        path = PREVIEW_ROOT / f"{variant}_walk_frame_{frame:02d}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        paths.append(str(path.relative_to(PROJECT_ROOT)).replace("\\", "/"))
    camera.location = (3.4, 0.0, 1.05)
    look_at(camera, Vector((0.0, 0.0, 0.82)))
    for frame in (1, 7, 13, 19):
        scene.frame_set(frame)
        path = PREVIEW_ROOT / f"{variant}_walk_side_frame_{frame:02d}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        paths.append(str(path.relative_to(PROJECT_ROOT)).replace("\\", "/"))
    return paths


def export_variant(armature: bpy.types.Object, mesh: bpy.types.Object, destination: Path) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    armature.select_set(True)
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.export_scene.gltf(
        filepath=str(destination),
        export_format="GLB",
        use_selection=True,
        export_apply=False,
        export_yup=True,
        export_animations=True,
        export_frame_range=True,
        export_force_sampling=True,
        export_cameras=False,
        export_lights=False,
    )


def validate_export(variant: str, destination: Path) -> dict:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(destination))
    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    skinned = [obj for obj in meshes if any(mod.type == "ARMATURE" for mod in obj.modifiers)]
    actions = list(bpy.data.actions)
    images = {image.name: list(image.size) for image in bpy.data.images}
    helpers = [obj.name for obj in meshes if obj not in skinned]
    result = {
        "output_file": str(destination.relative_to(PROJECT_ROOT)).replace("\\", "/"),
        "output_bytes": destination.stat().st_size,
        "output_sha256": sha256(destination),
        "armature_count": len(armatures),
        "bone_count": len(armatures[0].data.bones) if len(armatures) == 1 else 0,
        "skinned_mesh_count": len(skinned),
        "helper_meshes": helpers,
        "actions": [action.name for action in actions],
        "action_ranges": {action.name: [round(v, 3) for v in action.frame_range] for action in actions},
        "embedded_images": images,
    }
    result["passes"] = (
        destination.stat().st_size > 0
        and len(armatures) == 1
        and len(skinned) == 1
        and set(helpers) <= {"Icosphere"}
        and [name.lower() for name in result["actions"]] == ["walk"]
        and len(images) == 4
    )
    if not result["passes"]:
        raise RuntimeError(f"{variant}: exported GLB validation failed: {result}")
    result["helper_note"] = "Blender's glTF importer recreates one unskinned Icosphere as a shared custom-bone display shape; it is not runtime character geometry."
    return result


def build_variant(variant: str, output_name: str) -> dict:
    armature, mesh, source_path = import_variant(variant)
    motion_map = discover_motion_map(armature)
    author_walk(armature, motion_map)
    camera = setup_preview_scene(variant)
    preview_frames = render_review_frames(variant, camera)
    destination = ASSET_ROOT / output_name
    export_variant(armature, mesh, destination)
    result = validate_export(variant, destination)
    result.update({
        "variant": variant,
        "source_file": source_path.name,
        "source_bytes": source_path.stat().st_size,
        "source_sha256": sha256(source_path),
        "motion_map": motion_map,
        "preview_frames": preview_frames,
        "visual_review_required": True,
    })
    return result


def main() -> None:
    ASSET_ROOT.mkdir(parents=True, exist_ok=True)
    PREVIEW_ROOT.mkdir(parents=True, exist_ok=True)
    report = {
        "asset_set": "unicorn_walk_only_v1",
        "animation_contract": ["Walk"],
        "fps": FPS,
        "frame_range": [FRAME_START, FRAME_END],
        "variants": {},
    }
    for variant, output_name in VARIANTS.items():
        print(f"BUILDING_VARIANT={variant}")
        report["variants"][variant] = build_variant(variant, output_name)
    report["passes"] = all(item["passes"] for item in report["variants"].values())
    REPORT_PATH.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("UNICORN_WALK_BUILD=" + json.dumps(report))
    if not report["passes"]:
        raise RuntimeError("Walk-only unicorn set failed validation")


if __name__ == "__main__":
    main()
