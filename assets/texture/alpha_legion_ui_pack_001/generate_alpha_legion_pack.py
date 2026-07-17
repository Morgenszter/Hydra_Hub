from __future__ import annotations

import math
import os
import random
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent
SIZE = 4096

BG = (0, 0, 0, 0)
TEAL = (0, 212, 190, 255)
CYAN = (50, 255, 230, 255)
DEEP_TEAL = (0, 92, 92, 255)
GUNMETAL = (24, 32, 34, 255)
BLACK_STEEL = (8, 12, 13, 255)
SILVER = (148, 168, 164, 255)
BRASS = (170, 132, 72, 255)
RED = (255, 42, 34, 255)


@dataclass(frozen=True)
class AssetSpec:
    stem: str
    kind: str
    seed: int
    accent: tuple[int, int, int, int]


SPECS = [
    AssetSpec("ALP_S01_Top_Left_Covert_Frame", "corner_tl", 101, TEAL),
    AssetSpec("ALP_S02_Top_Right_Blade_Frame", "corner_tr", 202, CYAN),
    AssetSpec("ALP_S03_Bottom_Left_Serpent_Lock", "corner_bl", 303, TEAL),
    AssetSpec("ALP_S04_Bottom_Right_Shadow_Latch", "corner_br", 404, CYAN),
    AssetSpec("ALP_S05_Long_Top_Ribbed_Bar", "bar_top", 505, TEAL),
    AssetSpec("ALP_S06_Long_Bottom_Split_Bar", "bar_bottom", 606, CYAN),
    AssetSpec("ALP_S07_Left_Vertical_Channel", "rail_left", 707, TEAL),
    AssetSpec("ALP_S08_Right_Vertical_Sensor_Rail", "rail_right", 808, CYAN),
    AssetSpec("ALP_S09_Octagonal_Command_Button", "oct_button", 909, TEAL),
    AssetSpec("ALP_S10_Diamond_Stealth_Toggle", "diamond_toggle", 1010, CYAN),
    AssetSpec("ALP_S11_Narrow_Status_Tab", "status_tab", 1111, TEAL),
    AssetSpec("ALP_S12_Tactical_Window_Frame", "window_frame", 1212, CYAN),
    AssetSpec("ALP_S13_Covert_Data_Panel_Backplate", "data_panel", 1313, TEAL),
    AssetSpec("ALP_S14_Reticle_Serpent_Eye", "reticle", 1414, CYAN),
    AssetSpec("ALP_S15_Minimap_Hex_Ring", "hex_ring", 1515, TEAL),
    AssetSpec("ALP_S16_Scanner_Holo_Node", "scanner_node", 1616, CYAN),
    AssetSpec("ALP_S17_Notification_Badge_Mute", "badge", 1717, TEAL),
    AssetSpec("ALP_S18_Progress_Bar_Housing", "progress", 1818, CYAN),
    AssetSpec("ALP_S19_Cable_Node_Decal", "cable_node", 1919, TEAL),
    AssetSpec("ALP_S20_Duality_Micro_Mark", "duality_mark", 2020, CYAN),
]


def p(v: float) -> int:
    return int(round(v * SIZE))


def clamp(v: int) -> int:
    return max(0, min(255, v))


def tinted_noise(seed: int, base: tuple[int, int, int], alpha: Image.Image) -> Image.Image:
    rng = np.random.default_rng(seed)
    a = np.asarray(alpha, dtype=np.uint8)
    h, w = a.shape
    yy = np.linspace(0, 1, h, dtype=np.float32)[:, None]
    xx = np.linspace(0, 1, w, dtype=np.float32)[None, :]
    grain = rng.normal(0, 1, (h, w)).astype(np.float32)
    grain = (grain + np.roll(grain, 7, axis=0) + np.roll(grain, 13, axis=1)) / 3
    brushed = 0.55 + 0.20 * np.sin((xx * 58.0) + seed * 0.017) + 0.12 * np.cos((yy * 37.0) + seed * 0.031)
    micro = np.clip(brushed + grain * 0.055, 0, 1)
    arr = np.zeros((h, w, 4), dtype=np.uint8)
    for i, c in enumerate(base):
        arr[:, :, i] = np.clip(c * (0.56 + micro * 0.62), 0, 255).astype(np.uint8)
    arr[:, :, 0] = np.maximum(arr[:, :, 0], (a > 0) * 4)
    arr[:, :, 1] = np.maximum(arr[:, :, 1], (a > 0) * 10)
    arr[:, :, 2] = np.maximum(arr[:, :, 2], (a > 0) * 12)
    arr[:, :, 3] = a
    return Image.fromarray(arr, "RGBA")


