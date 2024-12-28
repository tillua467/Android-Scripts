# Set up build environment
echo "====== Starting Envsetup ======="
source build/envsetup.sh || { echo "Envsetup failed"; exit 1; }
echo "====== Envsetup Done ======="

# Lunch
echo "====== Lunching.... ========"
lunch lineage_phoenix-ap4a-userdebug || { echo "Lunch command failed"; exit 1; }
echo "===== Lunching done ========"


# Build ROM
echo "===================================="
echo "        Build Evo-X..."
echo "===================================="
m evolution || { echo "Build failed"; exit 1; }
