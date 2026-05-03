from pathlib import Path
from collections import deque
from PIL import Image, ImageFilter


ROOT = Path("/Users/mistluo/Codes/godot/WaterJourney")
SOURCE = ROOT / "assets/originals/新灵气版本/水滴分层：外轮廓、主体水色、内亮核、高光:泡泡分离版.png"
POSE_SOURCE = ROOT / "assets/originals/新灵气版本/更干净的 start : stop : nestle : leave 专用关键帧.png"
OUT_DIR = ROOT / "assets/sprites/water_player_layers"

CANVAS_SIZE = (320, 360)
STATES = ("start", "idle", "nestle", "leave")
LAYERS = ("outline", "body", "core", "highlight")
POSES = ("start", "stop", "nestle", "leave")


def is_checker_background(pixel) -> bool:
    r, g, b, a = pixel
    return a > 0 and r > 218 and g > 218 and b > 218 and max(r, g, b) - min(r, g, b) < 30


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


def trim_to_alpha(image: Image.Image, pad: int = 8) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if not bbox:
        return image
    left = max(0, bbox[0] - pad)
    top = max(0, bbox[1] - pad)
    right = min(image.width, bbox[2] + pad)
    bottom = min(image.height, bbox[3] + pad)
    return image.crop((left, top, right, bottom))


def scale_to_canvas(image: Image.Image) -> Image.Image:
    max_w = CANVAS_SIZE[0] - 18
    max_h = CANVAS_SIZE[1] - 18
    scale = min(max_w / image.width, max_h / image.height, 1.0)
    return image.resize((max(1, int(image.width * scale)), max(1, int(image.height * scale))), Image.Resampling.LANCZOS)


def center_on_canvas(image: Image.Image) -> Image.Image:
    image = scale_to_canvas(trim_to_alpha(image))
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    x = (CANVAS_SIZE[0] - image.width) // 2
    y = CANVAS_SIZE[1] - image.height - 18
    canvas.alpha_composite(image, (x, y))
    return canvas


def multiply_alpha(image: Image.Image, alpha_mul: float, blur: float = 0.0) -> Image.Image:
    image = image.copy()
    alpha = image.getchannel("A")
    if blur > 0:
        alpha = alpha.filter(ImageFilter.GaussianBlur(blur))
    alpha = alpha.point(lambda a: min(255, int(a * alpha_mul)))
    image.putalpha(alpha)
    return image


def crop_cell(sheet: Image.Image, col: int, row: int) -> Image.Image:
    cell_w = sheet.width // 4
    cell_h = sheet.height // 4
    cell = sheet.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
    return edge_key_transparent(cell)


def write_layer_index() -> None:
    lines = [
        "# Water Player Layers",
        "",
        "Generated from `assets/originals/新灵气版本/水滴分层：外轮廓、主体水色、内亮核、高光:泡泡分离版.png`.",
        "",
        "- `outline_*`: real outline and splash edge layers.",
        "- `body_*`: separated water color body layers, reserved for future full compositing.",
        "- `core_*`: inner spirit/glow and facial core layers.",
        "- `highlight_*`: surface highlight, bubbles, and rim shimmer layers.",
        "- `trail_motion` / `trail_leave`: derived soft trail layers for runtime feedback.",
        "- `pose_*`: cleaned key-pose overlays generated from the dedicated start/stop/nestle/leave sheet.",
    ]
    (OUT_DIR / "LAYER_INDEX.md").write_text("\n".join(lines), encoding="utf-8")


def build_pose_overlays() -> None:
    sheet = Image.open(POSE_SOURCE).convert("RGBA")
    cell_w = sheet.width // 2
    cell_h = sheet.height // 2
    boxes = [
        (0, 0, cell_w, cell_h),
        (cell_w, 0, sheet.width, cell_h),
        (0, cell_h, cell_w, sheet.height),
        (cell_w, cell_h, sheet.width, sheet.height),
    ]
    for pose_name, box in zip(POSES, boxes):
        pose = center_on_canvas(edge_key_transparent(sheet.crop(box)))
        pose = multiply_alpha(pose, 0.56, 0.35)
        pose.save(OUT_DIR / f"pose_{pose_name}.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(SOURCE).convert("RGBA")
    generated: dict[tuple[str, str], Image.Image] = {}

    for row, layer in enumerate(LAYERS):
        for col, state in enumerate(STATES):
            canvas = center_on_canvas(crop_cell(sheet, col, row))
            generated[(layer, state)] = canvas
            canvas.save(OUT_DIR / f"{layer}_{state}.png")

    trail_motion = multiply_alpha(generated[("highlight", "start")], 0.42, 1.1)
    trail_leave = multiply_alpha(generated[("highlight", "leave")], 0.5, 1.0)
    trail_motion.save(OUT_DIR / "trail_motion.png")
    trail_leave.save(OUT_DIR / "trail_leave.png")
    build_pose_overlays()
    write_layer_index()


if __name__ == "__main__":
    main()
