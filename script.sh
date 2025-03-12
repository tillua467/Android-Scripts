#!/bin/bash
set -euo pipefail

# crave run --no-patch -- "curl https://raw.githubusercontent.com/tillua467/Android-Scripts/refs/heads/main/script.sh | bash"

# ======= USER CONFIGURATION =======
manifest_url="https://github.com/PixelOS-AOSP/manifest.git" # The rom you wanna build
manifest_branch="fifteen" # The branch
device_codename="phoenix"  # Example: miatoll, phoenix, surya
lunch_prefix="aosp"        # Example: aosp, lineage
device_soc="sm6150"        # Example: sm6150
build_dir="tmp/src/android" # Where the source is cloned and the path should start from the root dir
mka_clean="1" # Clean build or not 

# Define build command
build_code="mka bacon -j$(nproc)"

# ======= USER-DEFINED DIRECTORY STRUCTURE =======
DT_DIR="device/xiaomi/${device_codename}" 
CDT_DIR="device/xiaomi/${device_soc}-common"
KERNEL_DIR="kernel/xiaomi/${device_soc}"
VENDOR_DIR="vendor/xiaomi/${device_codename}"
COMMON_VENDOR_DIR="vendor/xiaomi/${device_soc}-common"
HARDWARE_XIAOMI_DIR="hardware/xiaomi"
MIUICAMERA_DIR="vendor/xiaomi/miuicamera"

# ======= Define Trees and Branches Here =======
repos=(
    "$DT_DIR https://github.com/tillua467/phoenix-dt pos-15"
    "$CDT_DIR https://github.com/tillua467/sm6150-common pos-15"
    "$KERNEL_DIR https://github.com/Rom-Build-sys/android_kernel_xiaomi_sm6150 lineage-22.1"
    "$VENDOR_DIR https://github.com/tillua467/proprietary_vendor_xiaomi_phoenix los-22.1"
    "$COMMON_VENDOR_DIR https://github.com/aosp-phoenix/proprietary_vendor_xiaomi_sm6150-common lineage-22.1"
    "$HARDWARE_XIAOMI_DIR https://github.com/tillua467/android_hardware_xiaomi lineage-22.1"
    "$MIUICAMERA_DIR https://gitlab.com/Shripal17/vendor_xiaomi_miuicamera fifteen-leica"
)

# ======= CLEANUP =======
echo "===================================="
echo "     Removing Unnecessary Files"
echo "===================================="

dirs_to_remove=(
    "$DT_DIR"
    "$CDT_DIR"
    "$KERNEL_DIR"
    "$VENDOR_DIR"
    "$COMMON_VENDOR_DIR"
    "$HARDWARE_XIAOMI_DIR"
    "$MIUICAMERA_DIR"
)

files_to_remove=(
    "out/target/product/${device_codename}/*.zip"
    "out/target/product/${device_codename}/*.txt"
    "out/target/product/${device_codename}/boot.img"
    "out/target/product/${device_codename}/recovery.img"
    "out/target/product/${device_codename}/super*img"
)

for dir in "${dirs_to_remove[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir" && echo "Removed directory: $dir"
    fi
done

for file in "${files_to_remove[@]}"; do
    rm -f $file && echo "Removed file(s): $file"
done

echo "===================================="
echo "          Cleanup Done"
echo "===================================="

# ======= INIT & SYNC =======
echo "=============================================="
echo "         Cloning Manifest..."
echo "=============================================="
if ! repo init -u "$manifest_url" -b "$manifest_branch" --git-lfs; then
    echo "Repo initialization failed. Exiting."
    exit 1
fi

echo "Manifest cloned successfully."

if ! /opt/crave/resync.sh || ! repo sync; then
    echo "Repo sync failed. Exiting."
    exit 1
fi

echo "=============================================="
echo "             Sync Success"
echo "=============================================="

# ======= CLONE DEVICE TREES =======
echo "=============================================="
echo "            Cloning Trees..."
echo "=============================================="

for entry in "${repos[@]}"; do
    repo_path=$(echo "$entry" | awk '{print $1}')
    repo_url=$(echo "$entry" | awk '{print $2}')
    repo_branch=$(echo "$entry" | awk '{print $3}')

    echo "Cloning $repo_url -> $repo_path ($repo_branch)"
    git clone -b "$repo_branch" "$repo_url" "$repo_path" || { echo "Failed to clone $repo_url"; exit 1; }
    if [ -d "$repo_path" ]; then
        echo "Successfully cloned into $repo_path"
    fi
