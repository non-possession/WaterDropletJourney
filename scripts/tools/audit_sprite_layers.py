from pathlib import Path
from PIL import Image


ROOT = Path("/Users/mistluo/Codes/godot/WaterJourney")
TARGETS = [
    ROOT / "assets/sprites/water_player_spirit",
    ROOT / "assets/sprites/water_player_layers",
    ROOT / "assets/sprites/bush_interaction",
]


def alpha_corners(image: Image.Image) -> list[int]:
    width, height = image.size
    return [
        image.getpixel((0, 0))[3],
        image.getpixel((width - 1, 0))[3],
        image.getpixel((0, height - 1))[3],
        image.getpixel((width - 1, height - 1))[3],
    ]


def main() -> None:
    failed = False
    for folder in TARGETS:
        print(f"\n{folder.relative_to(ROOT)}")
        sizes: set[tuple[int, int]] = set()
        for path in sorted(folder.glob("*.png")):
            image = Image.open(path).convert("RGBA")
            sizes.add(image.size)
            bbox = image.getchannel("A").getbbox()
            corners = alpha_corners(image)
            has_opaque_corner = any(value > 0 for value in corners)
            status = "FAIL" if has_opaque_corner else "OK"
            if has_opaque_corner:
                failed = True
            print(f"{status} {path.name}: size={image.size} bbox={bbox} cornersA={corners}")
        if len(sizes) > 1:
            print(f"NOTE mixed canvas sizes: {sorted(sizes)}")
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
