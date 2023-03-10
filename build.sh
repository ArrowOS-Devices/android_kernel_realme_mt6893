#!/bin/bash
function compile()
{
source ~/.bashrc && source ~/.profile
export LC_ALL=C && export USE_CCACHE=1
ccache -M 25G
export ARCH=arm64
export KBUILD_BUILD_HOST=localhost
export KBUILD_BUILD_USER="root"
clangbin=clang/bin/clang
if ! [ -a $clangbin ]; then git clone --depth=1 https://github.com/ArrowOS-Devices/android_prebuilts_clang_host_linux-x86_clang-r437112 clang
fi
gcc64bin=los-4.9-64/bin/aarch64-linux-android-as
if ! [ -a $gcc64bin ]; then git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 los-4.9-64
fi
gcc32bin=los-4.9-32/bin/arm-linux-androideabi-as
if ! [ -a $gcc32bin ]; then git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 los-4.9-32
fi
[ -d "out" ] && rm -rf out || mkdir -p out
rm -rf AnyKernel
make O=out ARCH=arm64 mt6893_defconfig
PATH="${PWD}/clang/bin:${PATH}:${PWD}/los-4.9-32/bin:${PATH}:${PWD}/los-4.9-64/bin:${PATH}" \
make -j$(nproc --all)   O=out \
                        ARCH=arm64 \
                        CC="clang" \
                        CLANG_TRIPLE=aarch64-linux-gnu- \
                        CROSS_COMPILE="${PWD}/los-4.9-64/bin/aarch64-linux-android-" \
                        CROSS_COMPILE_ARM32="${PWD}/los-4.9-32/bin/arm-linux-androideabi-" \
                        LLVM=1 \
                        LD=ld.lld \
                        AS=llvm-as \
                        AR=llvm-ar \
                        NM=llvm-nm \
                        STRIP=llvm-strip \
                        OBJCOPY=llvm-objcopy \
                        OBJDUMP=llvm-objdump \
                        CONFIG_NO_ERROR_ON_MISMATCH=y
}
function zupload()
{
zimage=out/arch/arm64/boot/Image.gz-dtb
if ! [ -a $zimage ];
then
echo  " Failed To Compile Kernel"
else
echo -e " Kernel Compile Successful"
git clone --depth=1 https://github.com/neilchetty/AnyKernel3 AnyKernel
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
cd AnyKernel
zip -r9 OSS-KERNEL-Realme-X7-Max.zip *
curl -sL https://git.io/file-transfer | sh
./transfer wet OSS-KERNEL-Realme-X7-Max.zip
cd ../
fi
}
compile
zupload