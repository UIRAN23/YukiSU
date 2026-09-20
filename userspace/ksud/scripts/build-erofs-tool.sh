#!/usr/bin/env bash
set -euo pipefail
ROOT=$(pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"
export CC="$TOOLCHAIN/${1:?compiler target required}-clang" AR="$TOOLCHAIN/llvm-ar" RANLIB="$TOOLCHAIN/llvm-ranlib" STRIP="$TOOLCHAIN/llvm-strip"
git clone --quiet https://kernel.googlesource.com/pub/scm/linux/kernel/git/xiang/erofs-utils "$WORK/source"
git -C "$WORK/source" checkout --quiet 51b5939b5f783221310d25146e6a2019ba8129b6
mkdir -p "$ROOT/erofs-source" "$ROOT/userspace/ksud/assets"
git -C "$WORK/source" archive --format=tar.gz --output="$ROOT/erofs-source/erofs-utils-source.tar.gz" HEAD
cp "$WORK/source/COPYING" "$ROOT/erofs-source/COPYING"
cd "$WORK/source"
./autogen.sh
./configure --host=aarch64-linux-android --without-uuid --without-selinux --disable-fuse --disable-lz4 --disable-lzma --without-libzstd --without-zlib --without-libdeflate --without-qpl --without-xxhash
make -j2
"$STRIP" mkfs/mkfs.erofs fsck/fsck.erofs
cp mkfs/mkfs.erofs fsck/fsck.erofs "$ROOT/userspace/ksud/assets/"
