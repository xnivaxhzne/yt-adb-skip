#!/bin/bash

# Create temp directory in the current directory
TEMP_DIR="./temp_ocr"
mkdir -p "$TEMP_DIR"

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

    # Crop bottom-left half
    CROP_WIDTH=$((WIDTH / 2))
    CROP_HEIGHT=$((HEIGHT / 2))
    CROP_X=0
    CROP_Y=$((HEIGHT / 2))

    magick "$SCREENSHOT" -crop ${CROP_WIDTH}x${CROP_HEIGHT}+${CROP_X}+${CROP_Y} "$CROPPED"

    # Improve image contrast for OCR
    magick "$CROPPED" -contrast-stretch 5%x5% "$PROCESSED"

    # Extract Text
    tesseract "$PROCESSED" "$TEMP_DIR/output_text" > /dev/null 2>&1
    TEXT=$(cat "$TEXT_FILE")

    # Print extracted text
    echo "Extracted Text: $TEXT"

    # Check for 'Parithabangal'
    if echo "$TEXT" | grep -iq "Parithabangal"; then
        echo "Detected: Parithabangal - Pressing Enter"
        adb shell input keyevent 66
    fi

    # Sleep before next iteration
    sleep 2
done
