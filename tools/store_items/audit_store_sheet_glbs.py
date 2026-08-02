import argparse
import json
import sys
from pathlib import Path

import bpy


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mapping", required=True)
    parser.add_argument("--processed-root", required=True)
    parser.add_argument("--report", required=True)
    raw = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    return parser.parse_args(raw)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for datablock in list(datablocks):
            datablocks.remove(datablock)


def mesh_descendants(node):
    found = []
    if node.type == "MESH":
        found.append(node)
    for child in node.children:
        found.extend(mesh_descendants(child))
    return found


def material_images(meshes):
    images = set()
    materials = set()
    for obj in meshes:
        for slot in obj.material_slots:
            material = slot.material
            if material is None:
                continue
            materials.add(material.name)
            if material.use_nodes and material.node_tree:
                for node in material.node_tree.nodes:
                    if node.type == "TEX_IMAGE" and node.image is not None and node.image.size[0] > 0 and node.image.size[1] > 0:
                        images.add(node.image.name)
    return sorted(materials), sorted(images)


def main():
    args = parse_args()
    mapping = json.loads(Path(args.mapping).read_text(encoding="utf-8"))
    root = Path(args.processed_root)
    results = []
    failures = []
    for batch in mapping["batches"]:
        sheet = int(batch["sheet"])
        glb = root / f"store_items_sheet_{sheet:02d}" / f"store_items_sheet_{sheet:02d}_mobile.glb"
        clear_scene()
        bpy.ops.import_scene.gltf(filepath=str(glb))
        for catalog_id in batch["items"]:
            node = bpy.data.objects.get(catalog_id)
            if node is None:
                failures.append(f"sheet {sheet:02d}: missing node {catalog_id}")
                continue
            meshes = mesh_descendants(node)
            polygon_count = sum(len(obj.data.polygons) for obj in meshes)
            materials, images = material_images(meshes)
            if not meshes or polygon_count <= 0:
                failures.append(f"sheet {sheet:02d}: empty geometry for {catalog_id}")
            if not images:
                failures.append(f"sheet {sheet:02d}: no live texture image for {catalog_id}")
            results.append({
                "sheet": sheet,
                "catalog_id": catalog_id,
                "mesh_count": len(meshes),
                "polygon_count": polygon_count,
                "materials": materials,
                "images": images,
            })
    report = {
        "status": "pass" if not failures else "fail",
        "expected_items": sum(len(batch["items"]) for batch in mapping["batches"]),
        "validated_items": len(results),
        "failures": failures,
        "items": results,
    }
    Path(args.report).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"STORE_GLB_AUDIT_{report['status'].upper()}: {len(results)} items, {len(failures)} failures", flush=True)
    if failures:
        for failure in failures:
            print(failure, flush=True)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
