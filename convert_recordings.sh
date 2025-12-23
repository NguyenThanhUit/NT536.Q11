#!/bin/bash

# Convert FLV to MP4
# FLV: /var/www/html/recordings-flv/
# MP4: /var/www/html/recordings-mp4/

RECORDINGS_DIR="/var/www/html/recordings-flv"
OUTPUT_DIR="/var/www/html/recordings-mp4"
LOG_FILE="/var/log/convert_recordings.log"


# Tạo thư mục
mkdir -p "$OUTPUT_DIR"
chown -R nginx:nginx "$OUTPUT_DIR"
chmod -R 755 "$OUTPUT_DIR"

# Đếm file
total_files=$(find "$RECORDINGS_DIR" -maxdepth 1 -name "*.flv" -type f | wc -l)
echo "📂 FLV source: $RECORDINGS_DIR" | tee -a "$LOG_FILE"
echo "📂 MP4 output: $OUTPUT_DIR" | tee -a "$LOG_FILE"
echo "Found $total_files FLV file(s)" | tee -a "$LOG_FILE"

if [ "$total_files" -eq 0 ]; then
    echo "No FLV files found. Exiting." | tee -a "$LOG_FILE"
    exit 0
fi

converted=0
failed=0
skipped=0

# Convert
for flv_file in "$RECORDINGS_DIR"/*.flv; do
    [ -f "$flv_file" ] || continue
    
    filename=$(basename "$flv_file" .flv)
    mp4_file="$OUTPUT_DIR/${filename}.mp4"
    
    if [ -f "$mp4_file" ]; then
        echo "⏭  Skipped: $mp4_file" | tee -a "$LOG_FILE"
        ((skipped++))
        continue
    fi
    
    
    ffmpeg -i "$flv_file" \
        -c:v libx264 -preset fast -crf 23 \
        -c:a aac -b:a 128k \
        -movflags +faststart \
        "$mp4_file" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        flv_size=$(du -h "$flv_file" | cut -f1)
        mp4_size=$(du -h "$mp4_file" | cut -f1)
        
        echo "✅ Success! FLV: $flv_size → MP4: $mp4_size" | tee -a "$LOG_FILE"
        
        # Xóa FLV sau khi convert
        rm "$flv_file"
        echo "🗑️  Deleted FLV" | tee -a "$LOG_FILE"
        
        ((converted++))
    else
        echo "❌ Failed" | tee -a "$LOG_FILE"
        ((failed++))
    fi
done

