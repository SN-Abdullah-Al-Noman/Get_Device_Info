#!/bin/bash

source "$(pwd)/scripts/QuantumRom.sh"

EXTRACTED_FIRM_DIR="$FIRM_DIR/$STOCK_DEVICE"

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

# Extract firmware img
EXTRACT_FIRMWARE_IMG "$EXTRACTED_FIRM_DIR" "all"

INSTALL_FRAMEWORK "$APKTOOL" "$EXTRACTED_FIRM_DIR/system/system/framework/framework-res.apk"
DECOMPILE "$APKTOOL" "$EXTRACTED_FIRM_DIR/system/system/framework" "$EXTRACTED_FIRM_DIR/system/system/framework/ssrm.jar" "$WORK_DIR"


GET_SIOP_DVFS_FILE_NAME() {
    echo " "

    if [ "$#" -ne 1 ]; then
        echo -e "Usage: ${FUNCNAME[0]} <EXTRACTED_SSRM_DIRECTORY>"
        return 1
    fi

    local EXTRACTED_FIRM_DIR="$1"
    local FILE="$EXTRACTED_FIRM_DIR/smali/com/android/server/ssrm/Feature.smali"

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
GET_SIOP_DVFS_FILE_NAME "$EXTRACTED_FIRM_DIR"

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

mkdir -p "$OUT_DIR/$STOCK_DEVICE"
mkdir -p "$OUT_DIR/$STOCK_DEVICE/product/overlay"
mkdir -p "$OUT_DIR/$STOCK_DEVICE/system/cameradata"
mkdir -p "$OUT_DIR/$STOCK_DEVICE/system/etc/init"
mkdir -p "$OUT_DIR/$STOCK_DEVICE/system/etc/permissions"
mkdir -p "$OUT_DIR/$STOCK_DEVICE/system/lib"
mkdir -p "$OUT_DIR/$STOCK_DEVICE/system/lib64"
mkdir -p "$OUT_DIR/$STOCK_DEVICE/system/media"

cp -r "$EXTRACTED_FIRM_DIR/product*/overlay/framework-res*auto_generated_rro_product.apk"  "$OUT_DIR/$STOCK_DEVICE/product/overlay"
cp -r "$EXTRACTED_FIRM_DIR/product*/overlay/SystemUI*auto_generated_rro_product.apk"  "$OUT_DIR/$STOCK_DEVICE/product/overlay"
cp -r "$EXTRACTED_FIRM_DIR/product*/overlay/TeleService__*__auto_generated_rro_product.apk"  "$OUT_DIR/$STOCK_DEVICE/product/overlay"

cp -r "$EXTRACTED_FIRM_DIR/system*/system/cameradata/portrait_data"  "$OUT_DIR/$STOCK_DEVICE/system/cameradata"
cp -r "$EXTRACTED_FIRM_DIR/system*/system/cameradata/singletake"  "$OUT_DIR/$STOCK_DEVICE/system/cameradata"
cp -r "$EXTRACTED_FIRM_DIR/system*/system/cameradata/aremoji-feature.xml"  "$OUT_DIR/$STOCK_DEVICE/system/cameradata"
cp -r "$EXTRACTED_FIRM_DIR/system*/system/cameradata/camera-feature.xml"  "$OUT_DIR/$STOCK_DEVICE/system/cameradata"

cp -r "$EXTRACTED_FIRM_DIR/system*/system/etc/init/rscmgr*.rc"  "$OUT_DIR/$STOCK_DEVICE/system/etc/init"
cp -r "$EXTRACTED_FIRM_DIR/system*/system/etc/permissions/com.sec.feature.sensorhub_level*.xml"  "$OUT_DIR/$STOCK_DEVICE/system/etc/permissions"

cp -r "$EXTRACTED_FIRM_DIR/system*/system/lib/lib_SoundBooster_ver*.so"  "$OUT_DIR/$STOCK_DEVICE/system/lib"
cp -r "$EXTRACTED_FIRM_DIR/system*/system/lib/libsamsungSoundbooster_plus_legacy.so"  "$OUT_DIR/$STOCK_DEVICE/system/lib"

cp -r "$EXTRACTED_FIRM_DIR/system*/system/lib64/lib_SoundBooster_ver*.so"  "$OUT_DIR/$STOCK_DEVICE/system/lib64"
cp -r "$EXTRACTED_FIRM_DIR/system*/system/lib64/libsamsungSoundbooster_plus_legacy.so"  "$OUT_DIR/$STOCK_DEVICE/system/lib64"

find "$EXTRACTED_FIRM_DIR"/system*/system/media -maxdepth 1 -type f -exec cp -f {} "$OUT_DIR/$STOCK_DEVICE/system/media/" \;


# Generate .config
CONFIG_FILE="$QT_DIR/OUT/$STOCK_DEVICE/config"

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
