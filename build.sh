#Kernel build script 

# variables :>
wd=$(pwd)
zipper=$wd/AnyKernel3
out=$wd/out
kernel_name='Hadikernel'
commit=$(git rev-parse --short=5 HEAD)
refreshrate='75hz'
zipname=$(echo ${kernel_name}-${commit}-${refreshrate}.zip)

# Export proton-clang directory
export PATH="/home/hakidoto/toolchains/proton-clang/bin:$PATH"

# Clean out directory
make clean && make mrproper

# Check existence of mkdtboimg.py

if [ -f scripts/ufdt/libufdt/utils/src/mkdtboimg.py ]; then
    echo "mkdtboimg exists, skipping..."
else
    echo "mkdtboimg doesn't exists, running submodule update..."
    git submodule update --init --recursive
fi

# make .defconfig file
make O=out ARCH=arm64 andromeda_defconfig

# Start build

if ! make -j$(nproc --all) O=$out \
                      ARCH=arm64 \
                      CC=clang \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi | tee kernel.log; then
    err "Failed building kernel, check log for detailed explanation"
    exit 1
fi

# Removing previous zips
find  . -name 'Hadikernel*' -exec rm {} \;

#Copy files to AnyKernel3 folder

if [[ -f "$zipper"/"Image.gz-dtb" && "$zipper"/"dtbo.img" ]]; then
    echo "kernel images exists, deleting..."
    rm  "$zipper"/"Image.gz-dtb" &&  rm "$zipper"/"dtbo.img"
    copy_output
else
    copy_output
fi

# zipping files

cd "$zipper" || exit 2
zip -r9 "$zipname" . || exit 2
explorer.exe .
exit 0


# copy function

copy_output () {
    cp out/arch/arm64/boot/"Image.gz-dtb" "$zipper"/"Image.gz-dtb"
    cp out/arch/arm64/boot/"dtbo.img" "$zipper"/"dtbo.img"
}