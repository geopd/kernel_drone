#!/bin/bash

set -e

git clone --depth=1 $repo1 -b 4.9-R msm8953 && cd msm8953
export GCC_DIR="/tmp/gcc"
export PATH=$GCC_DIR/gcc64/bin/:$GCC_DIR/gcc32/bin/:/usr/bin:$PATH
export BUILD_START=$(date +"%s")
export CROSS_COMPILE_ARM32=arm-eabi-
export CROSS_COMPILE=aarch64-elf-
export ARCH=arm64
make O=out sakura_defconfig
make O=out -j"$(nproc --all)"
export BUILD_END=$(date +"%s")
export DIFF=$((BUILD_END - BUILD_START))
git clone $repo2
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3 && cd AnyKernel3
export ZIPNAME=Mystique-Kernel-$(TZ=Asia/Kolkata date +%Y%m%d-%H%M).zip
zip -r9 $ZIPNAME ./*
curl -F document=@"$ZIPNAME" "https://api.telegram.org/bot$bottoken/sendDocument" -F chat_id="$chatid" -F "parse_mode=Markdown" -F caption="*✅ Build finished after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds*"
