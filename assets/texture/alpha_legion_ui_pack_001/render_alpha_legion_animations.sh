#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/animated"
mkdir -p "$OUT"

COMMON=(-hide_banner -loglevel error -y)
ENC=(-c:v libvpx-vp9 -b:v 0 -crf 30 -deadline good -cpu-used 5 -row-mt 1 -auto-alt-ref 0 -pix_fmt yuva420p -an)

# A01 — covert scanline sweep, 2.0 s / 120 frames.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=3840x2160:r=60:d=2.0,format=rgba" -t 2.0 \
  -vf "drawgrid=w=3840:h=18:t=1:c=0x00ffd5@0.045,drawbox=x=0:y='mod(t*2160/2,2160)-96':w=3840:h=192:color=0x00ffd5@0.18:t=fill,drawbox=x=0:y='mod(t*2160/2,2160)-4':w=3840:h=8:color=0x7dfff0@0.55:t=fill,gblur=sigma=1.2" \
  "${ENC[@]}" "$OUT/ALP_A01_Covert_Scanline_Sweep.webm"

# A02 — tactical grid shimmer, 3.0 s / 180 frames.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=3840x2160:r=60:d=3.0,format=rgba" -t 3.0 \
  -vf "drawgrid=w=160:h=90:t=2:c=0x00d4be@0.075,drawbox=x='mod(t*3840/3,3840)':y=0:w=18:h=2160:color=0x78ffe8@0.20:t=fill,drawbox=x='mod(t*3840/3+1280,3840)':y=0:w=8:h=2160:color=0x34ffe0@0.13:t=fill,drawbox=x='mod(t*3840/3+2560,3840)':y=0:w=4:h=2160:color=0x00d4be@0.16:t=fill" \
  "${ENC[@]}" "$OUT/ALP_A02_Stealth_Grid_Shimmer.webm"

# A03 — scale-pattern glow crawl, 2.4 s / 144 frames.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=3840x2160:r=60:d=2.4,format=rgba" -t 2.4 \
  -vf "drawgrid=w=120:h=70:t=1:c=0x006f69@0.035,drawbox=x='mod(t*3840/2.4,3840)-480':y=620:w=960:h=920:color=0x00ffd5@0.16:t=fill,drawbox=x='mod(t*3840/2.4,3840)-360':y=680:w=720:h=760:color=0x7dfff0@0.12:t=fill,gblur=sigma=2.6" \
  "${ENC[@]}" "$OUT/ALP_A03_Hydra_Scale_Glow.webm"

# A04 — reticle lock brackets, 1.6 s / 96 frames.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=3840x2160:r=60:d=1.6,format=rgba" -t 1.6 \
  -vf "drawbox=x='960+80*sin(2*PI*t/1.6)':y='540+45*sin(2*PI*t/1.6)':w=420:h=12:color=0x7dfff0@0.82:t=fill,drawbox=x='960+80*sin(2*PI*t/1.6)':y='540+45*sin(2*PI*t/1.6)':w=12:h=240:color=0x7dfff0@0.82:t=fill,drawbox=x='2460-80*sin(2*PI*t/1.6)':y='540+45*sin(2*PI*t/1.6)':w=420:h=12:color=0x7dfff0@0.82:t=fill,drawbox=x='2868-80*sin(2*PI*t/1.6)':y='540+45*sin(2*PI*t/1.6)':w=12:h=240:color=0x7dfff0@0.82:t=fill,drawbox=x='960+80*sin(2*PI*t/1.6)':y='1380-45*sin(2*PI*t/1.6)':w=420:h=12:color=0x00d4be@0.74:t=fill,drawbox=x='960+80*sin(2*PI*t/1.6)':y='1152-45*sin(2*PI*t/1.6)':w=12:h=240:color=0x00d4be@0.74:t=fill,drawbox=x='2460-80*sin(2*PI*t/1.6)':y='1380-45*sin(2*PI*t/1.6)':w=420:h=12:color=0x00d4be@0.74:t=fill,drawbox=x='2868-80*sin(2*PI*t/1.6)':y='1152-45*sin(2*PI*t/1.6)':w=12:h=240:color=0x00d4be@0.74:t=fill,gblur=sigma=0.8" \
  "${ENC[@]}" "$OUT/ALP_A04_Reticle_Lock_Cycle.webm"

# A05 — minimap sweep bands, 3.2 s / 192 frames.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=3840x2160:r=60:d=3.2,format=rgba" -t 3.2 \
  -vf "drawbox=x=1470:y=630:w=900:h=900:color=0x00d4be@0.045:t=24,drawbox=x='1470+mod(t*900/3.2,900)':y=630:w=18:h=900:color=0x7dfff0@0.56:t=fill,drawbox=x=1470:y='630+mod(t*900/3.2,900)':w=900:h=10:color=0x00ffd5@0.28:t=fill,drawgrid=w=90:h=90:t=1:c=0x00d4be@0.055" \
  "${ENC[@]}" "$OUT/ALP_A05_Minimap_Sweep_Arc.webm"