done

/opt/crave/resync.sh # sync the trees

# Any extra stuff
rm -rf hardware/xiaomi/megvii

# Make Sure it's on the right Directory
cd /
cd "${build_dir}"

# ======= EXPORT ENVIRONMENT VARIABLES =======
echo "======= Exporting Environment Variables ======"
export BUILD_USERNAME=tillua467
export BUILD_HOSTNAME=crave
export TARGET_DISABLE_EPPE=true
export TZ=Asia/Dhaka
export ALLOW_MISSING_DEPENDENCIES=true
echo "======= Export Done ======"

# ======= BUILD ENVIRONMENT =======
echo "====== Starting Envsetup ======="
source build/envsetup.sh || { echo "Envsetup failed"; exit 1; }
echo "====== Envsetup Done ======="

if [[ "$mka_clean" == "1" || "$mka_clean" == "true" || "$mka_clean" == "yes" || "$mka_clean" == "y" ]]; then
    mka clean
fi

if [[ "$build_code" == "brunch"* ]]; then
    echo "Detected brunch as the build command, skipping lunch..."
else
    LUNCH_OPTIONS=(
        "lunch ${lunch_prefix}_${device_codename}-ap4a-userdebug"
        "lunch ${lunch_prefix}_${device_codename}-ap3a-userdebug"
        "lunch ${lunch_prefix}_${device_codename}-ap2a-userdebug"
        "lunch ${lunch_prefix}_${device_codename}-userdebug"
    )

    success=false
    for CMD in "${LUNCH_OPTIONS[@]}"; do
        echo "Trying: $CMD"
        if eval "$CMD"; then
            success=true
            break
        fi
    done

    # If all lunch commands fail, try breakfast
    if [ "$success" = false ]; then
        echo "All lunch commands failed, trying: breakfast ${lunch_prefix}_${device_codename}-userdebug"
        breakfast ${lunch_prefix}_${device_codename}-userdebug || { echo "Breakfast failed. Exiting."; exit 1; }
        success=true
    fi

    if [ "$success" = false ]; then
        echo "All attempts to select a build target failed, exiting."
        exit 1
    fi
fi


# ======= BUILD THE ROM =======
if [ "$success" = true ]; then
    echo "Lunch/Breakfast successful, running build command: $build_code"
    $build_code
    BUILD_STATUS=$?
    if [ $BUILD_STATUS -eq 0 ]; then
        echo "Build completed successfully!"
    else
        echo "Build failed! Fetching error.log..."
        error_log=$(find out/target/product/${device_codename} -name "error.log")

        if [ -f "$error_log" ]; then
            echo "Uploading error.log to Gofile..."
            response=$(curl -s -X POST -F "file=@$error_log" https://api.gofile.io/uploadFile)
            download_link=$(echo "$response" | jq -r '.data.downloadPage')

            if [ "$download_link" != "null" ]; then
                echo "error.log uploaded successfully! Download it here: $download_link"
            else
                echo "Error uploading file. Response: $response"
            fi
        else
            echo "error.log not found!"
        fi
        exit 1
    fi
else
    echo "All attempts to select a build target failed, exiting."
    exit 1
fi

# ======= UPLOAD TO GOFILE.IO (only if build succeeded) =======
echo "=============================================="
echo "      Searching for the built ROM..."
echo "=============================================="

# Use `ls -t` to get the latest built ROM file
ROM_FILE=$(ls -t out/target/product/${device_codename}/*.zip | head -n 1)

if [[ -z "$ROM_FILE" ]]; then
    echo "Error: No ROM zip file found in out/target/product/${device_codename}"
    exit 1
fi

echo "Found ROM: $ROM_FILE"

echo "=============================================="
echo "     Uploading ROM to Gofile.io..."
echo "=============================================="

UPLOAD_RESPONSE=$(curl -s -F "file=@$ROM_FILE" "https://store7.gofile.io/uploadFile")
DOWNLOAD_LINK=$(echo "$UPLOAD_RESPONSE" | jq -r '.data.downloadPage')

# Print the response to debug if necessary
echo "UPLOAD_RESPONSE: $UPLOAD_RESPONSE"

if [[ -n "$DOWNLOAD_LINK" && "$DOWNLOAD_LINK" != "null" ]]; then
    echo "=============================================="
    echo "        Upload Successful!"
    echo "Download Link: $DOWNLOAD_LINK"
    echo "=============================================="
else
    echo "Error: Upload failed!"
    exit 1
fi
