from pathlib import Path
from collections import deque
from PIL import Image, ImageEnhance, ImageFilter


ROOT = Path("/Users/mistluo/Codes/godot/WaterJourney")
SOURCE = ROOT / "assets/originals/新灵气版本/ChatGPT Image 2026年4月23日 12_42_07.png"
OUT_DIR = ROOT / "assets/sprites/water_player_spirit"

CANVAS_SIZE = (320, 360)
SPRITE_HEIGHT = 285


def is_checker_background(pixel) -> bool:
    r, g, b, a = pixel
    return a > 0 and r > 218 and g > 218 and b > 218 and max(r, g, b) - min(r, g, b) < 28


def edge_key_transparent(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    px = image.load()
    width, height = image.size
    visited = [[False] * height for _ in range(width)]
    queue: deque[tuple[int, int]] = deque()

    def try_add(x: int, y: int) -> None:
        if visited[x][y]:
            return
        visited[x][y] = True
        if is_checker_background(px[x, y]):
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
                if is_checker_background(px[nx, ny]):
                    queue.append((nx, ny))

    return image


def trim_to_alpha(image: Image.Image, pad: int = 12) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if not bbox:
        return image
    left = max(0, bbox[0] - pad)
    top = max(0, bbox[1] - pad)
    right = min(image.width, bbox[2] + pad)
    bottom = min(image.height, bbox[3] + pad)
    return image.crop((left, top, right, bottom))


def soften_and_tone(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    image = ImageEnhance.Color(image).enhance(0.9)
    image = ImageEnhance.Contrast(image).enhance(0.94)
    image = ImageEnhance.Brightness(image).enhance(0.98)

    alpha = image.getchannel("A")
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.45))
    alpha = alpha.point(lambda a: min(242, int(a * 0.94)))
    image.putalpha(alpha)
    return image


def scale_to_height(image: Image.Image, target_height: int) -> Image.Image:
    scale = target_height / image.height
    width = max(1, int(image.width * scale))
    return image.resize((width, target_height), Image.Resampling.LANCZOS)


def paste_centered(image: Image.Image, y_offset: int = 0, x_offset: int = 0) -> Image.Image:
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    x = (CANVAS_SIZE[0] - image.width) // 2 + x_offset
    y = CANVAS_SIZE[1] - image.height - 22 + y_offset
    canvas.alpha_composite(image, (x, y))
    return canvas


def resize_variant(image: Image.Image, scale_x: float, scale_y: float) -> Image.Image:
    return image.resize(
        (max(1, int(image.width * scale_x)), max(1, int(image.height * scale_y))),
        Image.Resampling.LANCZOS,
    )


def make_trail(image: Image.Image, alpha_mul: float, blur: float = 1.2) -> Image.Image:
    trail = image.copy()
    alpha = trail.getchannel("A").filter(ImageFilter.GaussianBlur(blur))
    alpha = alpha.point(lambda a: int(a * alpha_mul))
    trail.putalpha(alpha)
    return trail


def make_silhouette_overlay(image: Image.Image, out_name: str, color: tuple[int, int, int], alpha_mul: float, blur: float = 1.0) -> None:
    alpha = image.getchannel("A").filter(ImageFilter.GaussianBlur(blur))
    alpha = alpha.point(lambda a: int(a * alpha_mul))
    overlay = Image.new("RGBA", image.size, (*color, 0))
    overlay.putalpha(alpha)
    overlay.save(OUT_DIR / out_name)


def make_inner_glow(image: Image.Image) -> None:
    alpha = image.getchannel("A").filter(ImageFilter.GaussianBlur(8.0))
    alpha = alpha.point(lambda a: int(a * 0.42))
    glow = Image.new("RGBA", image.size, (120, 245, 255, 0))
    glow.putalpha(alpha)
    glow.save(OUT_DIR / "inner_glow.png")


