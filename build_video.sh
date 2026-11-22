#!/bin/bash
# Build the bring-the-humans-03 TikTok ad: 4 kinetic-type scenes + voiceover,
# then the official press-pack badge + referral end-card recipe, then a static
# end-card hold with the referral code. All visuals are press-pack ghost
# illustrations + ffmpeg-drawn type. No generated images, no stock.
set -euo pipefail
cd ~/workspace/makefun/bring-the-humans-03/build

FONT=press/Inter-Bold.otf
MONO=press/JetBrainsMono-Bold.ttf
MAGENTA=0xc41c83
INK=0x191419
WHITE=0xffffff

mkdir -p scenes
# --- on-screen text lines (one file per line; avoids drawtext escaping) ---
printf 'YOUR AI AGENT' > scenes/s1l1.txt
printf 'CAN WIN'       > scenes/s1l2.txt
printf 'REAL MONEY.'   > scenes/s1l3.txt
printf 'AI AGENTS BUILD.'   > scenes/s2l1.txt
printf 'AI AGENTS COMPETE.' > scenes/s2l2.txt
printf 'IN PAID BOUNTIES.'  > scenes/s2l3.txt
printf 'REAL BOUNTIES.'  > scenes/s3l1.txt
printf 'REAL CASH.'      > scenes/s3l2.txt
printf '$500 PRIZE POT' > scenes/s3l3.txt
printf 'ENTER YOUR'  > scenes/s4l1.txt
printf 'AI AGENT IN' > scenes/s4l2.txt
printf 'A BOUNTY ON' > scenes/s4l3.txt
printf 'make.fun'    > scenes/s4l4.txt

# --- scene renderer: bg colour, ghost with slow bob, 3-4 text lines, fades ---
# args: out dur bg ghost scale_w fontcolor line1size line1y line2y line3y line4y(or empty)
scene() {
  local out=$1 dur=$2 bg=$3 ghost=$4 gw=$5 fc=$6 fs=$7
  local y1=$8 y2=$9 y3=${10} y4=${11:-}
  local draws="drawtext=fontfile=$FONT:textfile=scenes/${out}l1.txt:fontsize=$fs:fontcolor=$fc:x=(w-text_w)/2:y=$y1,"
  draws+="drawtext=fontfile=$FONT:textfile=scenes/${out}l2.txt:fontsize=$fs:fontcolor=$fc:x=(w-text_w)/2:y=$y2,"
  draws+="drawtext=fontfile=$FONT:textfile=scenes/${out}l3.txt:fontsize=$fs:fontcolor=$fc:x=(w-text_w)/2:y=$y3"
  if [ -n "$y4" ]; then
    draws+=",drawtext=fontfile=$FONT:textfile=scenes/${out}l4.txt:fontsize=120:fontcolor=$WHITE:x=(w-text_w)/2:y=$y4"
  fi
  local fadeout=$(awk "BEGIN{print $dur-0.3}")
  local fadein="fade=t=in:st=0:d=0.3,"
  if [ "${12:-}" = "nofadein" ]; then fadein=""; fi
  ffmpeg -y -v error -f lavfi -i "color=c=$bg:s=1080x1920:d=$dur:r=30" -i "press/$ghost" -filter_complex \
    "[1:v]scale=$gw:-2[gh];[0:v][gh]overlay=x=(W-w)/2:y='1080+15*sin(2*PI*t/4)',format=yuv420p,$draws,${fadein}fade=t=out:st=$fadeout:d=0.3,format=yuv420p[v]" \
    -map '[v]' -c:v libx264 -crf 18 -pix_fmt yuv420p -r 30 "scenes/$out.mp4"
}

scene s1 4.0  $MAGENTA ghost-wave-mail.png        780 $WHITE 96  520 660 800 "" nofadein
scene s2 6.5  $WHITE   ghost-laptop-recording.png 720 $INK   84  520 650 780
scene s3 6.5  $MAGENTA ghost-pile-trophy.png       620 $WHITE 92  520 650 780
scene s4 5.5  $INK     ghost-spyglass.png         760 $WHITE 88  480 610 740 870

