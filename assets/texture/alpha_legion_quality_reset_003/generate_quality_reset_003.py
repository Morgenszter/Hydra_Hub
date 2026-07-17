from __future__ import annotations

import math
import os
import random
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent


TEAL = (0, 165, 150, 255)
CYAN_DIM = (35, 220, 200, 255)
STEEL = (22, 30, 32)
BLACK = (0, 0, 0, 0)
SCREEN_GREEN = (4, 30, 26)


@dataclass(frozen=True)
class PanelSpec:
    stem: str
    size: tuple[int, int]
    kind: str
    seed: int
    description: str


SPECS = [
    PanelSpec("ALP3_S01_Voice_Hub_Terminal_Screen", (4096, 1536), "voice", 3301, "wide Voice HUB terminal screen panel"),
    PanelSpec("ALP3_S02_Central_Status_Armored_Display", (4096, 2304), "central", 3302, "central armored status display panel"),
    PanelSpec("ALP3_S03_LED_RGB_Heater_Hex_Screen", (4096, 4096), "hex", 3303, "hexagonal LED/RGB/heater control screen"),
    PanelSpec("ALP3_S04_Right_Weather_Auspex_Screen", (3072, 4096), "weather", 3304, "right-side weather auspex screen panel"),
    PanelSpec("ALP3_S05_Cogitator_Message_Display", (4096, 2304), "message", 3305, "cogitator message display with dark CRT glass"),
]


def s(width: int, height: int, v: float) -> int:
    return int(round(min(width, height) * v))


def rgba(color, alpha=None):
    if alpha is None:
        return color
    return color[:3] + (alpha,)


def poly_mask(size: tuple[int, int], points) -> Image.Image:
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).polygon(points, fill=255)
    return m


def rounded_mask(size: tuple[int, int], box, radius: int) -> Image.Image:
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle(box, radius=radius, fill=255)
    return m


def hex_points(cx, cy, r, rot=math.pi / 6):
    return [(int(cx + math.cos(rot + i * math.tau / 6) * r), int(cy + math.sin(rot + i * math.tau / 6) * r)) for i in range(6)]


def subtract(a: Image.Image, b: Image.Image) -> Image.Image:
    return ImageChops.subtract(a, b)


def material_layer(size: tuple[int, int], mask: Image.Image, seed: int, base=STEEL) -> Image.Image:
    w, h = size
    rng = np.random.default_rng(seed)
    a = np.asarray(mask, dtype=np.uint8)
    yy = np.linspace(0, 1, h, dtype=np.float32)[:, None]
    xx = np.linspace(0, 1, w, dtype=np.float32)[None, :]
    grain = rng.normal(0, 1, (h, w)).astype(np.float32)
    grain = (grain + np.roll(grain, 11, axis=0) + np.roll(grain, 29, axis=1)) / 3.0
    brushed = 0.50 + 0.20 * np.sin(xx * 120.0 + seed * 0.013) + 0.10 * np.cos(yy * 41.0 + seed * 0.023)
    shade = np.clip(brushed + grain * 0.065, 0.0, 1.0)
    # A stronger top-left highlight and bottom-right mass makes the metal read as 2.5D.
    bevel_light = np.clip(1.22 - xx * 0.36 - yy * 0.44, 0.70, 1.25)
    arr = np.zeros((h, w, 4), dtype=np.uint8)
    for i, c in enumerate(base):
        arr[:, :, i] = np.clip(c * (0.65 + shade * 0.72) * bevel_light, 0, 255).astype(np.uint8)
    arr[:, :, 1] = np.clip(arr[:, :, 1] + (a > 0) * 8, 0, 255)
    arr[:, :, 2] = np.clip(arr[:, :, 2] + (a > 0) * 7, 0, 255)
    arr[:, :, 3] = a
    return Image.fromarray(arr, "RGBA")


def screen_layer(size: tuple[int, int], mask: Image.Image, seed: int) -> Image.Image:
    w, h = size
    rng = np.random.default_rng(seed)
    a = np.asarray(mask, dtype=np.uint8)
    yy = np.linspace(0, 1, h, dtype=np.float32)[:, None]
    xx = np.linspace(0, 1, w, dtype=np.float32)[None, :]
    noise = rng.normal(0, 1, (h, w)).astype(np.float32)
    scan = 0.75 + 0.10 * np.sin(yy * h * math.pi / 3.0)
    vignette = 1.0 - 0.55 * np.clip(((xx - 0.5) ** 2 + (yy - 0.5) ** 2) * 2.6, 0, 1)
    glow = np.clip(scan * vignette + noise * 0.025, 0, 1)
    arr = np.zeros((h, w, 4), dtype=np.uint8)
    arr[:, :, 0] = np.clip(SCREEN_GREEN[0] + glow * 10, 0, 255).astype(np.uint8)
    arr[:, :, 1] = np.clip(SCREEN_GREEN[1] + glow * 34, 0, 255).astype(np.uint8)
    arr[:, :, 2] = np.clip(SCREEN_GREEN[2] + glow * 30, 0, 255).astype(np.uint8)
    arr[:, :, 3] = np.minimum(a, 238)
    return Image.fromarray(arr, "RGBA")


