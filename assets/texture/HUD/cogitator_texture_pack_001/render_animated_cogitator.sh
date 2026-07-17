#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/animated"
mkdir -p "$OUT"

COMMON=(-hide_banner -loglevel error -y)
ENC=(-c:v libvpx-vp9 -b:v 0 -crf 30 -deadline good -cpu-used 4 -row-mt 1 -auto-alt-ref 0 -pix_fmt yuva420p -an)

# A01 — moving scanline luminance field, one complete phase every 2 seconds.
ffmpeg "${COMMON[@]}" -loop 1 -framerate 60 -i "$ROOT/S02_CRT_Scanline_Grid.png" -t 2.0 \
  -vf "geq=lum='lum(X,Y)*(0.94+0.06*sin(2*PI*(Y+240*T)/24))':cb='cb(X,Y)':cr='cr(X,Y)'" \
  "${ENC[@]}" "$OUT/A01_CRT_Scanline_Sweep.webm"

# A02 — restrained analog phosphor drift, phase-locked to 1.5 seconds.
ffmpeg "${COMMON[@]}" -loop 1 -framerate 60 -i "$ROOT/S03_Phosphor_Grain.png" -t 1.5 \
  -vf "geq=lum='lum(X,Y)*(0.965+0.025*sin(2*PI*T/1.5)+0.01*sin(2*PI*7*T/1.5))':cb='cb(X,Y)':cr='cr(X,Y)'" \
  "${ENC[@]}" "$OUT/A02_Phosphor_Flicker.webm"

# A03 — a cyan diagnostic sweep modulates only the alpha of the glyph field.
ffmpeg "${COMMON[@]}" -loop 1 -framerate 60 -i "$ROOT/S05_Cyan_Diagnostic_Glyph_Field.png" -t 2.4 \
  -vf "geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='alpha(X,Y)*(0.35+0.65*(0.5+0.5*cos(2*PI*(X-(2048/2.4)*T)/2048)))'" \
  "${ENC[@]}" "$OUT/A03_Cyan_Data_Sweep.webm"

# A04 — asymmetric amber breathing pulse, deliberately below strobe intensity.
ffmpeg "${COMMON[@]}" -loop 1 -framerate 60 -i "$ROOT/S06_Amber_Warning_Bleed.png" -t 1.8 \
  -vf "geq=r='r(X,Y)*(0.62+0.38*(0.5+0.5*sin(2*PI*T/1.8)))':g='g(X,Y)*(0.62+0.38*(0.5+0.5*sin(2*PI*T/1.8)))':b='b(X,Y)*(0.62+0.38*(0.5+0.5*sin(2*PI*T/1.8)))':a='alpha(X,Y)'" \
  "${ENC[@]}" "$OUT/A04_Amber_Status_Pulse.webm"

# A05 — slow red alert contamination; no hard blink.
ffmpeg "${COMMON[@]}" -loop 1 -framerate 60 -i "$ROOT/S07_Red_Alert_Bleed.png" -t 2.0 \
  -vf "geq=r='r(X,Y)*(0.72+0.28*(0.5+0.5*sin(2*PI*T/2.0)))':g='g(X,Y)*(0.72+0.28*(0.5+0.5*sin(2*PI*T/2.0)))':b='b(X,Y)*(0.72+0.28*(0.5+0.5*sin(2*PI*T/2.0)))':a='alpha(X,Y)'" \
  "${ENC[@]}" "$OUT/A05_Red_Alert_Bleed.webm"

# A06 — isolated phosphor cursor bar on transparent canvas.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=2048x2048:r=60:d=1.0" -t 1.0 \
  -vf "drawbox=x=1270:y=1490:w=84:h=26:color=0x59ff9d@0.16:t=fill:enable='lt(mod(t,1),0.5)',drawbox=x=1282:y=1495:w=60:h=16:color=0x8affbb@0.92:t=fill:enable='lt(mod(t,1),0.5)'" \
  "${ENC[@]}" "$OUT/A06_Terminal_Cursor_Blink.webm"

