from pathlib import Path
from collections import deque
from PIL import Image, ImageFilter, ImageEnhance


ROOT = Path("/Users/mistluo/Codes/godot/WaterJourney")
IDLE_SRC_DIR = ROOT / "assets/sprites/water_idle"
STATE_DIR = ROOT / "assets/sprites/water_states"
PLAYER_DIR = ROOT / "assets/sprites/water_player"
SIBLING_DIR = ROOT / "assets/sprites/water_siblings"


def checker_bg(pixel) -> bool:
    r, g, b, a = pixel
    return a > 0 and r > 232 and g > 232 and b > 232 and max(r, g, b) - min(r, g, b) < 20


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


def trim_to_alpha(image: Image.Image, pad: int) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if not bbox:
        return image
    left = max(0, bbox[0] - pad)
    top = max(0, bbox[1] - pad)
    right = min(image.width, bbox[2] + pad)
    bottom = min(image.height, bbox[3] + pad)
    return image.crop((left, top, right, bottom))


def center_on_canvas(image: Image.Image, canvas_size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    x = (canvas_size[0] - image.width) // 2
    y = (canvas_size[1] - image.height) // 2
    canvas.alpha_composite(image, (x, y))
    return canvas


def sanitize_idle_sources() -> None:
    idle_paths = [IDLE_SRC_DIR / f"idle_{i:02d}.png" for i in range(6)]
    cleaned_frames = [trim_to_alpha(edge_key_transparent(Image.open(p).convert("RGBA"), checker_bg), 12) for p in idle_paths]
    canvas_w = max(img.width for img in cleaned_frames) + 24
    canvas_h = max(img.height for img in cleaned_frames) + 24
    for path, img in zip(idle_paths, cleaned_frames):
        center_on_canvas(img, (canvas_w, canvas_h)).save(path)


def sanitize_state_sources() -> None:
    state_paths = sorted(STATE_DIR.glob("*.png"))
    cleaned_states = [trim_to_alpha(edge_key_transparent(Image.open(p).convert("RGBA"), checker_bg), 12) for p in state_paths]
    canvas_w = max(img.width for img in cleaned_states) + 20
    canvas_h = max(img.height for img in cleaned_states) + 20
    for path, img in zip(state_paths, cleaned_states):
        center_on_canvas(img, (canvas_w, canvas_h)).save(path)


def build_player_frames() -> None:
    sanitize_idle_sources()
    idle_paths = [IDLE_SRC_DIR / f"idle_{i:02d}.png" for i in range(6)]
    frames = [Image.open(p).convert("RGBA") for p in idle_paths]
    bboxes = [img.getchannel("A").getbbox() for img in frames]
    left = min(b[0] for b in bboxes)
    top = min(b[1] for b in bboxes)
    right = max(b[2] for b in bboxes)
    bottom = max(b[3] for b in bboxes)
    pad = 20
    common_box = (
        max(left - pad, 0),
        max(top - pad, 0),
        min(right + pad, frames[0].width),
        min(bottom + pad, frames[0].height),
    )

    compact_frames = []
    for i, img in enumerate(frames):
        comp = img.crop(common_box)
        compact_frames.append(comp)
        comp.save(PLAYER_DIR / f"idle_compact_{i:02d}.png")

    canvas_w = max(img.width for img in compact_frames) + 36
    canvas_h = max(img.height for img in compact_frames) + 24

    for i, img in enumerate(compact_frames):
        canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
        x = (canvas_w - img.width) // 2
        y = (canvas_h - img.height) // 2
        canvas.alpha_composite(img, (x, y))
        canvas.save(PLAYER_DIR / f"idle_{i:02d}.png")

        stretch_x = 1.05 + (0.04 if i % 2 == 0 else 0.0)
        stretch_y = 0.96 - (0.02 if i in (1, 4) else 0.0)
        resized = img.resize(
            (int(img.width * stretch_x), int(img.height * stretch_y)),
            Image.Resampling.LANCZOS,
        )
        trail = resized.copy()
        alpha = trail.getchannel("A").point(lambda a: int(a * 0.22))
        trail.putalpha(alpha)

        move_canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
        move_x = (canvas_w - resized.width) // 2 + (-8 if i < 3 else 8)
        move_y = (canvas_h - resized.height) // 2 + (3 if i in (1, 2, 4) else 0)
        move_canvas.alpha_composite(trail, (move_x - 10, move_y + 2))
        move_canvas.alpha_composite(resized, (move_x, move_y))
        move_canvas.save(PLAYER_DIR / f"move_{i:02d}.png")

    _write_player_spriteframes()


def make_variant(
    src_name: str,
    out_name: str,
    size=(96, 96),
    alpha_mul=1.0,
    tint=(255, 255, 255),
    blur=0.0,
    bright=1.0,
    contrast=1.0,
) -> None:
    img = Image.open(STATE_DIR / src_name).convert("RGBA")
    bbox = img.getchannel("A").getbbox()
    img = img.crop(bbox)
    scale = min((size[0] - 8) / img.width, (size[1] - 8) / img.height)
    img = img.resize(
        (max(1, int(img.width * scale)), max(1, int(img.height * scale))),
        Image.Resampling.LANCZOS,
    )
    if blur > 0:
        img = img.filter(ImageFilter.GaussianBlur(blur))
    if bright != 1.0:
        img = ImageEnhance.Brightness(img).enhance(bright)
    if contrast != 1.0:
        img = ImageEnhance.Contrast(img).enhance(contrast)
    r_t, g_t, b_t = tint
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (
                int(r * r_t / 255),
                int(g * g_t / 255),
                int(b * b_t / 255),
                int(a * alpha_mul),
            )
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(img, ((size[0] - img.width) // 2, (size[1] - img.height) // 2))
    canvas.save(SIBLING_DIR / out_name)


def build_sibling_variants() -> None:
    sanitize_state_sources()
    make_variant("water_cold.png", "sibling_still_ice_01.png", alpha_mul=0.62, tint=(235, 245, 255), bright=0.95, contrast=1.08)
    make_variant("water_resting.png", "sibling_still_rest_01.png", alpha_mul=0.5, tint=(230, 240, 255), bright=0.92)
    make_variant("water_calm.png", "sibling_intent_01.png", alpha_mul=0.72, tint=(255, 255, 255), bright=1.04, contrast=1.06)
    make_variant("water_tense.png", "sibling_intent_02.png", alpha_mul=0.62, tint=(245, 250, 255), bright=1.0)
    make_variant("water_evaporating.png", "sibling_drift_01.png", alpha_mul=0.42, tint=(240, 248, 255), blur=0.6, bright=1.06)
    make_variant("water_calm.png", "sibling_snow_01.png", alpha_mul=0.28, tint=(248, 250, 255), blur=0.8, bright=1.1)


def _write_player_spriteframes() -> None:
    lines = ['[gd_resource type="SpriteFrames" load_steps=13 format=3]', ""]
    idx = 1
    for prefix in ("idle", "move"):
        for i in range(6):
            name = f"{prefix}_{i:02d}.png"
            lines.append(
                f'[ext_resource type="Texture2D" path="res://assets/sprites/water_player/{name}" id="{idx}"]'
            )
            idx += 1
    lines += [
        "",
        "[resource]",
        "animations = [",
        "{",
        '"frames": [',
    ]
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
    for i in range(6):
        comma = "," if i < 5 else ""
        lines.append(f'{{"duration": 1.0, "texture": ExtResource("{i + 7}")}}{comma}')
    lines += [
        "],",
        '"loop": true,',
        '"name": &"move",',
        '"speed": 9.0',
        "}",
        "]",
    ]
    (PLAYER_DIR / "water_player_frames.tres").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    PLAYER_DIR.mkdir(parents=True, exist_ok=True)
    SIBLING_DIR.mkdir(parents=True, exist_ok=True)
    build_player_frames()
    build_sibling_variants()


if __name__ == "__main__":
    main()