def extract_cell(sheet: Image.Image, index: int) -> Image.Image:
    cols = 4
    rows = 2
    cell_width = sheet.width // cols
    cell_height = sheet.height // rows
    col = index % cols
    row = index // cols
    cell = sheet.crop((col * cell_width, row * cell_height, (col + 1) * cell_width, (row + 1) * cell_height))
    return trim_to_alpha(edge_key_transparent(cell), 16)


def write_spriteframes() -> None:
    lines = ['[gd_resource type="SpriteFrames" load_steps=15 format=3]', ""]
    ext_id = 1
    for prefix, count in (("idle", 6), ("move", 8)):
        for i in range(count):
            lines.append(
                f'[ext_resource type="Texture2D" path="res://assets/sprites/water_player_spirit/{prefix}_{i:02d}.png" id="{ext_id}"]'
            )
            ext_id += 1

    lines += ["", "[resource]", "animations = [", "{", '"frames": [']
    for i in range(6):
        comma = "," if i < 5 else ""
        lines.append(f'{{"duration": 1.0, "texture": ExtResource("{i + 1}")}}{comma}')
    lines += [
        "],",
        '"loop": true,',
        '"name": &"idle",',
        '"speed": 6.0',
        "},",
        "{",
        '"frames": [',
    ]
    for i in range(8):
        comma = "," if i < 7 else ""
        lines.append(f'{{"duration": 1.0, "texture": ExtResource("{i + 7}")}}{comma}')
    lines += [
        "],",
        '"loop": true,',
        '"name": &"move",',
        '"speed": 10.0',
        "}",
        "]",
    ]
    (OUT_DIR / "water_player_spirit_frames.tres").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(SOURCE).convert("RGBA")
    calm = soften_and_tone(scale_to_height(extract_cell(sheet, 0), SPRITE_HEIGHT))
    closed = soften_and_tone(scale_to_height(extract_cell(sheet, 2), SPRITE_HEIGHT - 4))
    moving = soften_and_tone(scale_to_height(extract_cell(sheet, 7), SPRITE_HEIGHT - 6))

    idle_specs = [
        (calm, 0.985, 1.010, 0, 0),
        (calm, 1.000, 0.995, 1, 0),
        (calm, 1.012, 0.985, 2, 0),
        (closed, 0.995, 1.005, 1, 0),
        (calm, 1.006, 0.990, 2, 0),
        (calm, 0.992, 1.008, 0, 0),
    ]
    for i, (src, sx, sy, y_offset, x_offset) in enumerate(idle_specs):
        frame = paste_centered(resize_variant(src, sx, sy), y_offset, x_offset)
        frame.save(OUT_DIR / f"idle_{i:02d}.png")
        if i == 0:
            make_silhouette_overlay(frame, "overlay_calm.png", (180, 245, 255), 0.32, 1.2)
            make_silhouette_overlay(frame, "overlay_tense.png", (210, 250, 255), 0.42, 0.6)
            make_silhouette_overlay(frame, "overlay_cold.png", (236, 250, 255), 0.48, 0.35)
            make_inner_glow(frame)

    move_specs = [
        (1.010, 0.990, 1, 4, 0.08),
        (1.055, 0.965, 2, 8, 0.12),
        (1.095, 0.940, 4, 12, 0.16),
        (1.060, 0.965, 3, 10, 0.12),
        (1.025, 0.985, 1, 6, 0.08),
        (0.995, 1.010, 0, 2, 0.05),
        (1.040, 0.970, 2, 7, 0.10),
        (1.085, 0.945, 4, 12, 0.15),
    ]
    for i, (sx, sy, y_offset, x_offset, trail_alpha) in enumerate(move_specs):
        body = resize_variant(moving, sx, sy)
        trail = make_trail(body, trail_alpha)
        canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
        x = (CANVAS_SIZE[0] - body.width) // 2 + x_offset
        y = CANVAS_SIZE[1] - body.height - 22 + y_offset
        canvas.alpha_composite(trail, (x - 18, y + 5))
        canvas.alpha_composite(body, (x, y))
        canvas.save(OUT_DIR / f"move_{i:02d}.png")

    write_spriteframes()


if __name__ == "__main__":
    main()
