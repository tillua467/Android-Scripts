# Android-Scripts

This project contains various scripts for automatic Android ROM development.

## Description

Android-Scripts provides scripts and tools to automate and simplify tasks in the Android ROM building process.

### What it Does:
- Clone the repositories
- Build the ROM
## ⚠️ Warning

This was made for Crave or a similar build environment. If you want to use this locally, you will need to adapt it accordingly.

## Installation

1. **Fork and Clone**
    Fork this repository and clone it to your local machine.

2. **Adapt accordingly**
    1. Add what foldersle to remove
        ```
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
        ```
    2. Add what needs to clone
        ```
        repos=(
            "device/xiaomi/phoenix https://github.com/tillua467/phoenix-dt los-22.1"
            "device/xiaomi/sm6150-common https://github.com/tillua467/sm6150-common los-22.1"
            "kernel/xiaomi/sm6150 https://github.com/tillua467/android_kernel_xiaomi_sm6150 los-22.1"
            "vendor/xiaomi/phoenix https://github.com/aosp-phoenix/proprietary_vendor_xiaomi_phoenix los-22.1"
            "vendor/xiaomi/sm6150-common https://github.com/aosp-phoenix/proprietary_vendor_xiaomi_sm6150-common los-22.1"
            "hardware/xiaomi https://github.com/LineageOS/android_hardware_xiaomi main"
            "vendor/xiaomi/miuicamera https://gitlab.com/Shripal17/vendor_xiaomi_miuicamera main"
        )
        ```
    3. Set what rom to build by adding their manifest and syncing code
        ```
            echo "Initializing repo..."
            repo init -u https://github.com/AxionAOSP/android.git -b lineage-22.2 --git-lfs || { echo "Repo init failed!"; exit 1; }
            echo "Syncing repo..."
            repo sync || { echo "Repo sync failed!"; exit 1; }
        ```
    4. Set Environment Variables
        ```
            # Export environment variables
            echo "Exporting build environment..."
            export BUILD_USERNAME=tillua467
            export BUILD_HOSTNAME=crave
            export TARGET_DISABLE_EPPE=true
            export TZ=Asia/Dhaka
            export ALLOW_MISSING_DEPENDENCIES=true
        ```
    5. Lastly set the build code-
        ```
            brunch phoenix || { echo "Build failed"; exit 1; }
        ```
    I am using brunch here so i don't need to add lunch if you need lunch u can add that by yourself

3. **Run the Build Script**
   After setting everything up, you can start the build process by running the following command:

   ```bash
    crave run --no-patch -- "curl https://raw.githubusercontent.com/tillua467/Android-Scripts/refs/heads/main/build.sh | bash"
   ```

   Make sure to link to the raw file from your forked repo.

---

Happy Building!