def alpha_clip(layer: Image.Image, mask: Image.Image) -> Image.Image:
    out = layer.copy()
    a = out.getchannel("A")
    out.putalpha(ImageChops.multiply(a, mask))
    return out


def edge_layer(mask: Image.Image, color: tuple[int, int, int, int], blur: int = 0, strength: float = 1.0) -> Image.Image:
    edge = mask.filter(ImageFilter.FIND_EDGES)
    if blur:
        edge = edge.filter(ImageFilter.GaussianBlur(blur))
    if strength != 1.0:
        edge = edge.point(lambda x: int(clamp(int(x * strength))))
    rgba = Image.new("RGBA", (SIZE, SIZE), color)
    rgba.putalpha(edge)
    return rgba


def glow_layer(mask: Image.Image, color: tuple[int, int, int, int], blur: int, alpha_scale: float) -> Image.Image:
    g = mask.filter(ImageFilter.GaussianBlur(blur))
    g = g.point(lambda x: int(clamp(int(x * alpha_scale))))
    layer = Image.new("RGBA", (SIZE, SIZE), color)
    layer.putalpha(g)
    return layer


def render(mask: Image.Image, spec: AssetSpec, detail_fn) -> Image.Image:
    rng = random.Random(spec.seed)
    img = Image.new("RGBA", (SIZE, SIZE), BG)
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 190))
    shadow_alpha = mask.filter(ImageFilter.GaussianBlur(p(0.018)))
    shadow.putalpha(shadow_alpha)
    img.alpha_composite(shadow, (p(0.008), p(0.010)))
    img.alpha_composite(glow_layer(mask, spec.accent, p(0.018), 0.38))

    base_color = (
        16 + rng.randint(0, 12),
        28 + rng.randint(0, 20),
        30 + rng.randint(0, 22),
    )
    metal = tinted_noise(spec.seed, base_color, mask)
    img.alpha_composite(metal)
    img.alpha_composite(edge_layer(mask, (210, 245, 235, 255), 0, 0.55))
    img.alpha_composite(edge_layer(mask, spec.accent, p(0.002), 0.38))

    details = Image.new("RGBA", (SIZE, SIZE), BG)
    d = ImageDraw.Draw(details, "RGBA")
    draw_micro_scratches(d, rng, mask)
    detail_fn(d, rng, spec)
    details = alpha_clip(details, mask)
    img.alpha_composite(details)
    return img


def draw_micro_scratches(d: ImageDraw.ImageDraw, rng: random.Random, mask: Image.Image) -> None:
    for _ in range(1500):
        x = rng.randint(p(0.04), p(0.96))
        y = rng.randint(p(0.04), p(0.96))
        length = rng.randint(p(0.006), p(0.035))
        if mask.getpixel((x, y)) < 20:
            continue
        angle = rng.uniform(-0.38, 0.38)
        x2 = int(x + math.cos(angle) * length)
        y2 = int(y + math.sin(angle) * length)
        a = rng.randint(18, 54)
        col = (185, 225, 218, a) if rng.random() < 0.55 else (0, 0, 0, a)
        d.line((x, y, x2, y2), fill=col, width=rng.randint(1, 3))


