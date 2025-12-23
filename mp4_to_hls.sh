#!/bin/bash


SRC_DIR="/var/vds"
HLS_DIR="/tmp/hls"
FFMPEG="/usr/bin/ffmpeg"

# tạo thư mục HLS nếu chưa có
mkdir -p "$HLS_DIR"

# duyệt tất cả file mp4
for file in "$SRC_DIR"/*.mp4; do
    [ -e "$file" ] || continue

    filename=$(basename "$file")
    name="${filename%.*}"

    out_dir="$HLS_DIR/$name"
    playlist="$out_dir/index.m3u8"

    # nếu đã convert rồi thì bỏ qua
    if [ -f "$playlist" ]; then
        echo "[SKIP] $filename already converted"
        continue
    fi

    echo "[CONVERT] $filename → HLS"

    mkdir -p "$out_dir"

    $FFMPEG -y -i "$file" \
        -c:v libx264 -preset veryfast -profile:v main \
        -c:a aac -ar 44100 -ac 2 \
        -f hls \
        -hls_time 4 \
        -hls_playlist_type vod \
        -hls_segment_filename "$out_dir/segment_%03d.ts" \
        "$playlist"

done
