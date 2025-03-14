#!/bin/bash

# Create temp directory in the current directory
TEMP_DIR="./temp_ocr"
mkdir -p "$TEMP_DIR"

# Set crop region (BL = Bottom Left, BR = Bottom Right, TL = Top Left, TR = Top Right)
CROP_REGION="BR"  # Change this to BR, TL, or TR as needed

# Set target text to detect
TARGET_TEXT="skip"  # Change this to whatever text you want to detect

while true; do
    SCREENSHOT="$TEMP_DIR/screen.png"
    CROPPED="$TEMP_DIR/cropped.png"
    PROCESSED="$TEMP_DIR/processed.png"
    TEXT_FILE="$TEMP_DIR/output_text.txt"

    # Capture Screenshot
    adb shell screencap -p /sdcard/screen.png
    adb pull /sdcard/screen.png "$SCREENSHOT"

    # Get Image Dimensions
    WIDTH=$(magick identify -format "%w" "$SCREENSHOT" 2>/dev/null)
    HEIGHT=$(magick identify -format "%h" "$SCREENSHOT" 2>/dev/null)

    if [[ -z "$WIDTH" || -z "$HEIGHT" ]]; then
        echo "Error: ImageMagick couldn't process the image!"
        exit 1
    fi

    # Calculate crop coordinates based on region
    CROP_WIDTH=$((WIDTH / 2))
    CROP_HEIGHT=$((HEIGHT / 2))

    case "$CROP_REGION" in
        "BL") CROP_X=0; CROP_Y=$((HEIGHT / 2)) ;;  # Bottom Left
        "BR") CROP_X=$((WIDTH / 2)); CROP_Y=$((HEIGHT / 2)) ;;  # Bottom Right
        "TL") CROP_X=0; CROP_Y=0 ;;  # Top Left
        "TR") CROP_X=$((WIDTH / 2)); CROP_Y=0 ;;  # Top Right
        *) echo "Invalid CROP_REGION"; exit 1 ;;
    esac

    # Crop the specified region
    magick "$SCREENSHOT" -crop ${CROP_WIDTH}x${CROP_HEIGHT}+${CROP_X}+${CROP_Y} "$CROPPED"

    # Improve image contrast for OCR
    magick "$CROPPED" -contrast-stretch 5%x5% "$PROCESSED"

    # Extract Text
    tesseract "$PROCESSED" "$TEMP_DIR/output_text" > /dev/null 2>&1
    TEXT=$(cat "$TEXT_FILE")

    # Print extracted text
    echo "Extracted Text: $TEXT"

    # Check for target text
    if echo "$TEXT" | grep -iq "$TARGET_TEXT"; then
        echo "Detected: $TARGET_TEXT - Pressing Enter"
        adb shell input keyevent 66
    fi

    # Sleep before next iteration
    sleep 3
done
