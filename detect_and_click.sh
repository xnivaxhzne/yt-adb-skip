#!/bin/bash

while true; do
    # Capture Screenshot
    adb shell screencap -p /sdcard/screen.png
    adb pull /sdcard/screen.png .

    # Get Image Dimensions
    WIDTH=$(magick identify -format "%w" screen.png)
    HEIGHT=$(magick identify -format "%h" screen.png)

    # Calculate Cropping for Left-Bottom Half
    CROP_WIDTH=$((WIDTH / 2))
    CROP_HEIGHT=$((HEIGHT / 2))
    CROP_X=0  # Left side
    CROP_Y=$((HEIGHT / 2))  # Bottom half

    # Crop Image (Left-Bottom)
    magick screen.png -crop ${CROP_WIDTH}x${CROP_HEIGHT}+${CROP_X}+${CROP_Y} cropped.png

    # Extract Text using Tesseract
    tesseract cropped.png output_text

    # Read Extracted Text
    TEXT=$(cat output_text.txt)

    # Check for 'Parithabangal'
    if echo "$TEXT" | grep -iq "Parithabangal"; then
        echo "Detected: Parithabangal - Pressing Enter"
        adb shell input keyevent 66  # Simulate Enter key
    fi

    # Sleep to avoid excessive CPU usage
    sleep 2
done
