#!/bin/bash

# === USER CONFIGURATION ===

# Set this to 0 if you don't want to clean before build
clean=1

# Paths to remove before cloning (if clean=1)
paths_to_remove=(
  "vendor/xiaomi"
  "kernel/xiaomi"
  "device/xiaomi"
  "device/xiaomi/sm6150-common"
  "vendor/xiaomi/sm6150-common"
  "hardware/xiaomi"
  "out/target/product/*/*zip"
  "out/target/product/*/*txt"
  "out/target/product/*/boot.img"
  "out/target/product/*/recovery.img"
  "out/target/product/*/super*img"
)

# Repositories to clone: ("path URL branch")
repos=(
    "device/xiaomi/phoenix https://github.com/tillua467/phoenix-dt los-22.2"
    "device/xiaomi/sm6150-common https://github.com/tillua467/sm6150-common los-22.2"
    "kernel/xiaomi/sm6150 https://github.com/tillua467/android_kernel_xiaomi_phoenix los-22.2"
    "vendor/xiaomi/phoenix https://github.com/tillua467/proprietary_vendor_xiaomi_phoenix lineage-22.2"
    "vendor/xiaomi/sm6150-common https://github.com/tillua467/proprietary_vendor_xiaomi_sm6150-common lineage-22.2"
    "hardware/xiaomi https://github.com/tillua467/android_hardware_xiaomi los-22.2"
    "vendor/xiaomi/miuicamera https://gitlab.com/Shripal17/vendor_xiaomi_miuicamera fifteen-leica"
)


# Clean unnecessary files if enabled
if [[ "$clean" -eq 1 ]]; then
  echo "Cleaning unnecessary files..."
  default_clean=(
    "out/target/product/*/*zip"
    "out/target/product/*/*txt"
    "out/target/product/*/boot.img"
    "out/target/product/*/recovery.img"
    "out/target/product/*/super*img"
  )
  for dir in "${default_clean[@]}"; do
    rm -rf $dir
  done
  echo "Global clean complete."
fi

# Remove user-defined paths
echo "Removing user-defined paths..."
for path in "${paths_to_remove[@]}"; do
  echo "Removing $path"
  rm -rf "$path"
done
echo "Cleaning done"

# Init and sync repo
echo "Initializing repo..."
repo init -u https://github.com/AxionAOSP/android.git -b lineage-22.2 --git-lfs || { echo "Repo init failed!"; exit 1; }

echo "Syncing repo..."
repo sync || { echo "Repo sync failed!"; exit 1; }

# Clone repositories
echo "Cloning trees..."
for repo_info in "${repos[@]}"; do
  read -r path url branch <<< "$repo_info"
  echo "Cloning $path from $url [$branch]"
  rm -rf "$path"
  git clone "$url" -b "$branch" "$path" || { echo "Failed to clone $path"; exit 1; }
done

echo "Running the custom syncing script"
/opt/crave/resync.sh

# Export environment variables
echo "Exporting build environment..."
export BUILD_USERNAME=tillua467
export BUILD_HOSTNAME=crave
export TARGET_DISABLE_EPPE=true
export TZ=Asia/Dhaka
export ALLOW_MISSING_DEPENDENCIES=true

# Set up environment
echo "Setting up build environment..."
source build/envsetup.sh || { echo "Envsetup failed"; exit 1; }

# Build the ROM
echo "Starting build..."
brunch phoenix || { echo "Build failed"; exit 1; }

echo "Build complete!"
