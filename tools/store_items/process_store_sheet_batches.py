import argparse
import hashlib
import json
import math
import sys
from collections import defaultdict
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector


CELL_NAMES = ["top_left", "top_right", "middle_left", "middle_right", "bottom_left", "bottom_right"]
INTRICATE_IDS = {
    "chandelier", "table_pool", "pet_fish", "pet_dragon", "toy_train", "xmas_deer", "xmas_snow",
    "hall_mask", "mom_tea", "butterfly_model", "fairy_lights", "crown_display", "studio_spot",
    "record_player", "bubble_machine", "terrarium", "uni_fountain", "crystal_ball", "hammock",
    "ac_fish_tank", "ac_anthurium", "ac_typewriter", "ac_cello", "uni_cloud_lamp", "uni_horn_planter",
}
RUG_IDS = {"rug_welcome", "rug_persian", "rug_bear", "rug_magic", "rug_puzzle", "pet_paw", "uni_glitter_rug"}
TARGET_MAX_DIMENSION = 1.55


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mapping", required=True)
    parser.add_argument("--input-dir", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--sheet", type=int)
    raw = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    return parser.parse_args(raw)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (
        bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras,
        bpy.data.lights, bpy.data.images,
    ):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


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


def mesh_bounds(mesh, indices=None):
    points = [mesh.vertices[index].co for index in indices] if indices is not None else [vertex.co for vertex in mesh.vertices]
    minimum = Vector(tuple(min(point[i] for point in points) for i in range(3)))
    maximum = Vector(tuple(max(point[i] for point in points) for i in range(3)))
    return minimum, maximum


def gap_threshold_coordinates(values, expected_minimum, expected_maximum, fraction, window_fraction=0.30):
    coordinates = sorted(values)
    if len(coordinates) < 2:
        return expected_minimum + (expected_maximum - expected_minimum) * fraction
    minimum = coordinates[0]
    maximum = coordinates[-1]
    full_span = expected_maximum - expected_minimum
    target = expected_minimum + full_span * fraction
    window = full_span * window_fraction
    candidates = []
    for left, right in zip(coordinates, coordinates[1:]):
        midpoint = (left + right) * 0.5
        if abs(midpoint - target) <= window:
            candidates.append((right - left, midpoint))
    return max(candidates)[1] if candidates else target


def classify_point(point, x_boundary, lower_boundary, upper_boundary):
    column = 0 if point.x < x_boundary else 1
    if point.z >= upper_boundary:
        row = 0
    elif point.z >= lower_boundary:
        row = 1
    else:
        row = 2
    return row * 2 + column


def vertex_assignments(mesh, item_count, threshold_overrides=None):
    minimum, maximum = mesh_bounds(mesh)
    x_mid = (minimum.x + maximum.x) * 0.5
    z_lower_equal = minimum.z + (maximum.z - minimum.z) / 3.0
    z_upper_equal = minimum.z + (maximum.z - minimum.z) * 2.0 / 3.0
    row_ranges = [
        (z_upper_equal, maximum.z),
        (z_lower_equal, z_upper_equal),
        (minimum.z, z_lower_equal),
    ]
    row_x = []
    for low, high in row_ranges:
        values = [vertex.co.x for vertex in mesh.vertices if low <= vertex.co.z <= high]
        row_x.append(gap_threshold_coordinates(values, minimum.x, maximum.x, 0.5))
    column_z = []
    for left in (True, False):
        values = [vertex.co.z for vertex in mesh.vertices if (vertex.co.x < x_mid) == left]
        # Keep the two row separators in non-overlapping thirds of the grid.
        # A wider window can select the same unusually large center gap for both
        # boundaries when the middle-row props are compact (for example sheet 13).
        lower = gap_threshold_coordinates(values, minimum.z, maximum.z, 1.0 / 3.0, 0.16)
        upper = gap_threshold_coordinates(values, minimum.z, maximum.z, 2.0 / 3.0, 0.16)
        column_z.append((lower, upper))
    if threshold_overrides:
        if "row_x" in threshold_overrides:
            row_x = list(map(float, threshold_overrides["row_x"]))
        if "left_z" in threshold_overrides:
            column_z[0] = tuple(map(float, threshold_overrides["left_z"]))
        if "right_z" in threshold_overrides:
            column_z[1] = tuple(map(float, threshold_overrides["right_z"]))
    assignments = {}
    for vertex in mesh.vertices:
        column = 0 if vertex.co.x < x_mid else 1
        lower, upper = column_z[column]
        row = 0 if vertex.co.z >= upper else 1 if vertex.co.z >= lower else 2
        column = 0 if vertex.co.x < row_x[row] else 1
        lower, upper = column_z[column]
        row = 0 if vertex.co.z >= upper else 1 if vertex.co.z >= lower else 2
        assignments[vertex.index] = row * 2 + column
    return assignments, minimum, maximum, {
        "row_x": list(map(float, row_x)),
        "left_z": list(map(float, column_z[0])),
        "right_z": list(map(float, column_z[1])),
    }


def vertex_assignments_three_by_two(mesh, threshold_overrides=None):
    minimum, maximum = mesh_bounds(mesh)
    thresholds = threshold_overrides or {}
    x_boundaries = list(map(float, thresholds.get("x", [
        minimum.x + (maximum.x - minimum.x) / 3.0,
        minimum.x + (maximum.x - minimum.x) * 2.0 / 3.0,
    ])))
    z_boundary = float(thresholds.get("z", (minimum.z + maximum.z) * 0.5))
    assignments = {}
    for vertex in mesh.vertices:
        column = 0 if vertex.co.x < x_boundaries[0] else 1 if vertex.co.x < x_boundaries[1] else 2
        row = 0 if vertex.co.z >= z_boundary else 1
        assignments[vertex.index] = row * 3 + column
    return assignments, minimum, maximum, {"x": x_boundaries, "z": z_boundary, "layout": "3x2"}


def consolidate_connected_components(mesh, assignments):
    """Keep connected generated surfaces intact when a cell boundary overlaps them."""
    neighbors = [[] for _ in mesh.vertices]
    for edge in mesh.edges:
        a, b = edge.vertices
        neighbors[a].append(b)
        neighbors[b].append(a)
    unseen = set(range(len(mesh.vertices)))
    component_summary = []
    while unseen:
        seed = unseen.pop()
        stack = [seed]
        component = [seed]
        while stack:
            current = stack.pop()
            for neighbor in neighbors[current]:
                if neighbor in unseen:
                    unseen.remove(neighbor)
                    stack.append(neighbor)
                    component.append(neighbor)
        votes = defaultdict(int)
        for index in component:
            votes[assignments[index]] += 1
        selected_cell = max(votes, key=lambda cell: (votes[cell], -cell))
        for index in component:
            assignments[index] = selected_cell
        if len(component) >= 100:
            component_summary.append((len(component), selected_cell, dict(votes)))
    component_summary.sort(reverse=True)
    return component_summary


def cluster_connected_components(mesh, assignments, target_cells):
    """Cluster overlapping sheet props by whole connected surfaces in XYZ space."""
    target_cells = list(map(int, target_cells))
    neighbors = [[] for _ in mesh.vertices]
    for edge in mesh.edges:
        a, b = edge.vertices
        neighbors[a].append(b)
        neighbors[b].append(a)
    unseen = set(range(len(mesh.vertices)))
    components = []
    while unseen:
        seed = unseen.pop()
        stack = [seed]
        indices = [seed]
        while stack:
            current = stack.pop()
            for neighbor in neighbors[current]:
                if neighbor in unseen:
                    unseen.remove(neighbor)
                    stack.append(neighbor)
                    indices.append(neighbor)
        votes = defaultdict(int)
        center = Vector((0.0, 0.0, 0.0))
        for index in indices:
            votes[assignments[index]] += 1
            center += mesh.vertices[index].co
        center /= len(indices)
        majority = max(votes, key=lambda cell: (votes[cell], -cell))
        components.append({"indices": indices, "center": center, "majority": majority, "votes": dict(votes)})

    candidates = [component for component in components if component["majority"] in target_cells]
    centers = {}
    for cell in target_cells:
        seed = max((component for component in candidates if component["majority"] == cell), key=lambda component: len(component["indices"]))
        centers[cell] = seed["center"].copy()
    for _iteration in range(12):
        totals = {cell: Vector((0.0, 0.0, 0.0)) for cell in target_cells}
        weights = {cell: 0 for cell in target_cells}
        for component in candidates:
            cell = min(target_cells, key=lambda candidate: (component["center"] - centers[candidate]).length_squared)
            component["cluster"] = cell
            weight = len(component["indices"])
            totals[cell] += component["center"] * weight
            weights[cell] += weight
        for cell in target_cells:
            if weights[cell]:
                centers[cell] = totals[cell] / weights[cell]
    for component in candidates:
        cell = component["cluster"]
        for index in component["indices"]:
            assignments[index] = cell
    summary = sorted(
        ((len(component["indices"]), component["cluster"], component["majority"], component["center"][:]) for component in candidates),
        reverse=True,
    )
    return summary


def remove_unassigned(mesh, assignments, cell_index):
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.verts.ensure_lookup_table()
    remove = [vertex for vertex in bm.verts if assignments.get(vertex.index) != cell_index]
    bmesh.ops.delete(bm, geom=remove, context="VERTS")
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()


def recenter_and_normalize(obj):
    minimum, maximum = mesh_bounds(obj.data)
    origin = Vector(((minimum.x + maximum.x) * 0.5, (minimum.y + maximum.y) * 0.5, minimum.z))
    dimensions = maximum - minimum
    scale = TARGET_MAX_DIMENSION / max(dimensions.x, dimensions.y, dimensions.z, 1e-6)
    for vertex in obj.data.vertices:
        vertex.co = (vertex.co - origin) * scale
    obj.location = Vector((0.0, 0.0, 0.0))
    obj.rotation_euler = (0.0, 0.0, 0.0)
    obj.scale = Vector((1.0, 1.0, 1.0))
    obj.data.update()
    final_min, final_max = mesh_bounds(obj.data)
    return origin, dimensions, scale, final_min, final_max


def polygon_target(catalog_id):
    if catalog_id in RUG_IDS:
        return 7000
    if catalog_id.startswith("pet_") or catalog_id in INTRICATE_IDS:
        return 18000
    if catalog_id.startswith("bed_") or catalog_id.startswith("table_"):
        return 15000
    return 12000


def decimate(obj, target):
    source = len(obj.data.polygons)
    if source <= target:
        return source, source
    ratio = target / source
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    modifier = obj.modifiers.new(name="MobileDecimate", type="DECIMATE")
    modifier.decimate_type = "COLLAPSE"
    modifier.ratio = ratio
    modifier.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.select_set(False)
    return source, len(obj.data.polygons)


def optimize_textures():
    report = []
    for image in bpy.data.images:
        if image.name == "Render Result" or image.size[0] == 0:
            continue
        source = [int(image.size[0]), int(image.size[1])]
        lower = image.name.lower()
        target = 2048 if "base_color" in lower or "normal" in lower else 1024
        if image.size[0] > target or image.size[1] > target:
            ratio = min(target / image.size[0], target / image.size[1])
            image.scale(max(1, round(image.size[0] * ratio)), max(1, round(image.size[1] * ratio)))
        report.append({"name": image.name, "source": source, "optimized": [int(image.size[0]), int(image.size[1])]})
    return report


def add_area(name, location, energy, size, target):
    data = bpy.data.lights.new(name=name, type="AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    light = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(light)
    light.location = location
    light.rotation_euler = (target - location).to_track_quat("-Z", "Y").to_euler()
    return light


def render_items(objects, output_dir):
    output_dir.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = False
    if scene.world is None:
        scene.world = bpy.data.worlds.new("ItemWorld")
    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.96, 0.96, 0.96, 1.0)
    background.inputs["Strength"].default_value = 0.22
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = -0.2

    camera_data = bpy.data.cameras.new("ItemCamera")
    camera = bpy.data.objects.new("ItemCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.data.type = "ORTHO"

    for obj in objects:
        for candidate in objects:
            candidate.hide_render = candidate != obj
        minimum, maximum = mesh_bounds(obj.data)
        center = (minimum + maximum) * 0.5
        dimensions = maximum - minimum
        radius = max(dimensions) * 3.0
        camera.location = center + Vector((radius * 0.55, -radius, radius * 0.32))
        camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
        camera.data.ortho_scale = max(dimensions.z, dimensions.x, dimensions.y) * 1.45
        for light in [candidate for candidate in scene.objects if candidate.type == "LIGHT"]:
            bpy.data.objects.remove(light, do_unlink=True)
        add_area("Key", center + Vector((-radius, -radius, radius)), 320, radius, center)
        add_area("Fill", center + Vector((radius, -radius * 0.4, radius * 0.4)), 130, radius, center)
        add_area("Rim", center + Vector((0, radius, radius)), 190, radius, center)
        scene.render.filepath = str(output_dir / f"{obj.name}.png")
        bpy.ops.render.render(write_still=True)
    for obj in objects:
        obj.hide_render = False
    bpy.data.objects.remove(camera, do_unlink=True)
    for light in [candidate for candidate in scene.objects if candidate.type == "LIGHT"]:
        bpy.data.objects.remove(light, do_unlink=True)


def export_sheet(objects, output_path):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=str(output_path), export_format="GLB", use_selection=True,
        export_extras=True, export_yup=True,
    )


def process_batch(batch, input_dir, output_root):
    sheet = int(batch["sheet"])
    input_path = input_dir / batch["input"]
    if not input_path.exists():
        raise FileNotFoundError(input_path)
    sheet_name = f"store_items_sheet_{sheet:02d}"
    sheet_dir = output_root / sheet_name
    sheet_dir.mkdir(parents=True, exist_ok=True)
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=str(input_path.resolve()))
    sources = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(sources) != 1:
        raise RuntimeError(f"{input_path.name}: expected one mesh, found {len(sources)}")
    source = sources[0]
    if batch.get("layout") == "3x2":
        assignments, grid_min, grid_max, grid_thresholds = vertex_assignments_three_by_two(
            source.data,
            batch.get("thresholds"),
        )
    else:
        assignments, grid_min, grid_max, grid_thresholds = vertex_assignments(
            source.data,
            len(batch["items"]),
            batch.get("thresholds"),
        )
    if batch.get("consolidate_components", False):
        component_summary = consolidate_connected_components(source.data, assignments)
        print(f"STORE_COMPONENTS sheet={sheet:02d} largest={component_summary[:12]}", flush=True)
    if batch.get("cluster_cells"):
        cluster_summary = cluster_connected_components(source.data, assignments, batch["cluster_cells"])
        print(f"STORE_CLUSTERS sheet={sheet:02d} largest={cluster_summary[:12]}", flush=True)
    cell_vertex_counts = [sum(1 for cell in assignments.values() if cell == index) for index in range(len(batch["items"]))]
    print(
        f"STORE_GRID sheet={sheet:02d} thresholds={grid_thresholds} vertex_counts={cell_vertex_counts}",
        flush=True,
    )
    objects = []
    records = []
    for cell_index, catalog_id in enumerate(batch["items"]):
        mesh = source.data.copy()
        mesh.name = f"{catalog_id}_mesh"
        obj = bpy.data.objects.new(catalog_id, mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.matrix_world = source.matrix_world.copy()
        remove_unassigned(mesh, assignments, cell_index)
        if len(mesh.vertices) == 0 or len(mesh.polygons) == 0:
            raise RuntimeError(f"{sheet_name} {catalog_id}: empty split")
        origin, dimensions, scale, final_min, final_max = recenter_and_normalize(obj)
        source_polygons, optimized_polygons = decimate(obj, polygon_target(catalog_id))
        obj["catalog_id"] = catalog_id
        obj["source_sheet"] = f"{sheet_name}.png"
        obj["source_glb"] = input_path.name
        records.append({
            "catalog_id": catalog_id,
            "cell": CELL_NAMES[cell_index],
            "source_vertices": len(mesh.vertices),
            "source_polygons": source_polygons,
            "optimized_vertices": len(obj.data.vertices),
            "optimized_polygons": optimized_polygons,
            "source_origin": list(map(float, origin)),
            "source_dimensions": list(map(float, dimensions)),
            "normalization_scale": scale,
            "final_bounds_min": list(map(float, final_min)),
            "final_bounds_max": list(map(float, final_max)),
        })
        objects.append(obj)
    bpy.data.objects.remove(source, do_unlink=True)
    textures = optimize_textures()
    render_items(objects, sheet_dir / "previews")
    blend_path = sheet_dir / f"{sheet_name}_mobile.blend"
    glb_path = sheet_dir / f"{sheet_name}_mobile.glb"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    export_sheet(objects, glb_path)
    report = {
        "sheet": sheet,
        "source": str(input_path.resolve()),
        "source_bytes": input_path.stat().st_size,
        "source_sha256": sha256(input_path),
        "grid_bounds_min": list(map(float, grid_min)),
        "grid_bounds_max": list(map(float, grid_max)),
        "grid_thresholds": grid_thresholds,
        "items": records,
        "textures": textures,
        "optimized_glb_bytes": glb_path.stat().st_size,
    }
    (sheet_dir / f"{sheet_name}_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"STORE_BATCH sheet={sheet:02d} items={len(objects)} polygons={sum(item['optimized_polygons'] for item in records)} glb={glb_path.stat().st_size}", flush=True)
    return report


def main():
    settings = parse_args()
    mapping = json.loads(Path(settings.mapping).read_text(encoding="utf-8"))
    input_dir = Path(settings.input_dir)
    output_root = Path(settings.output_dir)
    output_root.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    batches = mapping["batches"]
    if settings.sheet is not None:
        batches = [batch for batch in batches if int(batch["sheet"]) == settings.sheet]
    reports = [process_batch(batch, input_dir, output_root) for batch in batches]
    (output_root / "batch_summary.json").write_text(json.dumps({
        "sheets": reports,
        "missing_sheet": mapping["missing_sheet"],
        "missing_items": mapping["missing_items"],
    }, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