def alpha_clip(layer: Image.Image, mask: Image.Image) -> Image.Image:
    out = layer.copy()
    out.putalpha(ImageChops.multiply(out.getchannel("A"), mask))
    return out


def glow(size: tuple[int, int], mask: Image.Image, color, blur: int, scale: float) -> Image.Image:
    a = mask.filter(ImageFilter.GaussianBlur(blur)).point(lambda x: int(min(255, x * scale)))
    layer = Image.new("RGBA", size, color)
    layer.putalpha(a)
    return layer


def bevel_layers(size: tuple[int, int], mask: Image.Image) -> list[Image.Image]:
    w, h = size
    edge = mask.filter(ImageFilter.FIND_EDGES)
    hi = Image.new("RGBA", size, (190, 235, 225, 0))
    sh = Image.new("RGBA", size, (0, 0, 0, 0))
    hi_a = ImageChops.multiply(edge, Image.linear_gradient("L").resize(size).transpose(Image.Transpose.ROTATE_180))
    sh_a = ImageChops.multiply(edge, Image.linear_gradient("L").resize(size))
    hi.putalpha(hi_a.point(lambda x: int(x * 0.70)))
    sh.putalpha(sh_a.point(lambda x: int(x * 0.95)))
    return [sh, hi]


def scratches(size: tuple[int, int], mask: Image.Image, seed: int, amount: int) -> Image.Image:
    w, h = size
    rng = random.Random(seed)
    layer = Image.new("RGBA", size, BLACK)
    d = ImageDraw.Draw(layer, "RGBA")
    for _ in range(amount):
        x = rng.randint(0, w - 1)
        y = rng.randint(0, h - 1)
        if mask.getpixel((x, y)) < 20:
            continue
        length = rng.randint(s(w, h, 0.006), s(w, h, 0.035))
        angle = rng.uniform(-0.28, 0.28)
        x2 = int(x + math.cos(angle) * length)
        y2 = int(y + math.sin(angle) * length)
        if rng.random() < 0.70:
            col = (160, 205, 195, rng.randint(15, 48))
        else:
            col = (0, 0, 0, rng.randint(35, 90))
        d.line((x, y, x2, y2), fill=col, width=rng.randint(1, 3))
    return alpha_clip(layer, mask)


