#!/bin/bash
# Convert images in a folder to a format you pick, using macOS sips,
# then delete the original after a successful conversion.
#
# The script asks you:
#   1. Which format to convert to (pick a number from the list).
#   2. Which folder to convert (press Enter to use the folder this script is in).
#   3. To confirm before anything is changed.
#
# Files already in the format you pick are left alone.
#
# Usage: ./"Image Converter.sh"

set -euo pipefail

shopt -s nullglob nocaseglob

# Formats you can convert to. (sips can't save as webp, so it isn't offered.)
TARGETS=(jpeg png heic avif tiff gif bmp pdf)

# Image formats this script converts from.
SOURCE_EXTS=(jpg jpeg png gif webp heic heif tiff tif bmp avif jp2 ppm pgm tga)

script_dir="$(cd "$(dirname "$0")" && pwd)"

# --- 1. Pick a format ---
echo "Convert images to which format?"
for i in "${!TARGETS[@]}"; do
    echo "  $((i + 1))) ${TARGETS[$i]}"
done
while true; do
    read -r -p "Type a number (1-${#TARGETS[@]}): " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#TARGETS[@]}" ]; then
        target="${TARGETS[$((choice - 1))]}"
        break
    fi
    echo "Please type a number from the list."
done

# Endings that are the same format as the target. Those files are skipped.
case "$target" in
    jpeg) skip_exts="jpg jpeg" ;;
    tiff) skip_exts="tif tiff" ;;
    heic) skip_exts="heic heif" ;;
    *)    skip_exts="$target" ;;
esac

# --- 2. Pick a folder ---
echo
echo "Which folder? Press Enter to use: $script_dir"
while true; do
    # No -r here, so a dragged-in path like My\ Folder turns into My Folder.
    read -e -p "Or type or drag a folder here: " folder
    # Remove quotes around the path and turn ~ into your home folder.
    folder="${folder#[\"\']}"
    folder="${folder%[\"\']}"
    folder="${folder/#\~/$HOME}"
    if [ -z "$folder" ]; then
        folder="$script_dir"
    fi
    if [ -d "$folder" ]; then
        break
    fi
    echo "Can't find that folder: $folder"
done
cd "$folder"

# --- 3. Find the images and confirm ---
files=()
for ext in "${SOURCE_EXTS[@]}"; do
    case " $skip_exts " in
        *" $ext "*) continue ;;
    esac
    for src in *."$ext"; do
        files+=("$src")
    done
done

if [ "${#files[@]}" -eq 0 ]; then
    echo "No images to convert in $(pwd)."
    exit 0
fi

echo
echo "Found ${#files[@]} image(s) in $(pwd) to convert to $target."
echo "Each original is deleted after it converts."
read -r -p "Go ahead? (y/n): " answer
case "$answer" in
    [yY]*) ;;
    *) echo "Cancelled. Nothing was changed."; exit 0 ;;
esac

# --- 4. Convert ---
count=0
failed=0
for src in "${files[@]}"; do
    base="${src%.*}"
    out="$base.$target"

    # Don't overwrite a file that's already there.
    if [ -e "$out" ]; then
        out="$base-converted.$target"
    fi
    n=2
    while [ -e "$out" ]; do
        out="$base-converted-$n.$target"
        n=$((n + 1))
    done

    echo "Converting: $src -> $out"
    if sips -s format "$target" "$src" --out "$out" >/dev/null 2>&1; then
        rm -f "$src"
        echo "Deleted original: $src"
        count=$((count + 1))
    else
        rm -f "$out"
        echo "FAILED to convert: $src (original kept)" >&2
        failed=$((failed + 1))
    fi
done

echo
echo "Done. Converted and removed $count original(s)."
if [ "$failed" -gt 0 ]; then
    echo "$failed file(s) failed and were kept."
fi