# A07 — periodic green noise drift produced from spatial phase, so the loop closes exactly.
ffmpeg "${COMMON[@]}" -loop 1 -framerate 60 -i "$ROOT/S03_Phosphor_Grain.png" -t 3.0 \
  -vf "geq=r='r(X,Y)*(0.98+0.02*sin(2*PI*(X/320+T/3)))':g='g(X,Y)*(0.96+0.04*sin(2*PI*(X/320+T/3)))':b='b(X,Y)*(0.98+0.02*sin(2*PI*(X/320+T/3)))'" \
  "${ENC[@]}" "$OUT/A07_Green_Noise_Drift.webm"

# A08 — full-frame vertical diagnostic beam, one screen traverse every 2.5 seconds.
ffmpeg "${COMMON[@]}" -loop 1 -framerate 60 -i "$ROOT/S01_CRT_Glass_Base.png" -t 2.5 \
  -vf "drawbox=x='mod(t*2048/2.5,2048)':y=0:w=28:h=ih:color=0x45f0b2@0.28:t=fill" \
  "${ENC[@]}" "$OUT/A08_Vertical_Scan_Beam.webm"

# A09 — slow radial diagnostic rotation; one complete revolution every 6 seconds.
ffmpeg "${COMMON[@]}" -loop 1 -framerate 60 -i "$ROOT/S12_Faint_Schematic_Radial.png" -t 6.0 \
  -vf "rotate=2*PI*t/6:ow=iw:oh=ih:bilinear=1:fillcolor=black@0" \
  "${ENC[@]}" "$OUT/A09_Radial_Schematic_Rotation.webm"

# A10 — offset service LEDs; the order is intentionally asymmetric and non-periodic within the cycle.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=2048x2048:r=60:d=4.0" -t 4.0 \
  -vf "drawbox=x=640:y=1390:w=34:h=92:color=0x39e8c0@0.8:t=fill:enable='between(mod(t,4),0.0,0.72)',drawbox=x=720:y=1390:w=34:h=92:color=0xffb84a@0.86:t=fill:enable='between(mod(t,4),0.65,1.7)',drawbox=x=800:y=1390:w=34:h=92:color=0x49ff9c@0.82:t=fill:enable='between(mod(t,4),1.6,2.35)',drawbox=x=880:y=1390:w=34:h=92:color=0xf0a43a@0.86:t=fill:enable='between(mod(t,4),2.2,3.35)',drawbox=x=960:y=1390:w=34:h=92:color=0x39e8c0@0.78:t=fill:enable='between(mod(t,4),3.28,4.0)'" \
  "${ENC[@]}" "$OUT/A10_Mechanical_LED_Sequence.webm"

# A11 — sparse dust and dead-pixel motes drifting on long, phase-locked paths.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=2048x2048:r=60:d=5.0" -t 5.0 \
  -vf "drawbox=x='mod(t*2048/5+120,2048)':y='640+42*sin(2*PI*t/5)':w=12:h=12:color=0x7dffb0@0.62:t=fill,drawbox=x='mod(t*409.6+760,2048)':y='980+58*cos(2*PI*t/5)':w=8:h=8:color=0x42d5d0@0.54:t=fill,drawbox=x='mod(t*819.2+420,2048)':y='1260+34*sin(2*PI*t/5+1.2)':w=16:h=16:color=0xc3ff9e@0.46:t=fill,drawbox=x='mod(t*1228.8+1540,2048)':y='420+68*cos(2*PI*t/5+2.1)':w=6:h=6:color=0x6fffa8@0.72:t=fill" \
  "${ENC[@]}" "$OUT/A11_Dust_Pixel_Drift.webm"

# A12 — one-shot phosphor power-on wipe, with soft edge bloom and no hard strobe.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=2048x2048:r=60:d=1.2" -t 1.2 \
  -vf "drawbox=x=0:y='ih/2-(ih*min(t/1.2,1))/2':w=iw:h='ih*min(t/1.2,1)':color=0x45ffae@0.78:t=fill,gblur=sigma=4" \
  "${ENC[@]}" "$OUT/A12_CRT_Boot_Wipe.webm"

echo "Rendered 12 animated Cogitator assets at 2048x2048 / 60 FPS."