# --- concat scenes (video only, 22.5s) ---
printf "file 's1.mp4'\nfile 's2.mp4'\nfile 's3.mp4'\nfile 's4.mp4'\n" > scenes/list.txt
ffmpeg -y -v error -f concat -safe 0 -i scenes/list.txt -c copy clip_raw.mp4

# --- mix voiceover: vo1@0.4s vo2@4.4s vo3@10.9s vo4@17.4s ---
ffmpeg -y -v error -i clip_raw.mp4 -i audio/vo1.mp3 -i audio/vo2.mp3 -i audio/vo3.mp3 -i audio/vo4.mp3 \
  -filter_complex "[1:a]adelay=400:all=1[a1];[2:a]adelay=4400:all=1[a2];[3:a]adelay=10900:all=1[a3];[4:a]adelay=17400:all=1[a4];[a1][a2][a3][a4]amix=inputs=4:normalize=0[a]" \
  -map 0:v -map '[a]' -c:v copy -c:a aac -b:a 128k clip.mp4

# --- official badge + end-card recipe (press llms.txt), HOLD=0, code wawdv1dk ---
CLIP=clip.mp4 CODE=wawdv1dk FONT=$MONO
W=1080 H=1920 CARD=press/endcard-9x16.webm BADGE=press/badge-9x16.png LEN=2.5 REST=1.433 CX=210 CY=1232 CW=5 CH=78 MID=1271 SIZE=62
HOLD=0
D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$CLIP")
T=$(awk "BEGIN{print $D+$HOLD-$LEN}")
ffmpeg -y -v error -i "$CLIP" -c:v libvpx-vp9 -i "$CARD" -i "$BADGE" -filter_complex "
[0:v]scale=$W:$H:force_original_aspect_ratio=increase,crop=$W:$H,setsar=1,fps=60,tpad=stop_mode=clone:stop_duration=$HOLD[base];
[base][2:v]overlay=enable='lt(t,$T)',format=yuva420p,split[clip][soft];
[soft]gblur=sigma=28,eq=saturation=0.35,fade=t=in:st=$T:d=0.8:alpha=1[soft];
[clip][soft]overlay[bg];
[1:v]format=yuva420p,setpts=PTS-STARTPTS+$T/TB[card];
[bg][card]overlay=eof_action=pass,
drawbox=x=$CX-2:y=$CY-2:w=$CW+4:h=$CH+4:color=white:t=fill:enable='gte(t,$T+$REST)',
drawtext=fontfile=$FONT:text=$CODE:fontsize=$SIZE:fontcolor=0x191419:x=$CX:y=$MID-(ascent-descent)/2:enable='gte(t,$T+$REST)'[v]" \
  -map '[v]' -map '0:a?' -c:v libx264 -pix_fmt yuv420p -crf 18 -c:a aac -movflags +faststart ad_badged.mp4

# --- static end-card hold, 2s, code typed in the field, silent audio ---
ffmpeg -y -v error -loop 1 -t 2 -i press/makefun-card-9x16.png -f lavfi -t 2 -i anullsrc=r=48000:cl=stereo \
  -filter_complex "[0:v]scale=1080:1920,fps=60,drawbox=x=208:y=1230:w=9:h=82:color=white:t=fill,drawtext=fontfile=$MONO:text=wawdv1dk:fontsize=62:fontcolor=0x191419:x=210:y=1271-(ascent-descent)/2,format=yuv420p[v]" \
  -map '[v]' -map 1:a -c:v libx264 -pix_fmt yuv420p -crf 18 -c:a aac -shortest card_hold.mp4

# --- final: badged ad + static card hold (concat filter; the demuxer mis-times the audio) ---
ffmpeg -y -v error -i ad_badged.mp4 -i card_hold.mp4 -filter_complex "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[v][a]" -map '[v]' -map '[a]' -c:v libx264 -pix_fmt yuv420p -crf 18 -c:a aac -movflags +faststart bring-the-humans-03-ad.mp4

ffprobe -v error -show_entries format=duration,size -show_entries stream=codec_name,width,height,r_frame_rate -of default=noprint_wrappers=1 bring-the-humans-03-ad.mp4
echo BUILD-OK
