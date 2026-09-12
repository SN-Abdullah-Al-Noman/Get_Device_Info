#!/bin/bash

# QT DIR
QT_DIR="$(pwd)"

# Binary
export lpmake="$QT_DIR/bin/lp/lpmake"
export lpunpack="$QT_DIR/bin/lp/lpunpack"
export make_ext4fs="$QT_DIR/bin/ext4/make_ext4fs"
export samloader="$QT_DIR/bin/samloader/samloader"
export make_f2fs="$QT_DIR/bin/f2fs-tools/mkfs.f2fs"
export sload_f2fs="$QT_DIR/bin/f2fs-tools/sload.f2fs"
export omc_decoder="$QT_DIR/bin/java/omc-decoder.jar"
export mkfs_erofs="$QT_DIR/bin/erofs-utils/mkfs.erofs"
export extract_erofs="$QT_DIR/bin/erofs-utils/extract.erofs"
export imgextractor_py="$QT_DIR/bin/py_scripts/imgextractor.py"

chmod +x "$lpmake"
chmod +x "$lpunpack"
chmod +x "$samloader"
chmod +x "$make_f2fs"
chmod +x "$sload_f2fs"
chmod +x "$mkfs_erofs"
chmod +x "$make_ext4fs"
chmod +x "$extract_erofs"

export FIRM_DIR="$QT_DIR/FW"
export OUT_DIR="$QT_DIR/OUT"
export WORK_DIR="$QT_DIR/WORK"
export APKTOOL="$QT_DIR/bin/java/apktool.jar"

source "$(pwd)/scripts/QuantumRom.sh"

EXTRACT_FIRMWARE "$FIRM_DIR"

if compgen -G "$EXTRACTED_FIRM_DIR/system_ext*.img" > /dev/null; then
    STOCK_HAS_SEPARATE_SYSTEM_EXT=TRUE
else
    STOCK_HAS_SEPARATE_SYSTEM_EXT=FALSE
fi

if [ -f "$EXTRACTED_FIRM_DIR/system_a.img" ]; then
    STOCK_HAS_AB_SLOT=TRUE
else
    STOCK_HAS_AB_SLOT=FALSE
fi

# Extract firmware
EXTRACT_SUPER_IMG "$FIRM_DIR"
EXTRACT_FIRMWARE_IMG "$FIRM_DIR" "all"

INSTALL_FRAMEWORK \
    "$APKTOOL" \
    "$FIRM_DIR/system/system/framework/framework-res.apk"

DECOMPILE \
    "$APKTOOL" \
    "$FIRM_DIR/system/system/framework" \
    "$FIRM_DIR/system/system/framework/ssrm.jar" \
    "$WORK_DIR"


GET_SIOP_DVFS_FILE_NAME() {
    echo " "

    if [ "$#" -ne 1 ]; then
        echo -e "Usage: ${FUNCNAME[0]} <EXTRACTED_SSRM_DIRECTORY>"
        return 1
    fi

    local SSRM_DIR="$1"
    local FILE="$SSRM_DIR/smali/com/android/server/ssrm/Feature.smali"

    if [ ! -f "$FILE" ]; then
        echo "- File name not found: $FILE"
        return
    fi

    if FOUND=$(grep -E 'const-string [vp][0-9]+, "dvfs_policy_.*_xx"' "$FILE"); then
        echo "- Found DVFS policy: $FOUND"
        STOCK_DVFS_FILENAME="$FOUND"
    else
        echo "- DVFS policy file name not found."
    fi

    if FOUND=$(grep -E 'const-string [vp][0-9]+, "siop_[^"]*_[^"]*"' "$FILE"); then
        echo "- Found SIOP policy: $FOUND"
        STOCK_SIOP_POLICY_FILENAME="$FOUND"
    else
        echo "- SIOP policy file name not found."
    fi
}


# Get info
GET_SIOP_DVFS_FILE_NAME "$FIRM_DIR"

STOCK_VNDK_VERSION=$(GET_PROP "$EXTRACTED_FIRM_DIR" "vendor" "ro.vendor.build.version.sdk")
STOCK_DEVICE_CPU_ABILIST=$(GET_PROP "$EXTRACTED_FIRM_DIR" "vendor" "ro.vendor.product.cpu.abilist")
SOURCE=$(GET_PROP "$EXTRACTED_FIRM_DIR" "system" "ro.build.PDA")

if compgen -G "$EXTRACTED_FIRM_DIR/system*/system/priv-app/EuiccService" > /dev/null; then
    STOCK_HAS_ESIM_SUPPORT=TRUE
else
    STOCK_HAS_ESIM_SUPPORT=FALSE
fi


