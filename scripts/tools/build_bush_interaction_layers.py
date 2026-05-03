from pathlib import Path
from PIL import Image, ImageFilter


ROOT = Path("/Users/mistluo/Codes/godot/WaterJourney")
SOURCE = ROOT / "assets/originals/toyv1_bush_layers_sheet.png"
OUT = ROOT / "assets/sprites/bush_interaction"
CANVAS_SIZE = (704, 704)


def chroma_to_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # The sheet uses a flat #ff00ff key. Distance keeps antialiased foliage
            # edges while removing the saturated magenta card completely.
            distance = ((r - 255) ** 2 + g**2 + (b - 255) ** 2) ** 0.5
            if distance < 22:
                pixels[x, y] = (r, g, b, 0)
            elif r > 210 and b > 210 and g < 96:
                alpha = int(min(255, max(0, (distance - 22) * 3.1)))
                pixels[x, y] = (r, g, b, min(a, alpha))

    return image


def trim(image: Image.Image, padding: int = 12) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if not bbox:
        return image
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(image.width, bbox[2] + padding)
    bottom = min(image.height, bbox[3] + padding)
    return image.crop((left, top, right, bottom))


def normalize_canvas(image: Image.Image, y_bias: int = 0) -> Image.Image:
    """Put each layer on the same transparent canvas so anchors stay stable."""
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    x = (CANVAS_SIZE[0] - image.width) // 2
    y = (CANVAS_SIZE[1] - image.height) // 2 + y_bias
    canvas.alpha_composite(image, (x, y))
    return canvas


def make_presence_mask(image: Image.Image) -> Image.Image:
    image = chroma_to_alpha(image)
    alpha = image.getchannel("A").filter(ImageFilter.GaussianBlur(1.4))
    mask = Image.new("RGBA", image.size, (173, 255, 218, 0))
    mask.putalpha(alpha)
    return mask


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(SOURCE).convert("RGBA")
    half_width = sheet.width // 2
    half_height = sheet.height // 2
    cells = {
        "back_leaves": (0, 0, half_width, half_height),
        "front_leaves": (half_width, 0, sheet.width, half_height),
        "contact_leaves": (0, half_height, half_width, sheet.height),
        "local_glow_mask": (half_width, half_height, sheet.width, sheet.height),
    }

    for name, box in cells.items():
        crop = sheet.crop(box)
        if name == "local_glow_mask":
            layer = make_presence_mask(crop)
            layer = normalize_canvas(trim(layer, 18), 18)
        else:
            layer = trim(chroma_to_alpha(crop), 16)
            y_bias = 28 if name == "contact_leaves" else 0
            layer = normalize_canvas(layer, y_bias)
        layer.save(OUT / f"{name}.png")


if __name__ == "__main__":
    main()
