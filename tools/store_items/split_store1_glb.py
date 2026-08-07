import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector


ITEMS = {
    ("top", "left"): ("lamp", "Lava Lamp"),
    ("top", "center"): ("rug", "Fluffy Rug"),
    ("top", "right"): ("plant", "Magic Plant"),
    ("bottom", "left"): ("chair", "Gaming Chair"),
    ("bottom", "center"): ("arcade", "Mini Arcade"),
    ("bottom", "right"): ("trophy", "Gold Trophy"),
}


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output-dir", required=True)
    script_args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    return parser.parse_args(script_args)


def find_components(mesh):
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
    return list(groups.values())


def item_key(point):
    # The reconstruction occasionally bridges empty white space between cells.
    # Classify vertices by the actual asymmetric whitespace between the six
    # source silhouettes so those bridges are cut rather than assigned whole.
    if point.x < -0.45:
        row = "top" if point.z >= -0.0105 else "bottom"
    elif point.x > 0.40:
        row = "top" if point.z >= 0.0315 else "bottom"
    else:
        row = "top" if point.z >= 0.0400 else "bottom"
    if row == "top":
        column = "left" if point.x < -0.50 else "right" if point.x > 0.43 else "center"
    else:
        column = "left" if point.x < -0.40 else "right" if point.x > 0.33 else "center"
    return ITEMS[(row, column)]


def bounds_from_vertices(mesh):
    points = [vertex.co for vertex in mesh.vertices]
    minimum = Vector(tuple(min(point[i] for point in points) for i in range(3)))
    maximum = Vector(tuple(max(point[i] for point in points) for i in range(3)))
    return minimum, maximum


def remove_known_bridge_fragments(mesh, catalog_id):
    remove_indices = set()
    for indices in find_components(mesh):
        center = sum((mesh.vertices[index].co for index in indices), Vector()) / len(indices)
        if catalog_id == "lamp" and center.x > -0.56:
            remove_indices.update(indices)
        elif catalog_id == "rug" and center.x > 0.38:
            remove_indices.update(indices)
    if not remove_indices:
        return
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.verts.ensure_lookup_table()
    bmesh.ops.delete(
        bm,
        geom=[vertex for vertex in bm.verts if vertex.index in remove_indices],
        context="VERTS",
    )
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()


def split_source(source):
    vertex_item = {
        vertex.index: item_key(vertex.co)[0]
        for vertex in source.data.vertices
    }

    objects = []
    reports = []
    for (_, _), (catalog_id, display_name) in ITEMS.items():
        mesh = source.data.copy()
        mesh.name = f"{catalog_id}_mesh"
        obj = bpy.data.objects.new(catalog_id, mesh)
        source.users_collection[0].objects.link(obj)
        obj.matrix_world = source.matrix_world.copy()

        bm = bmesh.new()
        bm.from_mesh(mesh)
        bm.verts.ensure_lookup_table()
        remove = [vertex for vertex in bm.verts if vertex_item[vertex.index] != catalog_id]
        bmesh.ops.delete(bm, geom=remove, context="VERTS")
        bm.to_mesh(mesh)
        bm.free()
        mesh.update()
        remove_known_bridge_fragments(mesh, catalog_id)

        minimum, maximum = bounds_from_vertices(mesh)
        local_origin = Vector(((minimum.x + maximum.x) * 0.5, (minimum.y + maximum.y) * 0.5, minimum.z))
        for vertex in mesh.vertices:
            vertex.co -= local_origin
        obj.location += local_origin
        obj["catalog_id"] = catalog_id
        obj["catalog_name"] = display_name
        obj["source_sheet"] = "store_items_sheet_01.png"

        minimum_centered, maximum_centered = bounds_from_vertices(mesh)
        reports.append({
            "catalog_id": catalog_id,
            "catalog_name": display_name,
            "vertices": len(mesh.vertices),
            "polygons": len(mesh.polygons),
            "loose_components": len(find_components(mesh)),
            "grid_location": [round(float(value), 6) for value in obj.location],
            "local_bounds_min": [round(float(value), 6) for value in minimum_centered],
            "local_bounds_max": [round(float(value), 6) for value in maximum_centered],
            "dimensions": [round(float(value), 6) for value in maximum_centered - minimum_centered],
        })
        objects.append(obj)

    bpy.data.objects.remove(source, do_unlink=True)
    return objects, reports


def export_combined(objects, output_path):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
        export_format="GLB",
        use_selection=True,
        export_extras=True,
        export_yup=True,
    )


def main():
    args = parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(Path(args.input).resolve()))
    sources = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(sources) != 1:
        raise RuntimeError(f"Expected one source mesh, found {len(sources)}")

    objects, reports = split_source(sources[0])
    (output_dir / "store1_separation_report.json").write_text(json.dumps({
        "source": str(Path(args.input).resolve()),
        "objects": reports,
        "total_vertices": sum(item["vertices"] for item in reports),
        "total_polygons": sum(item["polygons"] for item in reports),
    }, indent=2), encoding="utf-8")

    bpy.ops.wm.save_as_mainfile(filepath=str(output_dir / "store1_separated.blend"))
    export_combined(objects, output_dir / "store1_separated.glb")


if __name__ == "__main__":
    main()
