# Cogitator Texture Pack 001 — Animation Render Notes

This pack contains 12 animated texture assets rendered as individual 2048×2048 WebM VP9 alpha files at 60 FPS.

## Verification summary

- Resolution: all animated files verified at 2048×2048.
- Frame rate: all animated files verified at 60/1 FPS.
- Alpha: all animated files report `alpha_mode=1`.
- Frame counts: all animated files match their intended timing exactly.
- Loop policy: A01–A11 are authored as seamless loops. A12 is a one-shot transition texture intended for controlled boot/power-on wipes.

## Intended compositing

- Green CRT effects: screen/additive at low intensity over dark terminal glass.
- Cyan diagnostics: additive/screen or UI-emissive material slot.
- Amber/red warning effects: additive with clamped intensity; avoid hard strobe.
- Cursor, LED, dust, and boot wipe: alpha blend or premultiplied alpha depending on engine import pipeline.

## Authorship note

All visuals are original grimdark industrial terminal textures inspired by the supplied cogitator reference mood. No official marks, faction insignia, readable copied text, exact UI layout, or branded iconography are reproduced.