# A06 — encrypted abstract data rain, 2.0 s / 120 frames.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=3840x2160:r=60:d=2.0,format=rgba" -t 2.0 \
  -vf "drawbox=x=420:y='mod(t*2160/2+0,2160)-80':w=14:h=80:color=0x00ffd5@0.50:t=fill,drawbox=x=760:y='mod(t*2160/2+540,2160)-90':w=10:h=90:color=0x7dfff0@0.42:t=fill,drawbox=x=1130:y='mod(t*2160/2+880,2160)-110':w=18:h=110:color=0x00d4be@0.55:t=fill,drawbox=x=1490:y='mod(t*2160/2+260,2160)-70':w=12:h=70:color=0x7dfff0@0.35:t=fill,drawbox=x=1910:y='mod(t*2160/2+1180,2160)-120':w=16:h=120:color=0x00ffd5@0.45:t=fill,drawbox=x=2340:y='mod(t*2160/2+720,2160)-90':w=12:h=90:color=0x00d4be@0.42:t=fill,drawbox=x=2820:y='mod(t*2160/2+1430,2160)-80':w=18:h=80:color=0x7dfff0@0.48:t=fill,drawbox=x=3260:y='mod(t*2160/2+310,2160)-110':w=10:h=110:color=0x00ffd5@0.36:t=fill" \
  "${ENC[@]}" "$OUT/ALP_A06_Data_Rain_Encrypted.webm"

# A07 — status LEDs breathing with asymmetric timing, 2.4 s / 144 frames.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=3840x2160:r=60:d=2.4,format=rgba" -t 2.4 \
  -vf "drawbox=x=1120:y=1660:w=90:h=90:color=0x00ffd5@0.45:t=fill:enable='between(mod(t,2.4),0,1.05)',drawbox=x=1270:y=1660:w=90:h=90:color=0x7dfff0@0.62:t=fill:enable='between(mod(t,2.4),0.38,1.45)',drawbox=x=1420:y=1660:w=90:h=90:color=0x00d4be@0.52:t=fill:enable='between(mod(t,2.4),0.82,1.92)',drawbox=x=1570:y=1660:w=90:h=90:color=0xc4fff6@0.50:t=fill:enable='between(mod(t,2.4),1.25,2.4)',drawbox=x=1720:y=1660:w=90:h=90:color=0x00ffd5@0.42:t=fill:enable='between(mod(t,2.4),1.80,2.4)'" \
  "${ENC[@]}" "$OUT/ALP_A07_Status_LED_Breath.webm"

# A08 — hologram tear / split-line distortion, 2.8 s / 168 frames.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=3840x2160:r=60:d=2.8,format=rgba" -t 2.8 \
  -vf "drawbox=x='mod(t*3840/2.8,3840)-380':y=250:w=760:h=9:color=0x7dfff0@0.42:t=fill,drawbox=x='mod(t*3840/2.8+800,3840)-320':y=510:w=640:h=7:color=0x00d4be@0.36:t=fill,drawbox=x='mod(t*3840/2.8+1500,3840)-420':y=930:w=840:h=11:color=0x00ffd5@0.30:t=fill,drawbox=x='mod(t*3840/2.8+2100,3840)-250':y=1320:w=500:h=8:color=0x7dfff0@0.44:t=fill,drawbox=x='mod(t*3840/2.8+3000,3840)-380':y=1770:w=760:h=10:color=0x00d4be@0.34:t=fill,gblur=sigma=1.1" \
  "${ENC[@]}" "$OUT/ALP_A08_Hologram_Tear.webm"

# A09 — stealth shutter transition, 1.2 s / 72 frames.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=3840x2160:r=60:d=1.2,format=rgba" -t 1.2 \
  -vf "drawbox=x=0:y=0:w=3840:h='360*min(t/1.2,1)':color=0x001f1d@0.86:t=fill,drawbox=x=0:y='2160-360*min(t/1.2,1)':w=3840:h='360*min(t/1.2,1)':color=0x001f1d@0.86:t=fill,drawbox=x=0:y='720-240*min(t/1.2,1)':w=3840:h='240*min(t/1.2,1)':color=0x00d4be@0.22:t=fill,drawbox=x=0:y=1200:w=3840:h='240*min(t/1.2,1)':color=0x00ffd5@0.18:t=fill,gblur=sigma=1.4" \
  "${ENC[@]}" "$OUT/ALP_A09_Shutter_Transition.webm"

# A10 — restrained cipher warning pulse, 2.0 s / 120 frames.
ffmpeg "${COMMON[@]}" -f lavfi -i "color=c=black@0.0:s=3840x2160:r=60:d=2.0,format=rgba" -t 2.0 \
  -vf "drawbox=x=1180:y=840:w=1480:h=12:color=0xff2a22@0.42:t=fill:enable='between(mod(t,2),0.0,0.28)+between(mod(t,2),1.2,1.45)',drawbox=x=1180:y=1300:w=1480:h=12:color=0xff2a22@0.36:t=fill:enable='between(mod(t,2),0.0,0.28)+between(mod(t,2),1.2,1.45)',drawbox=x=1360:y=920:w=90:h=34:color=0x00ffd5@0.60:t=fill,drawbox=x=1540:y=1010:w=140:h=28:color=0xff2a22@0.38:t=fill,drawbox=x=1790:y=940:w=110:h=42:color=0x7dfff0@0.50:t=fill,drawbox=x=2050:y=1080:w=170:h=24:color=0x00d4be@0.46:t=fill,drawbox=x=2320:y=970:w=80:h=52:color=0xff2a22@0.32:t=fill,gblur=sigma=0.9" \
  "${ENC[@]}" "$OUT/ALP_A10_Cipher_Warning_Pulse.webm"

echo "Rendered 10 Alpha Legion-inspired animated assets at 3840x2160 / 60 FPS."
