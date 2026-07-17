# Cogitator Texture Pack 001

**Status:** final render complete + verified  
**Count:** 24 individual assets — 12 static + 12 animated  
**Visual direction:** original grimdark industrial terminal, oxidized metal, CRT phosphor, restrained green/cyan/amber diagnostics  
**Reference use:** the supplied image is used only as a mood and material reference. No text, logo, heraldry, icon, exact frame, or screen layout is reproduced.

## Delivery rules

- Every asset is a separate file; no boards, sheets, collages, or multi-asset renders.
- No official marks, faction insignia, readable copied text, or recognizable branded interface elements.
- Static materials: 2048×2048 PNG source textures unless an overlay requires RGBA.
- Animated overlays: individual transparent WebM VP9 texture movies, 60 FPS, seamless loop where marked, with restrained luminance changes and professional easing.
- Material intent: physically plausible metal/glass/phosphor response, controlled roughness variation, sharp micro-detail, tile-safe where marked.

## Static textures

| ID | File stem | Function | Target | Status |
|---|---|---|---|---|
| S01 | `S01_CRT_Glass_Base` | dark green-black curved CRT glass material | RGB PNG, 2048², tile-safe | generated + verified |
| S02 | `S02_CRT_Scanline_Grid` | fine horizontal scanline field | RGBA PNG, 2048² | generated + verified |
| S03 | `S03_Phosphor_Grain` | subpixel grain and phosphor irregularity | RGB PNG, 2048², tile-safe | generated + verified |
| S04 | `S04_Phosphor_Bloom_Smear` | soft green persistence and bloom streaks | RGBA PNG, 2048² | generated + verified |
| S05 | `S05_Cyan_Diagnostic_Glyph_Field` | abstract non-readable diagnostic geometry | RGBA PNG, 2048² | generated + verified |
| S06 | `S06_Amber_Warning_Bleed` | low-intensity amber status contamination | RGBA PNG, 2048² | generated + verified |
| S07 | `S07_Red_Alert_Bleed` | controlled red alert spill texture | RGBA PNG, 2048² | generated + verified |
| S08 | `S08_Oxidized_Bezel_Metal` | worn dark ferrous panel surface | RGB PNG, 2048², tile-safe | generated + verified |
| S09 | `S09_Riveted_Service_Plate` | separate industrial service plate material | RGB PNG, 2048² | generated + verified |
| S10 | `S10_Cable_Vent_Grime` | soot, dust, grease, and vent residue decal | RGBA PNG, 2048² | generated + verified |
| S11 | `S11_Micro_Scratch_Field` | directional machining scratches and scuffs | RGB PNG, 2048², tile-safe | generated + verified |
| S12 | `S12_Faint_Schematic_Radial` | very low-opacity circular technical overlay | RGB PNG, 2048², additive/screen blend plate | generated + verified |

## Animated textures

| ID | File stem | Function | Loop / timing | Target | Status |
|---|---|---|---|---|---|
| A01 | `A01_CRT_Scanline_Sweep` | slow luminous scanline passing through glass | 2.0 s / 120 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |
| A02 | `A02_Phosphor_Flicker` | subtle irregular phosphor intensity drift | 1.5 s / 90 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |
| A03 | `A03_Cyan_Data_Sweep` | narrow cyan diagnostic sweep | 2.4 s / 144 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |
| A04 | `A04_Amber_Status_Pulse` | mechanical amber status breathing pulse | 1.8 s / 108 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |
| A05 | `A05_Red_Alert_Bleed` | slow red warning contamination, non-strobing | 2.0 s / 120 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |
| A06 | `A06_Terminal_Cursor_Blink` | restrained phosphor cursor blink | 1.0 s / 60 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |
| A07 | `A07_Green_Noise_Drift` | drifting analog noise and faint interference | 3.0 s / 180 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |
| A08 | `A08_Vertical_Scan_Beam` | soft vertical diagnostic beam | 2.5 s / 150 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |
| A09 | `A09_Radial_Schematic_Rotation` | slow technical radial overlay rotation | 6.0 s / 360 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |
| A10 | `A10_Mechanical_LED_Sequence` | asymmetric status-light sequence | 4.0 s / 240 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |
| A11 | `A11_Dust_Pixel_Drift` | sparse dust, dead-pixel, and motes movement | 5.0 s / 300 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |
| A12 | `A12_CRT_Boot_Wipe` | controlled power-on phosphor wipe | 1.2 s / 72 frames | WebM VP9 alpha, 2048², 60 FPS | generated + verified |

## Naming and validation

Each finished file uses its table ID, has no duplicate geometry, and is checked for dimensions, alpha mode where applicable, and accidental readable/copyrighted content. Animated assets are delivered as separate 2048×2048 WebM VP9 alpha files with exact 60 FPS timing.