def rivet(d: ImageDraw.ImageDraw, x: int, y: int, r: int, accent: tuple[int, int, int, int], damaged: bool = False) -> None:
    d.ellipse((x - r, y - r, x + r, y + r), fill=(5, 8, 9, 210), outline=(170, 190, 180, 130), width=max(2, r // 12))
    d.ellipse((x - r // 2, y - r // 2, x + r // 2, y + r // 2), fill=(35, 48, 48, 255), outline=accent[:3] + (120,), width=max(1, r // 18))
    d.arc((x - r, y - r, x + r, y + r), 210, 330, fill=(220, 255, 245, 120), width=max(2, r // 14))
    if damaged:
        d.line((x - r // 2, y, x + r // 2, y + r // 3), fill=(0, 0, 0, 170), width=max(2, r // 15))


def notch_line(d: ImageDraw.ImageDraw, x1: int, y1: int, x2: int, y2: int, accent, n: int, vertical: bool = False) -> None:
    for i in range(n):
        t = (i + 0.5) / n
        if vertical:
            y = int(y1 + (y2 - y1) * t)
            d.line((x1, y, x2, y + p(0.012)), fill=accent[:3] + (105,), width=p(0.004))
        else:
            x = int(x1 + (x2 - x1) * t)
            d.line((x, y1, x + p(0.018), y2), fill=accent[:3] + (105,), width=p(0.004))


def hydra_scale_field(d: ImageDraw.ImageDraw, rng: random.Random, spec: AssetSpec, x0: int, y0: int, x1: int, y1: int, rows: int, cols: int) -> None:
    w = (x1 - x0) / cols
    h = (y1 - y0) / rows
    for row in range(rows):
        for col in range(cols):
            cx = int(x0 + (col + 0.5) * w + ((row % 2) - 0.5) * w * 0.22)
            cy = int(y0 + (row + 0.52) * h)
            sx = int(w * rng.uniform(0.18, 0.34))
            sy = int(h * rng.uniform(0.22, 0.38))
            a = rng.randint(28, 80)
            pts = [(cx, cy - sy), (cx + sx, cy), (cx, cy + sy), (cx - sx, cy)]
            d.line(pts + [pts[0]], fill=spec.accent[:3] + (a,), width=max(2, p(0.002)))


def corner_mask(kind: str, seed: int) -> Image.Image:
    rng = random.Random(seed)
    m = Image.new("L", (SIZE, SIZE), 0)
    d = ImageDraw.Draw(m)
    # Draw in top-left local space then transform by orientation. Variants alter silhouette.
    pts = [
        (p(0.075), p(0.115)),
        (p(0.850), p(0.115)),
        (p(0.930), p(0.190 + rng.random() * 0.025)),
        (p(0.850), p(0.265)),
        (p(0.315), p(0.265)),
        (p(0.315), p(0.830)),
        (p(0.245), p(0.920)),
        (p(0.150 + rng.random() * 0.025), p(0.840)),
        (p(0.150), p(0.360)),
        (p(0.075), p(0.300)),
    ]
    local = Image.new("L", (SIZE, SIZE), 0)
    ld = ImageDraw.Draw(local)
    ld.polygon(pts, fill=255)
    for i in range(5):
        x = p(0.42 + i * 0.075 + rng.uniform(-0.012, 0.012))
        ld.polygon([(x, p(0.115)), (x + p(0.040), p(0.115)), (x + p(0.015), p(0.165))], fill=0)
    for i in range(4):
        y = p(0.42 + i * 0.090 + rng.uniform(-0.012, 0.012))
        ld.polygon([(p(0.150), y), (p(0.150), y + p(0.050)), (p(0.205), y + p(0.020))], fill=0)
    if kind == "corner_tl":
        return local
    if kind == "corner_tr":
        return local.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if kind == "corner_bl":
        return local.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    return local.transpose(Image.Transpose.ROTATE_180)


def rect_frame_mask(x0, y0, x1, y1, inner_pad, radius=0) -> Image.Image:
    m = Image.new("L", (SIZE, SIZE), 0)
    d = ImageDraw.Draw(m)
    if radius:
        d.rounded_rectangle((x0, y0, x1, y1), radius=radius, fill=255)
        d.rounded_rectangle((x0 + inner_pad, y0 + inner_pad, x1 - inner_pad, y1 - inner_pad), radius=max(0, radius - inner_pad), fill=0)
    else:
        d.rectangle((x0, y0, x1, y1), fill=255)
        d.rectangle((x0 + inner_pad, y0 + inner_pad, x1 - inner_pad, y1 - inner_pad), fill=0)
    return m


def polygon_mask(points) -> Image.Image:
    m = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(m).polygon(points, fill=255)
    return m


def regular_polygon(cx, cy, r, sides, rot=0):
    return [
        (int(cx + math.cos(rot + i * math.tau / sides) * r), int(cy + math.sin(rot + i * math.tau / sides) * r))
        for i in range(sides)
    ]


def build_mask(kind: str, seed: int) -> Image.Image:
    rng = random.Random(seed)
    if kind.startswith("corner_"):
        return corner_mask(kind, seed)
    if kind in ("bar_top", "bar_bottom"):
        y = p(0.40 if kind == "bar_top" else 0.46)
        h = p(0.155 if kind == "bar_top" else 0.185)
        pts = [
            (p(0.06), y + h // 2),
            (p(0.11), y),
            (p(0.84), y),
            (p(0.94), y + h // 2),
            (p(0.84), y + h),
            (p(0.11), y + h),
        ]
        m = polygon_mask(pts)
        d = ImageDraw.Draw(m)
        for i in range(9):
            x = p(0.18 + i * 0.070 + rng.uniform(-0.009, 0.009))
            d.rectangle((x, y + p(0.035), x + p(0.030), y + h - p(0.035)), fill=0)
        return m
    if kind in ("rail_left", "rail_right"):
        x = p(0.40 if kind == "rail_left" else 0.47)
        w = p(0.160 if kind == "rail_left" else 0.130)
        pts = [
            (x, p(0.08)),
            (x + w, p(0.13)),
            (x + w, p(0.88)),
            (x + w // 2, p(0.94)),
            (x, p(0.88)),
        ]
        m = polygon_mask(pts)
        d = ImageDraw.Draw(m)
        for i in range(8):
            y = p(0.20 + i * 0.075 + rng.uniform(-0.012, 0.012))
            d.rectangle((x + p(0.038), y, x + w - p(0.038), y + p(0.024)), fill=0)
        return m
    if kind == "oct_button":
        m = polygon_mask(regular_polygon(p(0.50), p(0.50), p(0.250), 8, math.pi / 8))
        d = ImageDraw.Draw(m)
        d.polygon(regular_polygon(p(0.50), p(0.50), p(0.135), 8, math.pi / 8), fill=0)
        return m
    if kind == "diamond_toggle":
        m = polygon_mask([(p(0.50), p(0.18)), (p(0.80), p(0.50)), (p(0.50), p(0.82)), (p(0.20), p(0.50))])
        d = ImageDraw.Draw(m)
        d.polygon([(p(0.50), p(0.33)), (p(0.65), p(0.50)), (p(0.50), p(0.67)), (p(0.35), p(0.50))], fill=0)
        return m
    if kind == "status_tab":
        return polygon_mask([(p(0.12), p(0.43)), (p(0.78), p(0.43)), (p(0.88), p(0.50)), (p(0.78), p(0.57)), (p(0.12), p(0.57)), (p(0.08), p(0.50))])
    if kind == "window_frame":
        return rect_frame_mask(p(0.14), p(0.20), p(0.86), p(0.80), p(0.075), p(0.035))
    if kind == "data_panel":
        m = rect_frame_mask(p(0.18), p(0.26), p(0.82), p(0.74), p(0.040), p(0.025))
        d = ImageDraw.Draw(m)
        d.rectangle((p(0.25), p(0.34), p(0.75), p(0.66)), fill=255)
        d.rectangle((p(0.28), p(0.38), p(0.72), p(0.62)), fill=0)
        return m
    if kind == "reticle":
        m = Image.new("L", (SIZE, SIZE), 0)
        d = ImageDraw.Draw(m)
        for r, w in [(p(0.28), p(0.018)), (p(0.18), p(0.014)), (p(0.070), p(0.020))]:
            d.ellipse((p(0.5) - r, p(0.5) - r, p(0.5) + r, p(0.5) + r), outline=255, width=w)
        for a in [0, math.pi / 2, math.pi, 3 * math.pi / 2]:
            x1 = p(0.5) + int(math.cos(a) * p(0.33))
            y1 = p(0.5) + int(math.sin(a) * p(0.33))
            x2 = p(0.5) + int(math.cos(a) * p(0.43))
            y2 = p(0.5) + int(math.sin(a) * p(0.43))
            d.line((x1, y1, x2, y2), fill=255, width=p(0.016))
        return m
    if kind == "hex_ring":
        m = polygon_mask(regular_polygon(p(0.50), p(0.50), p(0.330), 6, math.pi / 6))
        d = ImageDraw.Draw(m)
        d.polygon(regular_polygon(p(0.50), p(0.50), p(0.245), 6, math.pi / 6), fill=0)
        return m
    if kind == "scanner_node":
        m = Image.new("L", (SIZE, SIZE), 0)
        d = ImageDraw.Draw(m)
        d.rounded_rectangle((p(0.31), p(0.31), p(0.69), p(0.69)), radius=p(0.04), fill=255)
        d.ellipse((p(0.38), p(0.38), p(0.62), p(0.62)), fill=0)
        for i in range(4):
            a = i * math.pi / 2 + math.pi / 4
            d.line((p(0.5), p(0.5), p(0.5) + int(math.cos(a) * p(0.34)), p(0.5) + int(math.sin(a) * p(0.34))), fill=255, width=p(0.024))
        return m
    if kind == "badge":
        m = polygon_mask([(p(0.35), p(0.22)), (p(0.66), p(0.22)), (p(0.78), p(0.40)), (p(0.70), p(0.74)), (p(0.50), p(0.84)), (p(0.30), p(0.74)), (p(0.22), p(0.40))])
        d = ImageDraw.Draw(m)
        d.polygon([(p(0.50), p(0.36)), (p(0.61), p(0.50)), (p(0.50), p(0.64)), (p(0.39), p(0.50))], fill=0)
        return m
    if kind == "progress":
        m = rect_frame_mask(p(0.10), p(0.42), p(0.90), p(0.58), p(0.045), p(0.020))
        d = ImageDraw.Draw(m)
        for i in range(11):
            x = p(0.18 + i * 0.060)
            d.rectangle((x, p(0.455), x + p(0.020), p(0.545)), fill=255 if i % 3 else 0)
        return m
    if kind == "cable_node":
        m = Image.new("L", (SIZE, SIZE), 0)
        d = ImageDraw.Draw(m)
        d.ellipse((p(0.36), p(0.36), p(0.64), p(0.64)), fill=255)
        d.rounded_rectangle((p(0.12), p(0.47), p(0.39), p(0.53)), radius=p(0.025), fill=255)
        d.rounded_rectangle((p(0.61), p(0.47), p(0.88), p(0.53)), radius=p(0.025), fill=255)
        d.rounded_rectangle((p(0.47), p(0.12), p(0.53), p(0.39)), radius=p(0.025), fill=255)
        d.rounded_rectangle((p(0.47), p(0.61), p(0.53), p(0.88)), radius=p(0.025), fill=255)
        d.ellipse((p(0.435), p(0.435), p(0.565), p(0.565)), fill=0)
        return m
    if kind == "duality_mark":
        m = Image.new("L", (SIZE, SIZE), 0)
        d = ImageDraw.Draw(m)
        d.polygon([(p(0.26), p(0.50)), (p(0.43), p(0.27)), (p(0.56), p(0.33)), (p(0.41), p(0.50)), (p(0.56), p(0.67)), (p(0.43), p(0.73))], fill=255)
        d.polygon([(p(0.74), p(0.50)), (p(0.57), p(0.27)), (p(0.44), p(0.33)), (p(0.59), p(0.50)), (p(0.44), p(0.67)), (p(0.57), p(0.73))], fill=255)
        d.ellipse((p(0.445), p(0.445), p(0.555), p(0.555)), fill=0)
        return m
    raise ValueError(kind)


def detail_for(kind: str):
    def details(d: ImageDraw.ImageDraw, rng: random.Random, spec: AssetSpec) -> None:
        accent = spec.accent
        if kind.startswith("corner_"):
            for i in range(7):
                rivet(d, p(0.18 + i * 0.090), p(0.185 + rng.uniform(-0.008, 0.008)), p(0.018 + rng.random() * 0.006), accent, i % 3 == 0)
            for i in range(6):
                rivet(d, p(0.220 + rng.uniform(-0.010, 0.010)), p(0.34 + i * 0.075), p(0.017 + rng.random() * 0.006), accent, i % 2 == 0)
            notch_line(d, p(0.38), p(0.225), p(0.76), p(0.245), accent, 10)
            notch_line(d, p(0.212), p(0.42), p(0.238), p(0.73), accent, 8, vertical=True)
            hydra_scale_field(d, rng, spec, p(0.35), p(0.145), p(0.78), p(0.245), 3, 12)
        elif kind in ("bar_top", "bar_bottom", "progress"):
            y0, y1 = (p(0.41), p(0.56)) if kind != "progress" else (p(0.43), p(0.57))
            for i in range(16):
                x = p(0.12 + i * 0.048)
                d.line((x, y0, x + p(0.030), y1), fill=accent[:3] + (70,), width=p(0.004))
            for x in [p(0.13), p(0.88), p(0.48), p(0.54)]:
                rivet(d, x, (y0 + y1) // 2, p(0.017), accent, False)
            hydra_scale_field(d, rng, spec, p(0.18), y0 + p(0.020), p(0.82), y1 - p(0.020), 2, 18)
        elif kind in ("rail_left", "rail_right"):
            for i in range(10):
                y = p(0.16 + i * 0.073)
                rivet(d, p(0.50), y, p(0.014), accent, i % 4 == 0)
            notch_line(d, p(0.455), p(0.22), p(0.545), p(0.77), accent, 13, vertical=True)
        elif kind in ("oct_button", "diamond_toggle", "badge", "duality_mark"):
            for r in [p(0.09), p(0.15), p(0.22)]:
                box = (p(0.5) - r, p(0.5) - r, p(0.5) + r, p(0.5) + r)
                d.arc(box, 210, 330, fill=accent[:3] + (100,), width=p(0.006))
                d.arc(box, 30, 145, fill=(220, 255, 245, 70), width=p(0.004))
            for i in range(8):
                a = i * math.tau / 8 + rng.uniform(-0.08, 0.08)
                d.line((p(0.5) + int(math.cos(a) * p(0.15)), p(0.5) + int(math.sin(a) * p(0.15)),
                        p(0.5) + int(math.cos(a) * p(0.25)), p(0.5) + int(math.sin(a) * p(0.25))),
                       fill=accent[:3] + (70,), width=p(0.004))
        elif kind in ("window_frame", "data_panel"):
            for i in range(4):
                rivet(d, p(0.20 + (i % 2) * 0.60), p(0.27 + (i // 2) * 0.46), p(0.020), accent, i == 2)
            hydra_scale_field(d, rng, spec, p(0.24), p(0.25), p(0.76), p(0.33), 2, 16)
            hydra_scale_field(d, rng, spec, p(0.24), p(0.67), p(0.76), p(0.75), 2, 16)
            for i in range(10):
                y = p(0.37 + i * 0.026)
                d.line((p(0.29), y, p(0.71), y + rng.randint(-3, 3)), fill=accent[:3] + (38,), width=p(0.002))
        elif kind in ("reticle", "hex_ring", "scanner_node", "cable_node"):
            for r in [p(0.12), p(0.22), p(0.32)]:
                box = (p(0.5) - r, p(0.5) - r, p(0.5) + r, p(0.5) + r)
                d.arc(box, 0, 82, fill=accent[:3] + (130,), width=p(0.005))
                d.arc(box, 184, 238, fill=(220, 255, 245, 90), width=p(0.004))
            for i in range(12):
                a = i * math.tau / 12
                rivet(d, p(0.5) + int(math.cos(a) * p(0.29)), p(0.5) + int(math.sin(a) * p(0.29)), p(0.010), accent, False)
        elif kind == "status_tab":
            for i in range(13):
                x = p(0.18 + i * 0.045)
                d.rectangle((x, p(0.465), x + p(0.022), p(0.535)), fill=accent[:3] + (55 + (i % 3) * 22,))
            rivet(d, p(0.14), p(0.50), p(0.016), accent)
            rivet(d, p(0.82), p(0.50), p(0.016), accent)
        else:
            hydra_scale_field(d, rng, spec, p(0.25), p(0.25), p(0.75), p(0.75), 6, 10)

    return details


def write_manifest() -> None:
    rows = "\n".join(
        f"| {i:02d} | `{spec.stem}.png` | {spec.kind.replace('_', ' ')} | PNG RGBA, 4096×4096 | generated |"
        for i, spec in enumerate(SPECS, 1)
    )
    manifest = f"""# Alpha Legion-Inspired UI Pack 001

**Status:** static render generated; animation render pending  
**Count:** 30 individual assets — 20 static PNG + 10 animated WebM  
**Visual direction:** original covert hydra-legion interface language: blackened steel, dark teal, cyan phosphor, scale-like mechanical geometry, stealth scanner motifs.  
**IP rule:** inspired by grimdark covert-legion mood only. No official logos, faction heraldry, readable copied text, trademarks, or exact Warhammer layouts.

## Static assets

| # | File | Function / silhouette | Format | Status |
|---|---|---|---|---|
{rows}

## Animated assets

| # | File | Function | Format | Status |
|---|---|---|---|---|
| 01 | `ALP_A01_Covert_Scanline_Sweep.webm` | dark teal CRT scan sweep | WebM VP9 alpha, 3840×2160, 60 FPS | pending |
| 02 | `ALP_A02_Stealth_Grid_Shimmer.webm` | low-opacity tactical grid shimmer | WebM VP9 alpha, 3840×2160, 60 FPS | pending |
| 03 | `ALP_A03_Hydra_Scale_Glow.webm` | scale-pattern glow crawl | WebM VP9 alpha, 3840×2160, 60 FPS | pending |
| 04 | `ALP_A04_Reticle_Lock_Cycle.webm` | reticle lock brackets | WebM VP9 alpha, 3840×2160, 60 FPS | pending |
| 05 | `ALP_A05_Minimap_Sweep_Arc.webm` | minimap radial sweep | WebM VP9 alpha, 3840×2160, 60 FPS | pending |
| 06 | `ALP_A06_Data_Rain_Encrypted.webm` | abstract encrypted data rain | WebM VP9 alpha, 3840×2160, 60 FPS | pending |
| 07 | `ALP_A07_Status_LED_Breath.webm` | status LED breathing pulse | WebM VP9 alpha, 3840×2160, 60 FPS | pending |
| 08 | `ALP_A08_Hologram_Tear.webm` | distorted hologram tear | WebM VP9 alpha, 3840×2160, 60 FPS | pending |
| 09 | `ALP_A09_Shutter_Transition.webm` | stealth shutter transition | WebM VP9 alpha, 3840×2160, 60 FPS | pending |
| 10 | `ALP_A10_Cipher_Warning_Pulse.webm` | restrained red/cyan warning cipher pulse | WebM VP9 alpha, 3840×2160, 60 FPS | pending |

## Import notes

- Static PNG files are transparent and intended for TextureRect/NinePatchRect/custom Control overlays.
- Animated WebM files are transparent overlays for additive/screen/alpha compositing.
- No asset is a mirror-only duplicate; each file uses separate silhouette logic, ornament density, cutouts, and mechanical function.
"""
    (ROOT / "ALPHA_LEGION_UI_PACK_001_MANIFEST.md").write_text(manifest, encoding="utf-8")


def main() -> None:
    os.makedirs(ROOT, exist_ok=True)
    for spec in SPECS:
        mask = build_mask(spec.kind, spec.seed)
        img = render(mask, spec, detail_for(spec.kind))
        img.save(ROOT / f"{spec.stem}.png", optimize=True, compress_level=6)
        print(f"generated {spec.stem}.png")
    write_manifest()


if __name__ == "__main__":
    main()
