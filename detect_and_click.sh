#!/bin/bash

while true; do
    echo "Checking for Skip Ad button or Parithabangal..."

    # Step 1: Capture Screenshot from Android TV
    adb shell screencap -p /sdcard/screen.png

    # Step 2: Pull Screenshot to Local Machine
    adb pull /sdcard/screen.png ./screen.png >/dev/null 2>&1

    # Step 3: Run OCR with Tesseract
    tesseract screen.png output_text >/dev/null 2>&1

    # Step 4: Read Extracted Text
    extracted_text=$(cat output_text.txt)

    # Step 5: Print Extracted Content
    echo "Extracted Text: "
    echo "--------------------------------"
    echo "$extracted_text"
    echo "--------------------------------"

    # Step 6: Check for "Skip" in Extracted Text
    if echo "$extracted_text" | grep -i "skip"; then
        echo "🎯 Skip Ad button detected!"
    fi

    # Step 7: Check for "Parithabangal" and Press Enter
    if echo "$extracted_text" | grep -i "Parithabangal"; then
        echo "✅ 'Parithabangal' found! Pressing ENTER..."
        adb shell input keyevent KEYCODE_ENTER
    fi

    # Step 8: Wait for 2 seconds before checking again
    sleep 2
done
