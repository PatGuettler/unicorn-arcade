import bpy
import numpy as np
import sys
from pathlib import Path

source = Path(sys.argv[sys.argv.index("--") + 1])
output_dir = Path(sys.argv[sys.argv.index("--") + 2])
output_dir.mkdir(parents=True, exist_ok=True)
image = bpy.data.images.load(str(source), check_existing=False)
width, height = image.size
pixels = np.empty(width * height * 4, dtype=np.float32)
image.pixels.foreach_get(pixels)
pixels = pixels.reshape((height, width, 4))

# The generated sheet uses a bright green key. Restrict removal to extremely
# saturated green so the illustrated leaves and aqua stones remain intact.
red = pixels[:, :, 0]
green = pixels[:, :, 1]
blue = pixels[:, :, 2]
saturation_key = np.minimum(
    np.clip((green - 0.65) / 0.22, 0.0, 1.0),
    np.clip((green - np.maximum(red, blue) - 0.30) / 0.25, 0.0, 1.0),
)
pixels[:, :, 3] = 1.0 - saturation_key
edge = (saturation_key > 0.0) & (saturation_key < 1.0)
pixels[:, :, 1][edge] = np.minimum(pixels[:, :, 1][edge], np.maximum(red[edge], blue[edge]) * 1.08)
print(
    "JUMP_STONES_ALPHA"
    f" corners={[round(float(pixels[y, x, 3]), 4) for y, x in ((0, 0), (0, width - 1), (height - 1, 0), (height - 1, width - 1))]}"
    f" transparent={float(np.mean(pixels[:, :, 3] < 0.01)):.4f}"
    f" opaque={float(np.mean(pixels[:, :, 3] > 0.99)):.4f}",
    flush=True,
)

def save_rgba(name, data):
    out = bpy.data.images.new(name, width=data.shape[1], height=data.shape[0], alpha=True)
    out.file_format = "PNG"
    out.alpha_mode = "STRAIGHT"
    out.pixels.foreach_set(data.astype(np.float32).ravel())
    out.filepath_raw = str(output_dir / f"{name}.png")
    out.save()
    bpy.data.images.remove(out)

save_rgba("unicorn_jump_stones_alpha_v1", pixels)
cells = {
    "jump_stone_normal_cream_v1": (0, 1),
    "jump_stone_current_v1": (1, 1),
    "jump_stone_normal_lilac_v1": (2, 1),
    "jump_stone_visited_v1": (0, 0),
    "jump_stone_moon_v1": (1, 0),
    "jump_stone_finish_v1": (2, 0),
}
cell_width = width // 3
cell_height = height // 2
for name, (column, row) in cells.items():
    x0 = column * cell_width
    y0 = row * cell_height
    save_rgba(name, pixels[y0:y0 + cell_height, x0:x0 + cell_width, :])

print(f"JUMP_STONES_PROCESSED source={width}x{height} outputs={len(cells)}", flush=True)
