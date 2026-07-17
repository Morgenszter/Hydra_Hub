# Alpha Legion-Inspired UI Pack 001 — Render Notes

## Output

- 20 static PNG assets: 4096×4096, RGBA, transparent background.
- 10 animated WebM overlay assets: 3840×2160, VP9 alpha, 60 FPS.
- All animated outputs were verified for frame rate, resolution, duration, frame count, and `alpha_mode=1`.

## Art direction

The pack uses an original covert hydra-legion visual language: blackened steel, oxidized teal, cyan phosphor, scale-like mechanical cuts, stealth scanner geometry, and tactical UI glow.

No official insignia, faction heraldry, copied readable text, logos, or trademarked screen layouts are used.

## Engine notes

- Godot: import static PNGs as lossless or high-quality VRAM compressed UI textures.
- For WebM overlays, use alpha blend or additive/screen-like shader treatment depending on the effect.
- Keep animated overlays subtle; the red warning asset is deliberately non-strobing.
- Static assets are designed as separate TextureRect/NinePatchRect/custom Control pieces, not as a full assembled screen.
