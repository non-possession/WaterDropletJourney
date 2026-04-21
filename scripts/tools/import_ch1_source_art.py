from pathlib import Path
from collections import deque
from PIL import Image


ROOT = Path("/Users/mistluo/Codes/godot/WaterJourney")
ORIG = ROOT / "assets/originals"
PLAYER_OUT = ROOT / "assets/sprites/water_player_sheet"
MID_OUT = ROOT / "assets/tiles/ch1_snow_mid"


def edge_key_transparent(image: Image.Image, bg_predicate) -> Image.Image:
    image = image.convert("RGBA")
    px = image.load()
    width, height = image.size
    visited = [[False] * height for _ in range(width)]
    queue: deque[tuple[int, int]] = deque()

    def try_add(x: int, y: int) -> None:
        if visited[x][y]:
            return
        visited[x][y] = True
        if bg_predicate(px[x, y]):
            queue.append((x, y))

    for x in range(width):
        try_add(x, 0)
        try_add(x, height - 1)
    for y in range(height):
        try_add(0, y)
        try_add(width - 1, y)

    while queue:
        x, y = queue.popleft()
        r, g, b, _a = px[x, y]
        px[x, y] = (r, g, b, 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height and not visited[nx][ny]:
                visited[nx][ny] = True
                if bg_predicate(px[nx, ny]):
                    queue.append((nx, ny))

    return image


def build_player_sheet_frames() -> None:
    PLAYER_OUT.mkdir(parents=True, exist_ok=True)
    motion = Image.open(ORIG / "水灵轻移动逐帧动画.png").convert("RGBA")

    def motion_bg(pixel) -> bool:
        r, g, b, a = pixel
        return a > 0 and r > 244 and g > 244 and b > 244 and max(r, g, b) - min(r, g, b) < 6

    motion = edge_key_transparent(motion, motion_bg)
    frame_width = 181
    frame_count = 8
    for index in range(frame_count):
        cell = motion.crop((index * frame_width, 0, (index + 1) * frame_width, motion.height))
        bbox = cell.getbbox()
        if bbox:
            pad = 8
            left = max(0, bbox[0] - pad)
            top = max(0, bbox[1] - pad)
            right = min(cell.width, bbox[2] + pad)
            bottom = min(cell.height, bbox[3] + pad)
            cell = cell.crop((left, top, right, bottom))
        cell.save(PLAYER_OUT / f"move_sheet_{index:02d}.png")

    lines = ['[gd_resource type="SpriteFrames" load_steps=15 format=3]', ""]
    ext_id = 1
    for index in range(6):
        lines.append(
            f'[ext_resource type="Texture2D" path="res://assets/sprites/water_player/idle_{index:02d}.png" id="{ext_id}"]'
        )
        ext_id += 1
    for index in range(8):
        lines.append(
            f'[ext_resource type="Texture2D" path="res://assets/sprites/water_player_sheet/move_sheet_{index:02d}.png" id="{ext_id}"]'
        )
        ext_id += 1

    lines += ["", "[resource]", "animations = [", "{", '"frames": [']
    for index in range(6):
        comma = "," if index < 5 else ""
        lines.append(f'{{"duration": 1.0, "texture": ExtResource("{index + 1}")}}{comma}')
    lines += [
        "],",
        '"loop": true,',
        '"name": &"idle",',
        '"speed": 6.0',
        "},",
        "{",
        '"frames": [',
    ]
    for index in range(8):
        comma = "," if index < 7 else ""
        lines.append(f'{{"duration": 1.0, "texture": ExtResource("{index + 7}")}}{comma}')
    lines += [
        "],",
        '"loop": true,',
        '"name": &"move",',
        '"speed": 10.0',
        "}",
        "]",
    ]
    (PLAYER_OUT / "water_player_sheet_frames.tres").write_text("\n".join(lines), encoding="utf-8")


def build_midground_tiles() -> None:
    MID_OUT.mkdir(parents=True, exist_ok=True)
    snow = Image.open(ORIG / "可拼接的中景雪坡:冰面:山体边缘素材.png").convert("RGBA")

    def snow_bg(pixel) -> bool:
        r, g, b, a = pixel
        return a > 0 and r > 232 and g > 232 and b > 232 and max(r, g, b) - min(r, g, b) < 12

    snow = edge_key_transparent(snow, snow_bg)
    crops = {
        "snow_platform_long_01": (10, 8, 222, 91),
        "snow_platform_slope_01": (438, 7, 624, 96),
        "snow_platform_slope_02": (838, 7, 1043, 96),
        "ice_platform_long_01": (617, 256, 853, 331),
        "ice_crack_01": (21, 378, 181, 463),
        "ice_crack_02": (181, 378, 389, 463),
        "cliff_block_01": (16, 612, 185, 770),
        "cliff_block_02": (848, 1047, 1248, 1248),
        "snow_column_01": (925, 521, 1004, 748),
        "snow_column_02": (1007, 521, 1086, 748),
        "mist_patch_01": (20, 897, 178, 1058),
        "mist_patch_02": (836, 893, 1046, 1058),
    }
    for name, box in crops.items():
        tile = snow.crop(box)
        bbox = tile.getbbox()
        if bbox:
            pad = 4
            left = max(0, bbox[0] - pad)
            top = max(0, bbox[1] - pad)
            right = min(tile.width, bbox[2] + pad)
            bottom = min(tile.height, bbox[3] + pad)
            tile = tile.crop((left, top, right, bottom))
        tile.save(MID_OUT / f"{name}.png")


def main() -> None:
    build_player_sheet_frames()
    build_midground_tiles()


if __name__ == "__main__":
    main()
