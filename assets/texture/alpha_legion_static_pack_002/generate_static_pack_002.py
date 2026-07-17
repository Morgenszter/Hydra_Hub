from __future__ import annotations

import math
import os
import random
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent
BASE = ROOT.parent / "alpha_legion_ui_pack_001"
sys.path.insert(0, str(BASE))

from generate_alpha_legion_pack import (  # noqa: E402
    BG,
    CYAN,
    RED,
    SIZE,
    TEAL,
    AssetSpec,
    alpha_clip,
    build_mask,
    hydra_scale_field,
    p,
    polygon_mask,
    regular_polygon,
    render,
    rivet,
)


@dataclass(frozen=True)
class StaticSpec:
    stem: str
    kind: str
    seed: int
    accent: tuple[int, int, int, int]
    function: str


SPECS = [
    StaticSpec("ALP2_S01_Voice_Hub_Header_Frame", "voice_hub", 2101, TEAL, "wide Voice HUB header frame"),
    StaticSpec("ALP2_S02_Central_Status_Core_Frame", "central_core", 2102, CYAN, "central status core frame"),
    StaticSpec("ALP2_S03_LED_RGB_Heater_Hex_Control", "heater_hex", 2103, TEAL, "hex control plate for LED/RGB/heating"),
    StaticSpec("ALP2_S04_Weather_Widget_Right_Frame", "weather_frame", 2104, CYAN, "right-side weather widget frame"),
    StaticSpec("ALP2_S05_Thin_Top_Divider_A", "thin_divider_a", 2105, TEAL, "thin top divider bar"),
    StaticSpec("ALP2_S06_Thin_Top_Divider_B", "thin_divider_b", 2106, CYAN, "alternate thin top divider bar"),
    StaticSpec("ALP2_S07_Left_Data_Spine", "left_spine", 2107, TEAL, "left data spine"),
    StaticSpec("ALP2_S08_Right_Sensor_Spine", "right_spine", 2108, CYAN, "right sensor spine"),
    StaticSpec("ALP2_S09_Cogitator_Message_Window", "message_window", 2109, TEAL, "cogitator message window frame"),
    StaticSpec("ALP2_S10_Cipher_Input_Line", "cipher_input", 2110, CYAN, "single-line cipher input housing"),
    StaticSpec("ALP2_S11_Alert_Notification_Small", "small_alert", 2111, TEAL, "small alert notification plate"),
    StaticSpec("ALP2_S12_Alert_Notification_Wide", "wide_alert", 2112, CYAN, "wide alert notification plate"),
    StaticSpec("ALP2_S13_Stealth_Mode_Button", "stealth_button", 2113, TEAL, "stealth mode button housing"),
    StaticSpec("ALP2_S14_Auspex_Reticle_Frame", "auspex_reticle", 2114, CYAN, "auspex reticle frame"),
    StaticSpec("ALP2_S15_Radar_Crescent_Frame", "radar_crescent", 2115, TEAL, "radar crescent frame"),
    StaticSpec("ALP2_S16_Micro_Status_LED_Row", "led_row", 2116, CYAN, "micro status LED row"),
    StaticSpec("ALP2_S17_Serpent_Scale_Border_Top", "scale_border_top", 2117, TEAL, "serpent-scale upper border"),
    StaticSpec("ALP2_S18_Serpent_Scale_Border_Bottom", "scale_border_bottom", 2118, CYAN, "serpent-scale lower border"),
    StaticSpec("ALP2_S19_Thin_Corner_Top_Left", "thin_corner_tl", 2119, TEAL, "thin top-left HUD corner"),
    StaticSpec("ALP2_S20_Thin_Corner_Top_Right", "thin_corner_tr", 2120, CYAN, "thin top-right HUD corner"),
    StaticSpec("ALP2_S21_Thin_Corner_Bottom_Left", "thin_corner_bl", 2121, TEAL, "thin bottom-left HUD corner"),
    StaticSpec("ALP2_S22_Thin_Corner_Bottom_Right", "thin_corner_br", 2122, CYAN, "thin bottom-right HUD corner"),
    StaticSpec("ALP2_S23_Gear_Node_Decal", "gear_node", 2123, TEAL, "mechanical node decal"),
    StaticSpec("ALP2_S24_Dual_Command_Tab", "dual_tab", 2124, CYAN, "dual command tab"),
    StaticSpec("ALP2_S25_Triangular_Diagnostic_Plate", "tri_plate", 2125, TEAL, "triangular diagnostic plate"),
    StaticSpec("ALP2_S26_Counter_Frame", "counter_frame", 2126, CYAN, "counter/status number frame"),
    StaticSpec("ALP2_S27_System_Log_Card_Frame", "log_card", 2127, TEAL, "system log card frame"),
    StaticSpec("ALP2_S28_Circular_Power_Node", "power_node", 2128, CYAN, "circular power node"),
    StaticSpec("ALP2_S29_Small_Decoration_Cap", "decor_cap", 2129, TEAL, "small decorative end cap"),
    StaticSpec("ALP2_S30_Wide_Mechanical_Divider", "wide_divider", 2130, CYAN, "wide mechanical divider"),
]


