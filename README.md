# Android-Scripts

This project contains various scripts for automatic Android ROM development.

## Description

Android-Scripts provides scripts and tools to automate and simplify tasks in the Android ROM building process.

### What it Does:
- Clone the repositories
- Build the ROM
- Upload it to Go-file and provide a download link

## Warning

This was made for Crave or a similar build environment. If you want to use this locally, you will need to adapt it accordingly.

## Installation

1. **Fork and Clone**  
   Fork this repository and clone it to your local machine.

2. **Edit `script.sh`**  
   Open the `script.sh` file. At the beginning, you'll find the following variables:
   - `manifest_url`
   - `manifest_branch`
   - `device_codename`
   - `lunch_prefix`
   - `device_soc`
   - `build_dir`
   - `mka_clean`
   - `variant`

   Fill them with the appropriate information, like this:

   ```
   manifest_url="https://github.com/LineageOS/android.git"
   manifest_branch="lineage-22.1"
   device_codename="phoenix"
   lunch_prefix="lineage"
   device_soc="sm6150"
   build_dir="tmp/src/android"
   mka_clean="1"
   variant="userdebug"
   ```

3. **Additional Variables**  
   After that, you'll find another set of variables:

   ```
   build_code="brunch"
   # ======= USER-DEFINED DIRECTORY STRUCTURE =======
   DT_DIR=""
   CDT_DIR=""
   KERNEL_DIR=""
   VENDOR_DIR=""
   COMMON_VENDOR_DIR=""
   HARDWARE_XIAOMI_DIR=""
   MIUICAMERA_DIR=""

   # ======= Define Trees and Branches Here =======
   repos=(
       "$DT_DIR"
       "$CDT_DIR"
       "$KERNEL_DIR"
       "$VENDOR_DIR"
       "$COMMON_VENDOR_DIR"
       "$HARDWARE_XIAOMI_DIR"
       "$MIUICAMERA_DIR"
   )
   ```

   Fill these variables with the following values:

   ```
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
       "$HARDWARE_XIAOMI_DIR https://github.com/tillua467/android_hardware_xiaomi lineage-22.1"
       "$MIUICAMERA_DIR https://gitlab.com/Shripal17/vendor_xiaomi_miuicamera fifteen-leica"
   )
   ```

4. **Adding More Repositories** 
   If you want to clone additional repositories, define the directory name first, like this:

   ```bash
   Example_DIR="Your_Directory"
   ```

   Then add it to the `repos` array in this format:

   ```bash
   "$Example_DIR <Link> <branch>"
   ```

5. **Run the Build Script** 
   After setting everything up, you can start the build process by running the following command:

   ```bash
   crave run --no-patch -- "curl https://raw.githubusercontent.com/tillua467/Android-Scripts/refs/heads/main/script.sh | bash"
   ```

   Make sure to link to the raw file from GitHub.

---

Happy Building!
