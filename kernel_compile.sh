#!/bin/bash

set -e

export COMPILER=EVA-GCC

git clone --depth=1 $repo1 -b 4.9-R msm8953 && cd msm8953

export BUILD_START=$(date +"%s")
export ARCH=arm64
make O=out sakura_defconfig

eva_gcc() {
  # docker has gcc repos cloned to gcc directory.
  export GCC_DIR="/tmp/gcc"
  export PATH=$GCC_DIR/gcc64/bin/:$GCC_DIR/gcc32/bin/:/usr/bin:$PATH
  build_commands() {
          make -j"$(nproc --all)" \
          O=out \
          CROSS_COMPILE=aarch64-elf- \
          CROSS_COMPILE_ARM32=arm-eabi-
  }
  build_commands
}

proton_clang() {
  # docker has proton clang repo cloned to clang directory.
  export CLANG_DIR="/tmp/proton"
  export PATH=$CLANG_DIR/bin/:/usr/bin:$PATH
  build_commands() {
          make -j"$(nproc --all)" \
          O=out \
          CROSS_COMPILE=aarch64-linux-gnu- \
          CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
          CC=clang \
          AR=llvm-ar \
          OBJDUMP=llvm-objdump \
          STRIP=llvm-strip
  }
  build_commands
}

case "${COMPILER}" in
 "EVA-GCC") eva_gcc
    ;;
 "PROTON-CLANG") proton_clang
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac

export BUILD_END=$(date +"%s")
export DIFF=$((BUILD_END - BUILD_START))

git clone $repo2
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3 && cd AnyKernel3

export ZIPNAME=Mystique-Kernel-$(TZ=Asia/Kolkata date +%Y%m%d-%H%M).zip
zip -r9 $ZIPNAME ./*

curl -F document=@"$ZIPNAME" "https://api.telegram.org/bot$bottoken/sendDocument" -F chat_id="$chatid" -F "parse_mode=Markdown" -F caption="*✅ Build finished after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds*"