# Need to do it manually
USE_ALT_SDHMS_APP=True
STOCK_DEVICE_CHIPSET=
SDHMS_MAX_SUPPORTED_OS_SDK=40

rm -rf "$FIRM_DIR"
mkdir -p "$FIRM_DIR"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

mkdir "$OUT_DIR/$STOCK_DEVICE"
mkdir "$OUT_DIR/$STOCK_DEVICE/product/overlay"
mkdir "$OUT_DIR/$STOCK_DEVICE/system/cameradata"
mkdir "$OUT_DIR/$STOCK_DEVICE/system/etc/init"
mkdir "$OUT_DIR/$STOCK_DEVICE/system/etc/permissions"
mkdir "$OUT_DIR/$STOCK_DEVICE/system/lib"
mkdir "$OUT_DIR/$STOCK_DEVICE/system/lib64"
mkdir "$OUT_DIR/$STOCK_DEVICE/system/media"

cp -r "$FIRM_DIR/product*/overlay/framework-res*auto_generated_rro_product.apk"  "$OUT_DIR/$STOCK_DEVICE/product/overlay"
cp -r "$FIRM_DIR/product*/overlay/SystemUI*auto_generated_rro_product.apk"  "$OUT_DIR/$STOCK_DEVICE/product/overlay"
cp -r "$FIRM_DIR/product*/overlay/TeleService__*__auto_generated_rro_product.apk"  "$OUT_DIR/$STOCK_DEVICE/product/overlay"

cp -r "$FIRM_DIR/system*/system/cameradata/portrait_data"  "$OUT_DIR/$STOCK_DEVICE/system/cameradata"
cp -r "$FIRM_DIR/system*/system/cameradata/singletake"  "$OUT_DIR/$STOCK_DEVICE/system/cameradata"
cp -r "$FIRM_DIR/system*/system/cameradata/aremoji-feature.xml"  "$OUT_DIR/$STOCK_DEVICE/system/cameradata"
cp -r "$FIRM_DIR/system*/system/cameradata/camera-feature.xml"  "$OUT_DIR/$STOCK_DEVICE/system/cameradata"

cp -r "$FIRM_DIR/system*/system/etc/init/rscmgr*.rc"  "$OUT_DIR/$STOCK_DEVICE/system/etc/init"
cp -r "$FIRM_DIR/system*/system/etc/permissions/com.sec.feature.sensorhub_level*.xml"  "$OUT_DIR/$STOCK_DEVICE/system/etc/permissions"

cp -r "$FIRM_DIR/system*/system/lib/lib_SoundBooster_ver*.so"  "$OUT_DIR/$STOCK_DEVICE/system/lib"
cp -r "$FIRM_DIR/system*/system/lib/libsamsungSoundbooster_plus_legacy.so"  "$OUT_DIR/$STOCK_DEVICE/system/lib"

cp -r "$FIRM_DIR/system*/system/lib64/lib_SoundBooster_ver*.so"  "$OUT_DIR/$STOCK_DEVICE/system/lib64"
cp -r "$FIRM_DIR/system*/system/lib64/libsamsungSoundbooster_plus_legacy.so"  "$OUT_DIR/$STOCK_DEVICE/system/lib64"

find "$FIRM_DIR"/system*/system/media -maxdepth 1 -type f -exec cp -f {} "$OUT_DIR/$STOCK_DEVICE/system/media/" \;


# Generate .config
CONFIG_FILE="$QT_DIR/OUT/STOCK_DEVICE/config"

rm -f "$CONFIG_FILE"

cat > "$CONFIG_FILE" <<EOF
STOCK_VNDK_VERSION=$STOCK_VNDK_VERSION
STOCK_DEVICE_CPU_ABILIST=$STOCK_DEVICE_CPU_ABILIST

STOCK_HAS_SEPARATE_SYSTEM_EXT=$STOCK_HAS_SEPARATE_SYSTEM_EXT
STOCK_HAS_AB_SLOT=$STOCK_HAS_AB_SLOT
STOCK_HAS_ESIM_SUPPORT=$STOCK_HAS_ESIM_SUPPORT

STOCK_DVFS_FILENAME=$STOCK_DVFS_FILENAME
STOCK_SIOP_POLICY_FILENAME=$STOCK_SIOP_POLICY_FILENAME

USE_ALT_SDHMS_APP=$USE_ALT_SDHMS_APP
STOCK_DEVICE_CHIPSET=$STOCK_DEVICE_CHIPSET
SDHMS_MAX_SUPPORTED_OS_SDK=$SDHMS_MAX_SUPPORTED_OS_SDK
EOF

echo
echo "=========================================="
echo "             CONFIG GENERATED"
echo "=========================================="
echo "- Config: $CONFIG_FILE"
echo "=========================================="