#!/bin/bash

set -euo pipefail

if (( $# < 1 || $# > 2 )); then
    echo "Usage: $0 raw-recording.mov [output.mp4]" >&2
    exit 64
fi

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
input="$1"
output="${2:-$repository_root/docs/product-hunt/assets/demo/siderefresh-demo-final.mp4}"
overwrite="${SIDEREFRESH_OVERWRITE:-0}"

if [[ ! -f "$input" ]]; then
    echo "Input recording not found: $input" >&2
    exit 66
fi
for command in ffmpeg ffprobe; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required demo export command not found: $command" >&2
        exit 69
    fi
done
if [[ -e "$output" && "$overwrite" != "1" ]]; then
    echo "Output exists; set SIDEREFRESH_OVERWRITE=1 to replace it." >&2
    exit 73
fi

output_directory="$(dirname "$output")"
mkdir -p "$output_directory"
export_root="$(
    mktemp -d "$output_directory/.siderefresh-demo-export.XXXXXX"
)"
temporary_output="$export_root/demo.mp4"
cleanup() {
    rm -rf "$export_root"
}
trap cleanup EXIT

ffmpeg -y -i "$input" \
    -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black,fps=30" \
    -c:v libx264 \
    -preset slow \
    -crf 18 \
    -pix_fmt yuv420p \
    -c:a aac \
    -b:a 192k \
    -movflags +faststart \
    "$temporary_output"

video_codec="$(
    ffprobe -v error -select_streams v:0 \
        -show_entries stream=codec_name -of default=nw=1:nk=1 \
        "$temporary_output"
)"
width="$(
    ffprobe -v error -select_streams v:0 \
        -show_entries stream=width -of default=nw=1:nk=1 \
        "$temporary_output"
)"
height="$(
    ffprobe -v error -select_streams v:0 \
        -show_entries stream=height -of default=nw=1:nk=1 \
        "$temporary_output"
)"
audio_codec="$(
    ffprobe -v error -select_streams a:0 \
        -show_entries stream=codec_name -of default=nw=1:nk=1 \
        "$temporary_output"
)"
duration="$(
    ffprobe -v error -show_entries format=duration \
        -of default=nw=1:nk=1 "$temporary_output"
)"
if [[ "$video_codec" != "h264" || "$width" != "1920" \
    || "$height" != "1080" || "$audio_codec" != "aac" ]] || \
    ! awk -v duration="$duration" \
        'BEGIN { exit !(duration >= 45 && duration <= 75) }'; then
    echo "Export must be 45-75s, 1920x1080 H.264 with AAC audio." >&2
    exit 65
fi

if [[ "$overwrite" = "1" ]]; then
    mv -f "$temporary_output" "$output"
elif ! ln "$temporary_output" "$output" 2>/dev/null; then
    echo "Output appeared during export; refusing to replace it." >&2
    exit 73
else
    rm "$temporary_output"
fi

echo "$output"
