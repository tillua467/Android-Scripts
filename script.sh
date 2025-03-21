#!/bin/bash

set -euo pipefail

# ======= USER CONFIGURATION =======
manifest_url="https://github.com/AxionAOSP/android.git" # The rom you wanna build
manifest_branch="lineage-22.2" # The branch
device_codename="phoenix"  # Example: miatoll, phoenix, surya
lunch_prefix="lineage"        # Example: aosp, lineage
device_soc="sm6150"        # Example: sm6150
mka_clean="1" # Clean build or not 
variant="userdebug" # user/userdebug/eng

# Define build command
build_code="brunch"

CURRENT_DIR=$(pwd)

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
    "$DT_DIR https://github.com/tillua467/phoenix-dt los-22.1"
    "$CDT_DIR https://github.com/tillua467/sm6150-common los-22.1"
    "$KERNEL_DIR https://github.com/Rom-Build-sys/android_kernel_xiaomi_sm6150 lineage-22.1"
    "$VENDOR_DIR https://github.com/tillua467/proprietary_vendor_xiaomi_phoenix lineage-22.1"
    "$COMMON_VENDOR_DIR https://github.com/aosp-phoenix/proprietary_vendor_xiaomi_sm6150-common lineage-22.1"
    "$HARDWARE_XIAOMI_DIR https://github.com/tillua467/android_hardware_xiaomi los-22.1"
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

# ======= CLONE DEVICE TREES WITH RETRY =======
echo "=============================================="
echo "            Cloning Trees..."
echo "=============================================="

# Function to clone a repo with retry mechanism
clone_repo_with_retry() {
    local repo_path="$1"
    local repo_url="$2"
    local repo_branch="$3"
    local retries=3 # If the clone failed it will Try 3 times to clone it again
    local attempt=0 # Attempts will be Starts from 0 then 1 - 2 - 3 - ..... - n

    while [[ $attempt -lt $retries ]]; do
        echo "Attempting to clone $repo_url -> $repo_path ($repo_branch), attempt $((attempt + 1))"
        if git clone -b "$repo_branch" "$repo_url" "$repo_path"; then
            echo "Successfully cloned into $repo_path"
            return 0
        else
            echo "Failed to clone $repo_url, attempt $((attempt + 1)) of $retries"
            ((attempt++))
        fi
    done

    echo "Failed to clone $repo_url after $retries attempts. Exiting."
    exit 1
}

# Loop through the repo list and clone each repo
for entry in "${repos[@]}"; do
    repo_path=$(echo "$entry" | awk '{print $1}')
    repo_url=$(echo "$entry" | awk '{print $2}')
    repo_branch=$(echo "$entry" | awk '{print $3}')

    clone_repo_with_retry "$repo_path" "$repo_url" "$repo_branch"
done

/opt/crave/resync.sh

# ======= EXPORT ENVIRONMENT VARIABLES =======
echo "======= Exporting Environment Variables ======"
export BUILD_USERNAME=tillua467
export BUILD_HOSTNAME=crave
export TARGET_DISABLE_EPPE=true
export TZ=Asia/Dhaka
export ALLOW_MISSING_DEPENDENCIES=true
echo "======= Export Done ======"

# Check if build/envsetup.sh exists
if [ -f "build/envsetup.sh" ]; then
    echo "Found build/envsetup.sh in the current directory."
else
    # Get the directory where the script is located
    script_dir=$(dirname "$0")
    # Search for envsetup.sh from the script's location
    envsetup_path=$(find "$script_dir" -type f -name "envsetup.sh" | grep "/build/envsetup.sh$" | head -n 1)

    if [ -z "$envsetup_path" ]; then
        echo "envsetup.sh not found in the expected locations. Exiting."
        exit 1
    fi
    echo "Found envsetup.sh at: $envsetup_path"
    # Move to the directory where envsetup.sh is located (this should be inside 'build/')
    cd "$(dirname "$envsetup_path")/.."
fi

echo "Now in the root directory of the build environment."

# ======= BUILD ENVIRONMENT =======
echo "====== Starting Envsetup ======="
source build/envsetup.sh || { echo "Envsetup failed"; exit 1; }
echo "====== Envsetup Done ======="


# Clean build if the user set it
if [[ "$mka_clean" == "1" || "$mka_clean" == "true" || "$mka_clean" == "yes" || "$mka_clean" == "y" ]]; then
    mka clean
fi

# Setting up build command for brunch or other commands
if [[ "$build_code" == "brunch"* ]]; then
    echo "Detected brunch as the build command, no need to lunch/breakfast"
    echo "Setting the build to brunch -> brunch ${device_codename} ${variant}"
    build_code="brunch ${device_codename} ${variant}"  
else
    LUNCH_OPTIONS=(
        "lunch ${lunch_prefix}_${device_codename}-ap4a-${variant}"
        "lunch ${lunch_prefix}_${device_codename}-ap3a-${variant}"
        "lunch ${lunch_prefix}_${device_codename}-ap2a-${variant}"
        "lunch ${lunch_prefix}_${device_codename}-${variant}"
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
        echo "All lunch commands failed, trying: breakfast ${lunch_prefix}_${device_codename}-${variant}"
        breakfast ${lunch_prefix}_${device_codename}-${variant} || { echo "Breakfast failed. Exiting."; exit 1; }
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
        error_log=$(find out/ -name "error.log")

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
