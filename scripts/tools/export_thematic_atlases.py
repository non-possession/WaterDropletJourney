from __future__ import annotations

from collections import defaultdict, deque
from pathlib import Path

from PIL import Image


ROOT = Path("/Users/mistluo/Codes/godot/WaterJourney")
SOURCE = ROOT / "assets" / "originals" / "b2.png"
EXPORT_ROOT = ROOT / "assets" / "atlases"

PADDING = 16
ATLAS_BG = (0, 0, 0, 0)


def crop_box(image: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    return image.crop(box)


def remove_edge_background(
    image: Image.Image,
    threshold: int = 38,
    alpha_cutoff: int = 12,
) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    visited: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int, tuple[int, int, int]]] = deque()

    def add_seed(x: int, y: int) -> None:
        r, g, b, a = pixels[x, y]
        if a <= alpha_cutoff:
            return
        queue.append((x, y, (r, g, b)))

    for x in range(width):
        add_seed(x, 0)
        add_seed(x, height - 1)
    for y in range(height):
        add_seed(0, y)
        add_seed(width - 1, y)

    while queue:
        x, y, seed = queue.popleft()
        if (x, y) in visited:
            continue
        visited.add((x, y))
        r, g, b, a = pixels[x, y]
        if a <= alpha_cutoff:
            continue
        distance = abs(r - seed[0]) + abs(g - seed[1]) + abs(b - seed[2])
        if distance > threshold:
            continue

        pixels[x, y] = (r, g, b, 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in visited:
                queue.append((nx, ny, seed))

    bbox = rgba.getbbox()
    if bbox is None:
        return rgba
    return rgba.crop(bbox)


def save_category_items(
    source: Image.Image,
    category: str,
    specs: list[dict[str, object]],
) -> list[Path]:
    category_dir = EXPORT_ROOT / category
    category_dir.mkdir(parents=True, exist_ok=True)
    outputs: list[Path] = []

    for spec in specs:
        name = spec["name"]
        box = spec["box"]
        transparent = bool(spec.get("transparent", False))
        item = crop_box(source, box)
        if transparent:
            item = remove_edge_background(
                item,
                threshold=int(spec.get("threshold", 38)),
            )
        out_path = category_dir / f"{name}.png"
        item.save(out_path)
        outputs.append(out_path)

    return outputs


def build_atlas(category: str, files: list[Path]) -> Path:
    images = [Image.open(path).convert("RGBA") for path in files]
    max_w = max(img.width for img in images)
    max_h = max(img.height for img in images)
    columns = min(3, len(images))
    rows = (len(images) + columns - 1) // columns
    atlas_w = columns * max_w + (columns + 1) * PADDING
    atlas_h = rows * max_h + (rows + 1) * PADDING
    atlas = Image.new("RGBA", (atlas_w, atlas_h), ATLAS_BG)

    for index, img in enumerate(images):
        col = index % columns
        row = index // columns
        x = PADDING + col * (max_w + PADDING)
        y = PADDING + row * (max_h + PADDING)
        atlas.alpha_composite(img, (x, y))

    atlas_path = EXPORT_ROOT / f"{category}_atlas.png"
    atlas.save(atlas_path)
    return atlas_path


def write_manifest(entries: dict[str, list[Path]], atlases: dict[str, Path]) -> None:
    lines = ["# Thematic Atlases", ""]
    lines.append("由 `assets/originals/b2.png` 手工选区导出的专题图集与切片。")
    lines.append("")
    for category in ("river", "grass", "bridge", "trees"):
        lines.append(f"## {category}")
        lines.append("")
        lines.append(f"- atlas: `assets/atlases/{atlases[category].name}`")
        lines.append(f"- items: `assets/atlases/{category}/`")
        for path in entries[category]:
            lines.append(f"- `{path.name}`")
        lines.append("")

    (EXPORT_ROOT / "ATLAS_INDEX.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    specs: dict[str, list[dict[str, object]]] = {
        "river": [
            {"name": "river_top_straight", "box": (90, 0, 346, 256)},
            {"name": "river_top_bend", "box": (180, 90, 436, 346)},
            {"name": "river_bridge_section", "box": (120, 250, 376, 506)},
            {"name": "river_mid_channel", "box": (95, 430, 351, 686)},
            {"name": "river_mid_bend", "box": (170, 600, 426, 856)},
            {"name": "river_lower_straight", "box": (210, 830, 466, 1086)},
        ],
        "grass": [
            {"name": "grass_open_01", "box": (590, 20, 846, 276)},
            {"name": "grass_open_02", "box": (820, 30, 1076, 286)},
            {"name": "grass_open_03", "box": (980, 240, 1236, 496)},
            {"name": "grass_open_04", "box": (600, 420, 856, 676)},
            {"name": "grass_open_05", "box": (860, 430, 1116, 686)},
            {"name": "grass_open_06", "box": (930, 700, 1186, 956)},
        ],
        "bridge": [
            {
                "name": "bridge_horizontal_main",
                "box": (220, 300, 460, 455),
                "transparent": True,
                "threshold": 44,
            },
            {
                "name": "bridge_with_banks",
                "box": (170, 255, 500, 500),
            },
        ],
        "trees": [
            {
                "name": "tree_deciduous_left",
                "box": (0, 0, 220, 255),
                "transparent": True,
                "threshold": 46,
            },
            {
                "name": "tree_pine_center",
                "box": (430, 0, 700, 320),
                "transparent": True,
                "threshold": 44,
            },
            {
                "name": "tree_deciduous_right",
                "box": (1160, 220, 1448, 560),
                "transparent": True,
                "threshold": 46,
            },
            {
                "name": "tree_deciduous_lower_right",
                "box": (1160, 650, 1415, 950),
                "transparent": True,
                "threshold": 46,
            },
            {
                "name": "tree_pine_lower_right",
                "box": (1220, 810, 1448, 1086),
                "transparent": True,
                "threshold": 44,
            },
        ],
    }

    entries: dict[str, list[Path]] = defaultdict(list)
    atlases: dict[str, Path] = {}
    for category, category_specs in specs.items():
        files = save_category_items(source, category, category_specs)
        entries[category] = files
        atlases[category] = build_atlas(category, files)

    write_manifest(entries, atlases)


if __name__ == "__main__":
    main()
