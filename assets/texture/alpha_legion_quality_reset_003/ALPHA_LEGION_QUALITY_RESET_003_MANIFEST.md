# Alpha Legion Quality Reset 003

**Status:** final static test pack complete + verified  
**Count:** 5 individual static screen-panel PNG assets  
**Animation policy:** none.  
**Reason for reset:** previous batches leaned too much into glowing frame silhouettes. This pack focuses on usable HUD screens: dark CRT/glass interiors, armored metal bezels, restrained glow, and readable empty areas for dynamic Godot text.

## Assets

| # | File | Function | Format | Status |
|---|---|---|---|---|
| 01 | `ALP3_S01_Voice_Hub_Terminal_Screen.png` | wide Voice HUB terminal screen panel | 4096x1536 PNG RGBA | generated + verified |
| 02 | `ALP3_S02_Central_Status_Armored_Display.png` | central armored status display panel | 4096x2304 PNG RGBA | generated + verified |
| 03 | `ALP3_S03_LED_RGB_Heater_Hex_Screen.png` | hexagonal LED/RGB/heater control screen | 4096x4096 PNG RGBA | generated + verified |
| 04 | `ALP3_S04_Right_Weather_Auspex_Screen.png` | right-side weather auspex screen panel | 3072x4096 PNG RGBA | generated + verified |
| 05 | `ALP3_S05_Cogitator_Message_Display.png` | cogitator message display with dark CRT glass | 4096x2304 PNG RGBA | generated + verified |

## Godot usage

- Use each file as a TextureRect-backed screen/panel component.
- The interior dark glass is part of the PNG, so text can be placed above it without relying on broken shaders.
- Outside the panel is transparent alpha.
- No official marks, copied heraldry, readable text, or trademarked layouts are used.