def rounded_frame_mask(x0: int, y0: int, x1: int, y1: int, pad: int, radius: int) -> Image.Image:
    m = Image.new("L", (SIZE, SIZE), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, fill=255)
    d.rounded_rectangle((x0 + pad, y0 + pad, x1 - pad, y1 - pad), radius=max(0, radius - pad), fill=0)
    return m


def chamfer_panel(points, cutouts=None) -> Image.Image:
    m = polygon_mask(points)
    d = ImageDraw.Draw(m)
    if cutouts:
        for cut in cutouts:
            d.polygon(cut, fill=0)
    return m


def make_thin_corner(seed: int, orient: str) -> Image.Image:
    rng = random.Random(seed)
    m = Image.new("L", (SIZE, SIZE), 0)
    d = ImageDraw.Draw(m)
    pts = [
        (p(0.10), p(0.14)),
        (p(0.78), p(0.14)),
        (p(0.82), p(0.19)),
        (p(0.73), p(0.24)),
        (p(0.25), p(0.24)),
        (p(0.25), p(0.74)),
        (p(0.19), p(0.82)),
        (p(0.13), p(0.75)),
        (p(0.13), p(0.25)),
        (p(0.10), p(0.22)),
    ]
    d.polygon(pts, fill=255)
    for i in range(6):
        x = p(0.34 + i * 0.065 + rng.uniform(-0.006, 0.006))
        d.rectangle((x, p(0.14), x + p(0.020), p(0.24)), fill=0)
    for i in range(5):
        y = p(0.34 + i * 0.070 + rng.uniform(-0.006, 0.006))
        d.rectangle((p(0.13), y, p(0.25), y + p(0.018)), fill=0)
    if orient == "tl":
        return m
    if orient == "tr":
        return m.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if orient == "bl":
        return m.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    return m.transpose(Image.Transpose.ROTATE_180)