def rivet(d: ImageDraw.ImageDraw, x: int, y: int, r: int, accent=TEAL) -> None:
    d.ellipse((x - r, y - r, x + r, y + r), fill=(5, 8, 9, 230), outline=(115, 150, 145, 170), width=max(2, r // 10))
    d.ellipse((x - r // 2, y - r // 2, x + r // 2, y + r // 2), fill=(22, 35, 36, 255), outline=accent[:3] + (100,), width=max(1, r // 16))
    d.arc((x - r, y - r, x + r, y + r), 210, 330, fill=(215, 250, 240, 100), width=max(2, r // 12))


def draw_scale_notches(d: ImageDraw.ImageDraw, box, count: int, accent=TEAL) -> None:
    x0, y0, x1, y1 = box
    for i in range(count):
        t = (i + 0.5) / count
        x = int(x0 + (x1 - x0) * t)
        y = int((y0 + y1) / 2)
        r = int(min(x1 - x0, y1 - y0) * 0.035)
        pts = [(x, y - r), (x + r, y), (x, y + r), (x - r, y)]
        d.line(pts + [pts[0]], fill=accent[:3] + (70,), width=max(2, r // 7))


def panel_masks(spec: PanelSpec) -> tuple[Image.Image, Image.Image, Image.Image]:
    w, h = spec.size
    u = min(w, h)
    if spec.kind == "voice":
        outer = poly_mask(spec.size, [
            (int(w * 0.035), int(h * 0.20)),
            (int(w * 0.80), int(h * 0.20)),
            (int(w * 0.96), int(h * 0.40)),
            (int(w * 0.91), int(h * 0.80)),
            (int(w * 0.08), int(h * 0.80)),
            (int(w * 0.035), int(h * 0.62)),
        ])
        inner = rounded_mask(spec.size, (int(w * 0.12), int(h * 0.34), int(w * 0.78), int(h * 0.66)), s(w, h, 0.025))
        trim = rounded_mask(spec.size, (int(w * 0.10), int(h * 0.29), int(w * 0.82), int(h * 0.71)), s(w, h, 0.035))
    elif spec.kind == "central":
        outer = rounded_mask(spec.size, (int(w * 0.11), int(h * 0.10), int(w * 0.89), int(h * 0.90)), s(w, h, 0.045))
        inner = rounded_mask(spec.size, (int(w * 0.22), int(h * 0.22), int(w * 0.78), int(h * 0.78)), s(w, h, 0.025))
        trim = poly_mask(spec.size, hex_points(w // 2, h // 2, int(u * 0.355), math.pi / 8))
    elif spec.kind == "hex":
        outer = poly_mask(spec.size, hex_points(w // 2, h // 2, int(u * 0.420), math.pi / 6))
        inner = poly_mask(spec.size, hex_points(w // 2, h // 2, int(u * 0.255), math.pi / 6))
        trim = poly_mask(spec.size, hex_points(w // 2, h // 2, int(u * 0.325), math.pi / 6))
    elif spec.kind == "weather":
        outer = rounded_mask(spec.size, (int(w * 0.12), int(h * 0.06), int(w * 0.88), int(h * 0.94)), s(w, h, 0.050))
        inner = rounded_mask(spec.size, (int(w * 0.23), int(h * 0.21), int(w * 0.77), int(h * 0.78)), s(w, h, 0.030))
        trim = rounded_mask(spec.size, (int(w * 0.18), int(h * 0.14), int(w * 0.82), int(h * 0.84)), s(w, h, 0.040))
    else:
        outer = poly_mask(spec.size, [
            (int(w * 0.08), int(h * 0.13)),
            (int(w * 0.86), int(h * 0.13)),
            (int(w * 0.94), int(h * 0.28)),
            (int(w * 0.94), int(h * 0.87)),
            (int(w * 0.14), int(h * 0.87)),
            (int(w * 0.06), int(h * 0.72)),
            (int(w * 0.06), int(h * 0.28)),
        ])
        inner = rounded_mask(spec.size, (int(w * 0.16), int(h * 0.25), int(w * 0.84), int(h * 0.75)), s(w, h, 0.020))
        trim = rounded_mask(spec.size, (int(w * 0.125), int(h * 0.20), int(w * 0.875), int(h * 0.80)), s(w, h, 0.030))
    metal = subtract(outer, inner)
    return outer, inner, trim if spec.kind != "central" else subtract(trim, inner)


def render_panel(spec: PanelSpec) -> Image.Image:
    w, h = spec.size
    rng = random.Random(spec.seed)
    outer, screen, trim = panel_masks(spec)
    metal_mask = subtract(outer, screen)
    img = Image.new("RGBA", spec.size, BLACK)

    # Heavy drop shadow, subtle outer energy only.
    shadow = Image.new("RGBA", spec.size, (0, 0, 0, 170))
    sh_a = outer.filter(ImageFilter.GaussianBlur(s(w, h, 0.020)))
    shadow.putalpha(sh_a)
    img.alpha_composite(shadow, (s(w, h, 0.010), s(w, h, 0.012)))
    img.alpha_composite(glow(spec.size, outer, TEAL, s(w, h, 0.010), 0.16))

    img.alpha_composite(material_layer(spec.size, metal_mask, spec.seed))
    img.alpha_composite(material_layer(spec.size, subtract(trim, screen), spec.seed + 17, (20, 55, 52)))
    img.alpha_composite(screen_layer(spec.size, screen, spec.seed + 99))

    for layer in bevel_layers(spec.size, outer):
        img.alpha_composite(layer)
    for layer in bevel_layers(spec.size, screen):
        img.alpha_composite(layer)
    img.alpha_composite(scratches(spec.size, metal_mask, spec.seed + 200, int((w * h) / 12000)))

    detail = Image.new("RGBA", spec.size, BLACK)
    d = ImageDraw.Draw(detail, "RGBA")
    accent = TEAL if spec.seed % 2 else CYAN_DIM

    # Rivets and mechanical anchors.
    riv = s(w, h, 0.018)
    anchors = [
        (0.16, 0.23), (0.84, 0.23), (0.16, 0.77), (0.84, 0.77)
    ]
    if spec.kind == "voice":
        anchors = [(0.10, 0.31), (0.86, 0.36), (0.13, 0.69), (0.87, 0.70)]
    elif spec.kind == "hex":
        anchors = [(0.50 + math.cos(i * math.tau / 6) * 0.34, 0.50 + math.sin(i * math.tau / 6) * 0.34) for i in range(6)]
    elif spec.kind == "weather":
        anchors = [(0.24, 0.12), (0.76, 0.12), (0.24, 0.88), (0.76, 0.88)]
    for ax, ay in anchors:
        rivet(d, int(w * ax), int(h * ay), riv, accent)

    # Screen interior technical lines, no readable text.
    for i in range(14):
        y = int(h * (0.30 + i * 0.026))
        x0 = int(w * (0.20 + rng.random() * 0.04))
        x1 = int(w * (0.52 + rng.random() * 0.24))
        if spec.kind == "hex":
            y = int(h * (0.40 + i * 0.014))
            x0 = int(w * 0.39)
            x1 = int(w * (0.52 + rng.random() * 0.10))
        d.line((x0, y, x1, y + rng.randint(-2, 2)), fill=accent[:3] + (28,), width=max(2, s(w, h, 0.0015)))

    if spec.kind == "hex":
        for i in range(3):
            ang = i * math.tau / 3 + math.pi / 6
            cx = int(w * 0.5 + math.cos(ang) * min(w, h) * 0.225)
            cy = int(h * 0.5 + math.sin(ang) * min(w, h) * 0.225)
            d.ellipse((cx - s(w, h, 0.040), cy - s(w, h, 0.040), cx + s(w, h, 0.040), cy + s(w, h, 0.040)), outline=accent[:3] + (120,), width=s(w, h, 0.006))
    elif spec.kind == "weather":
        cx, cy, rr = int(w * 0.50), int(h * 0.135), s(w, h, 0.060)
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=accent[:3] + (120,), width=s(w, h, 0.006))
        d.arc((cx - rr * 2, cy - rr * 2, cx + rr * 2, cy + rr * 2), 205, 330, fill=accent[:3] + (70,), width=s(w, h, 0.005))
    elif spec.kind == "central":
        for r in [0.14, 0.22, 0.30]:
            rr = s(w, h, r)
            d.arc((w // 2 - rr, h // 2 - rr, w // 2 + rr, h // 2 + rr), 35, 150, fill=accent[:3] + (85,), width=s(w, h, 0.004))
            d.arc((w // 2 - rr, h // 2 - rr, w // 2 + rr, h // 2 + rr), 215, 318, fill=(180, 220, 210, 55), width=s(w, h, 0.003))

    draw_scale_notches(d, (int(w * 0.18), int(h * 0.16), int(w * 0.82), int(h * 0.24)), 18, accent)
    draw_scale_notches(d, (int(w * 0.18), int(h * 0.76), int(w * 0.82), int(h * 0.84)), 18, accent)

    detail = alpha_clip(detail, outer)
    img.alpha_composite(detail)
    return img


def write_manifest() -> None:
    rows = "\n".join(
        f"| {i:02d} | `{spec.stem}.png` | {spec.description} | {spec.size[0]}x{spec.size[1]} PNG RGBA | generated + verified |"
        for i, spec in enumerate(SPECS, 1)
    )
    manifest = f"""# Alpha Legion Quality Reset 003

**Status:** final static test pack complete + verified  
**Count:** 5 individual static screen-panel PNG assets  
**Animation policy:** none.  
**Reason for reset:** previous batches leaned too much into glowing frame silhouettes. This pack focuses on usable HUD screens: dark CRT/glass interiors, armored metal bezels, restrained glow, and readable empty areas for dynamic Godot text.

## Assets

| # | File | Function | Format | Status |
|---|---|---|---|---|
{rows}

## Godot usage

- Use each file as a TextureRect-backed screen/panel component.
- The interior dark glass is part of the PNG, so text can be placed above it without relying on broken shaders.
- Outside the panel is transparent alpha.
- No official marks, copied heraldry, readable text, or trademarked layouts are used.
"""
    (ROOT / "ALPHA_LEGION_QUALITY_RESET_003_MANIFEST.md").write_text(manifest, encoding="utf-8")


def main() -> None:
    os.makedirs(ROOT, exist_ok=True)
    for spec in SPECS:
        img = render_panel(spec)
        img.save(ROOT / f"{spec.stem}.png", optimize=True, compress_level=4)
        print(f"generated {spec.stem}.png {spec.size[0]}x{spec.size[1]}", flush=True)
    write_manifest()


if __name__ == "__main__":
    main()
