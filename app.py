import cv2
import time
import subprocess
import easyocr  # Import EasyOCR

# Configurations
CROP_REGION = "BR"  # Options: BL, BR, TL, TR
TARGET_TEXT = "skip"  # Change this to detect other words
TEMP_DIR = "./temp_ocr"

# Create temp directory
subprocess.run(["mkdir", "-p", TEMP_DIR])

# Initialize EasyOCR Reader
reader = easyocr.Reader(['en'])


def check_adb_connection():
    """Check if the device is connected via ADB."""
    result = subprocess.run(["adb", "devices"], capture_output=True, text=True)

    # Get the output as a string
    output = result.stdout

    # Check if any devices are listed after the "List of devices attached" line
    lines = output.splitlines()
    devices = [line for line in lines if line.strip(
    ) and not line.startswith("List of devices attached")]

    # If no devices are connected, the list will be empty
    if devices:
        print("Device(s) connected.")
        return True
    else:
        print("No devices connected.")
        return False


def connect_to_device(tv_ip):
    """Connect to the Android device using ADB over IP."""
    result = subprocess.run(["adb", "connect", tv_ip],
                            capture_output=True, text=True)
    if "connected" in result.stdout:
        print(f"Successfully connected to {tv_ip}")
    else:
        print(f"Failed to connect to {tv_ip}: {result.stdout}")


def disconnect_device():
    """Disconnect from the current ADB connection."""
    subprocess.run(["adb", "disconnect"], capture_output=True, text=True)
    print("Disconnected from the device.")


def capture_screenshot():
    """Capture a screenshot from the Android device."""
    subprocess.run(["adb", "shell", "screencap", "-p", "/sdcard/screen.png"])
    subprocess.run(["adb", "pull", "/sdcard/screen.png",
                   f"{TEMP_DIR}/screen.png"])


def crop_image(image_path, region="BR"):
    """Crop image based on the selected region."""
    img = cv2.imread(image_path)
    height, width, _ = img.shape
    crop_w, crop_h = width // 2, height // 2

    regions = {
        "BL": (0, crop_h, crop_w, height),         # Bottom Left
        "BR": (crop_w, crop_h, width, height),     # Bottom Right
        "TL": (0, 0, crop_w, crop_h),              # Top Left
        "TR": (crop_w, 0, width, crop_h)           # Top Right
    }

    if region not in regions:
        raise ValueError("Invalid region selection.")

    x1, y1, x2, y2 = regions[region]
    cropped = img[y1:y2, x1:x2]
    cropped_path = f"{TEMP_DIR}/cropped.png"
    cv2.imwrite(cropped_path, cropped)
    return cropped_path


def run_easyocr(image_path):
    """Use EasyOCR on the image."""
    result = reader.readtext(image_path)
    # Extract text from OCR results
    text = " ".join([item[1] for item in result])
    return text


def get_media_session_actions():
    """Get media session actions from YouTube TV using adb."""
    result = subprocess.run(["adb", "shell", "dumpsys", "media_session", "|", "grep",
                            "-A", "20", "com.google.android.youtube.tv"], capture_output=True, text=True)
    if result.returncode != 0:
        print("Failed to retrieve media session info.")
        return None

    output = result.stdout
    if 'state=2' in output and 'actions=53' in output or 'actions=51' in output:
        return True
    return False


# Check if the device is connected
if not check_adb_connection():
    # Ask for the IP address if not connected
    tv_ip = input("Enter TV IP address to connect: ")
    connect_to_device(tv_ip)
else:
    print("Device is already connected.")

while True:
    print("Checking media session actions...")
    if get_media_session_actions():
        print("Correct playback state detected. Proceeding with OCR.")

        print("Capturing screenshot...")
        capture_screenshot()

        print("Cropping image...")
        cropped_path = crop_image(f"{TEMP_DIR}/screen.png", CROP_REGION)

        print("Running OCR...")
        extracted_text = run_easyocr(cropped_path)

        print(f"Extracted Text: {extracted_text}")

        # Check for target text
        if TARGET_TEXT.lower() in extracted_text.lower():
            print(f"Detected '{TARGET_TEXT}' - Pressing Enter")
            subprocess.run(["adb", "shell", "input", "keyevent", "66"])

    else:
        print("Playback state not correct. Waiting for the right state...")

    time.sleep(3)  # Wait before the next loop