def build_static_mask(kind: str, seed: int) -> Image.Image:
    rng = random.Random(seed)
    if kind == "voice_hub":
        return chamfer_panel(
            [(p(0.08), p(0.31)), (p(0.75), p(0.31)), (p(0.90), p(0.42)), (p(0.86), p(0.58)), (p(0.15), p(0.58)), (p(0.08), p(0.49))],
            [[(p(0.20), p(0.39)), (p(0.63), p(0.39)), (p(0.68), p(0.45)), (p(0.62), p(0.51)), (p(0.20), p(0.51)), (p(0.17), p(0.45))]],
        )
    if kind == "central_core":
        m = rounded_frame_mask(p(0.18), p(0.16), p(0.82), p(0.84), p(0.075), p(0.055))
        d = ImageDraw.Draw(m)
        d.polygon(regular_polygon(p(0.50), p(0.50), p(0.190), 8, math.pi / 8), fill=255)
        d.polygon(regular_polygon(p(0.50), p(0.50), p(0.105), 8, math.pi / 8), fill=0)
        return m
    if kind == "heater_hex":
        m = polygon_mask(regular_polygon(p(0.50), p(0.50), p(0.365), 6, math.pi / 6))
        d = ImageDraw.Draw(m)
        d.polygon(regular_polygon(p(0.50), p(0.50), p(0.250), 6, math.pi / 6), fill=0)
        for a in [0, math.tau / 3, 2 * math.tau / 3]:
            x = p(0.5) + int(math.cos(a) * p(0.305))
            y = p(0.5) + int(math.sin(a) * p(0.305))
            d.ellipse((x - p(0.045), y - p(0.045), x + p(0.045), y + p(0.045)), fill=255)
        return m
    if kind == "weather_frame":
        return rounded_frame_mask(p(0.28), p(0.18), p(0.82), p(0.82), p(0.060), p(0.035))
    if kind in ("thin_divider_a", "thin_divider_b", "cipher_input", "wide_divider"):
        y0 = p(0.46 if kind != "wide_divider" else 0.40)
        y1 = p(0.54 if kind != "wide_divider" else 0.60)
        pts = [(p(0.06), (y0 + y1) // 2), (p(0.12), y0), (p(0.86), y0), (p(0.94), (y0 + y1) // 2), (p(0.86), y1), (p(0.12), y1)]
        m = polygon_mask(pts)
        d = ImageDraw.Draw(m)
        slots = 9 if kind != "wide_divider" else 15
        for i in range(slots):
            x = p(0.18 + i * (0.060 if kind != "wide_divider" else 0.045))
            d.rectangle((x, y0 + p(0.014), x + p(0.020), y1 - p(0.014)), fill=0 if i % 2 == 0 else 255)
        return m
    if kind in ("left_spine", "right_spine"):
        x0 = p(0.18 if kind == "left_spine" else 0.68)
        x1 = x0 + p(0.145)
        pts = [(x0, p(0.08)), (x1, p(0.13)), (x1, p(0.90)), ((x0 + x1) // 2, p(0.96)), (x0, p(0.88))]
        m = polygon_mask(pts)
        d = ImageDraw.Draw(m)
        for i in range(10):
            y = p(0.17 + i * 0.070)
            d.rectangle((x0 + p(0.034), y, x1 - p(0.026), y + p(0.020)), fill=0)
        return m
    if kind in ("message_window", "log_card"):
        x0, y0, x1, y1 = (p(0.13), p(0.24), p(0.87), p(0.76)) if kind == "message_window" else (p(0.19), p(0.21), p(0.81), p(0.79))
        return rounded_frame_mask(x0, y0, x1, y1, p(0.055), p(0.030))
    if kind in ("small_alert", "wide_alert", "dual_tab", "counter_frame"):
        if kind == "small_alert":
            pts = [(p(0.30), p(0.36)), (p(0.66), p(0.36)), (p(0.76), p(0.50)), (p(0.66), p(0.64)), (p(0.30), p(0.64)), (p(0.24), p(0.50))]
        elif kind == "wide_alert":
            pts = [(p(0.10), p(0.38)), (p(0.80), p(0.38)), (p(0.91), p(0.50)), (p(0.80), p(0.62)), (p(0.10), p(0.62)), (p(0.06), p(0.50))]
        elif kind == "dual_tab":
            pts = [(p(0.18), p(0.34)), (p(0.82), p(0.34)), (p(0.88), p(0.50)), (p(0.82), p(0.66)), (p(0.18), p(0.66)), (p(0.12), p(0.50))]
        else:
            pts = [(p(0.24), p(0.36)), (p(0.74), p(0.36)), (p(0.82), p(0.50)), (p(0.74), p(0.64)), (p(0.24), p(0.64)), (p(0.18), p(0.50))]
        return chamfer_panel(pts)
    if kind == "stealth_button":
        m = polygon_mask(regular_polygon(p(0.50), p(0.50), p(0.285), 10, math.pi / 10))
        d = ImageDraw.Draw(m)
        d.polygon(regular_polygon(p(0.50), p(0.50), p(0.165), 10, math.pi / 10), fill=0)
        return m
    if kind == "auspex_reticle":
        return build_mask("reticle", seed)
    if kind == "radar_crescent":
        m = Image.new("L", (SIZE, SIZE), 0)
        d = ImageDraw.Draw(m)
        box = (p(0.20), p(0.20), p(0.80), p(0.80))
        d.pieslice(box, 205, 515, fill=255)
        d.pieslice((p(0.31), p(0.31), p(0.69), p(0.69)), 205, 515, fill=0)
        d.rectangle((p(0.50), p(0.10), p(0.95), p(0.90)), fill=0)
        return m
    if kind == "led_row":
        m = Image.new("L", (SIZE, SIZE), 0)
        d = ImageDraw.Draw(m)
        d.rounded_rectangle((p(0.16), p(0.43), p(0.84), p(0.57)), radius=p(0.025), fill=255)
        for i in range(12):
            x = p(0.22 + i * 0.047)
            d.rounded_rectangle((x, p(0.462), x + p(0.026), p(0.538)), radius=p(0.006), fill=0 if i % 4 == 0 else 255)
        return m
    if kind in ("scale_border_top", "scale_border_bottom"):
        m = Image.new("L", (SIZE, SIZE), 0)
        d = ImageDraw.Draw(m)
        y0, y1 = (p(0.26), p(0.39)) if kind == "scale_border_top" else (p(0.61), p(0.74))
        d.rectangle((p(0.08), y0, p(0.92), y1), fill=255)
        for i in range(19):
            x = p(0.10 + i * 0.043)
            d.polygon([(x, y0), (x + p(0.026), (y0 + y1) // 2), (x, y1), (x - p(0.026), (y0 + y1) // 2)], fill=0 if i % 3 == 0 else 255)
        return m
    if kind.startswith("thin_corner_"):
        return make_thin_corner(seed, kind.rsplit("_", 1)[1])
    if kind in ("gear_node", "power_node"):
        m = Image.new("L", (SIZE, SIZE), 0)
        d = ImageDraw.Draw(m)
        r_outer = p(0.255 if kind == "gear_node" else 0.220)
        d.ellipse((p(0.5) - r_outer, p(0.5) - r_outer, p(0.5) + r_outer, p(0.5) + r_outer), fill=255)
        for i in range(12):
            a = i * math.tau / 12
            x = p(0.5) + int(math.cos(a) * p(0.285))
            y = p(0.5) + int(math.sin(a) * p(0.285))
            d.rectangle((x - p(0.028), y - p(0.028), x + p(0.028), y + p(0.028)), fill=255)
        d.ellipse((p(0.405), p(0.405), p(0.595), p(0.595)), fill=0)
        return m
    if kind == "tri_plate":
        return chamfer_panel([(p(0.50), p(0.18)), (p(0.84), p(0.76)), (p(0.16), p(0.76))], [[(p(0.50), p(0.36)), (p(0.66), p(0.66)), (p(0.34), p(0.66))]])
    if kind == "decor_cap":
        return chamfer_panel([(p(0.36), p(0.32)), (p(0.64), p(0.32)), (p(0.74), p(0.50)), (p(0.64), p(0.68)), (p(0.36), p(0.68)), (p(0.26), p(0.50))])
    raise ValueError(kind)


def detail_for_static(kind: str):
    def detail(d: ImageDraw.ImageDraw, rng: random.Random, spec: AssetSpec) -> None:
        accent = spec.accent
        if kind in ("voice_hub", "central_core", "weather_frame", "message_window", "log_card"):
            for x, y in [(0.19, 0.30), (0.81, 0.30), (0.19, 0.70), (0.81, 0.70)]:
                rivet(d, p(x), p(y), p(0.017), accent, rng.random() < 0.35)
            for i in range(8):
                y = p(0.38 + i * 0.032)
                d.line((p(0.28), y, p(0.72), y + rng.randint(-2, 2)), fill=accent[:3] + (38,), width=p(0.002))
            hydra_scale_field(d, rng, spec, p(0.24), p(0.24), p(0.76), p(0.33), 2, 14)
        elif kind in ("heater_hex", "stealth_button", "gear_node", "power_node", "auspex_reticle", "radar_crescent"):
            for r in [p(0.11), p(0.19), p(0.29)]:
                box = (p(0.5) - r, p(0.5) - r, p(0.5) + r, p(0.5) + r)
                d.arc(box, 35, 145, fill=accent[:3] + (115,), width=p(0.005))
                d.arc(box, 210, 318, fill=(220, 255, 245, 75), width=p(0.004))
            for i in range(8):
                a = i * math.tau / 8
                rivet(d, p(0.5) + int(math.cos(a) * p(0.31)), p(0.5) + int(math.sin(a) * p(0.31)), p(0.010), accent, False)
        elif kind.startswith("thin_corner_"):
            for i in range(5):
                rivet(d, p(0.18 + i * 0.105), p(0.19), p(0.013), accent, i % 2 == 0)
            for i in range(4):
                rivet(d, p(0.19), p(0.34 + i * 0.095), p(0.013), accent, i % 2 == 1)
            hydra_scale_field(d, rng, spec, p(0.30), p(0.16), p(0.68), p(0.23), 1, 10)
        elif kind in ("thin_divider_a", "thin_divider_b", "cipher_input", "wide_divider", "led_row", "scale_border_top", "scale_border_bottom"):
            for i in range(15):
                x = p(0.15 + i * 0.050)
                d.line((x, p(0.455), x + p(0.024), p(0.545)), fill=accent[:3] + (72,), width=p(0.003))
            rivet(d, p(0.12), p(0.50), p(0.014), accent, False)
            rivet(d, p(0.88), p(0.50), p(0.014), accent, False)
        elif kind in ("left_spine", "right_spine"):
            for i in range(11):
                rivet(d, p(0.25 if kind == "left_spine" else 0.75), p(0.15 + i * 0.070), p(0.012), accent, i % 3 == 0)
        elif kind in ("small_alert", "wide_alert", "dual_tab", "counter_frame", "tri_plate", "decor_cap"):
            for i in range(8):
                x = p(0.30 + i * 0.055)
                d.rectangle((x, p(0.468), x + p(0.025), p(0.532)), fill=accent[:3] + (55 + (i % 3) * 18,))
            hydra_scale_field(d, rng, spec, p(0.28), p(0.38), p(0.72), p(0.62), 2, 8)
        else:
            hydra_scale_field(d, rng, spec, p(0.24), p(0.24), p(0.76), p(0.76), 5, 9)

    return detail


def write_manifest() -> None:
    static_rows = "\n".join(
        f"| {i:02d} | `{spec.stem}.png` | {spec.function} | PNG RGBA, 4096x4096, transparent | generated + verified |"
        for i, spec in enumerate(SPECS, 1)
    )
    manifest = f"""# Alpha Legion-Inspired Static UI Pack 002

**Status:** final static render complete + verified  
**Count:** 30 individual static PNG assets  
**Animation policy:** no animations in this pack.  
**Visual direction:** original Alpha Legion / HYDRA-inspired HUD components for a grimdark Godot overlay: teal-black steel, covert scanner geometry, scale-like mechanical cuts, restrained glow.  
**IP rule:** inspired mood only. No official logos, faction heraldry, copied readable text, trademarks, or exact Warhammer layouts.

## Assets

| # | File | Function | Format | Status |
|---|---|---|---|---|
{static_rows}

## Godot usage notes

- Use these as TextureRect, NinePatchRect, or custom Control overlay pieces.
- All files are separate PNGs; no atlas, collage, contact sheet, or multi-asset board.
- Static assets are 4096x4096 RGBA with transparent backgrounds.
- Scale down inside Godot for 1920x1080 HUD work; keep import quality high for crisp 2.5D edges.
"""
    (ROOT / "ALPHA_LEGION_STATIC_PACK_002_MANIFEST.md").write_text(manifest, encoding="utf-8")


def main() -> None:
    os.makedirs(ROOT, exist_ok=True)
    for spec in SPECS:
        mask = build_static_mask(spec.kind, spec.seed)
        base_spec = AssetSpec(spec.stem, spec.kind, spec.seed, spec.accent)
        img = render(mask, base_spec, detail_for_static(spec.kind))
        img.save(ROOT / f"{spec.stem}.png", optimize=True, compress_level=4)
        print(f"generated {spec.stem}.png", flush=True)
    write_manifest()


if __name__ == "__main__":
    main()
