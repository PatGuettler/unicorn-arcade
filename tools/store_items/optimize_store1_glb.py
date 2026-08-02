import argparse
import json
import sys
from pathlib import Path

import bpy


TARGET_POLYGONS = {
    "lamp": 22000,
    "rug": 18000,
    "plant": 35000,
    "chair": 28000,
    "arcade": 30000,
    "trophy": 18000,
}

TARGET_TEXTURES = {
    "base_color": 2048,
    "normal": 2048,
    "metallic_roughness": 1024,
    "emissive": 1024,
}


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output-dir", required=True)
    script_args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    return parser.parse_args(script_args)


def main():
    args = parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(Path(args.input).resolve()))

    objects = sorted((obj for obj in bpy.context.scene.objects if obj.type == "MESH"), key=lambda obj: obj.name)
    report = []
    for obj in objects:
        catalog_id = obj.name.removesuffix("_mesh")
        target = TARGET_POLYGONS[catalog_id]
        source_polygons = len(obj.data.polygons)
        ratio = min(1.0, target / max(1, source_polygons))
        if ratio < 1.0:
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            modifier = obj.modifiers.new(name="MobileDecimate", type="DECIMATE")
            modifier.decimate_type = "COLLAPSE"
            modifier.ratio = ratio
            modifier.use_collapse_triangulate = True
            bpy.ops.object.modifier_apply(modifier=modifier.name)
            obj.select_set(False)
        report.append({
            "catalog_id": catalog_id,
            "source_polygons": source_polygons,
            "optimized_polygons": len(obj.data.polygons),
            "vertices": len(obj.data.vertices),
            "ratio": round(len(obj.data.polygons) / source_polygons, 6),
        })

    texture_report = []
    for image in bpy.data.images:
        target = TARGET_TEXTURES.get(image.name)
        source_size = [int(image.size[0]), int(image.size[1])]
        if target and (image.size[0] > target or image.size[1] > target):
            image.scale(target, target)
            image.pack()
        texture_report.append({
            "name": image.name,
            "source_size": source_size,
            "optimized_size": [int(image.size[0]), int(image.size[1])],
        })

    (output_dir / "store1_optimization_report.json").write_text(json.dumps({
        "objects": report,
        "textures": sorted(texture_report, key=lambda item: item["name"]),
        "source_total_polygons": sum(item["source_polygons"] for item in report),
        "optimized_total_polygons": sum(item["optimized_polygons"] for item in report),
    }, indent=2), encoding="utf-8")

    bpy.ops.wm.save_as_mainfile(filepath=str(output_dir / "store1_mobile.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=str(output_dir / "store1_mobile.glb"),
        export_format="GLB",
        use_selection=True,
        export_extras=True,
        export_yup=True,
    )


if __name__ == "__main__":
    main()
