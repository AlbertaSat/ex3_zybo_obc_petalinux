#!/bin/bash -e
# Script automate the petalinux image build process
# Default project location
PROJECT_LOCATION="/home/petalinux/project"
SKIP_BUILD=false
WKS_32="${WKS_32:-ex3_32gb.wks}"
WKS_64="${WKS_64:-ex3_64gb.wks}"
WIC_OUTDIR="images/linux"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --skip-build)
            SKIP_BUILD=true
            ;;
        *)
            PROJECT_LOCATION="$arg"
            ;;
    esac
done

cd $PROJECT_LOCATION

echo "Using petalinux project location: $PROJECT_LOCATION"

if [ "$SKIP_BUILD" = false ]; then
    # Build the petalinux project
    # echo "Cleaning project"
    # petalinux-build -x mrproper
    echo "Configuring project"
    petalinux-config --silentconfig
    echo "Building project"
    petalinux-build
else
    echo "Skipping build process as --skip-build flag is present"
fi

# Create the image
echo "Packaging boot image"
petalinux-package --boot --force --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot

# Get the current branch name and hash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
HASH=$(git rev-parse --short HEAD)

# Check if the working directory is dirty
if [ -n "$(git status --porcelain)" ]; then
    DIRTY="_dirty"
else
    DIRTY=""
fi

package_wic() {
    local label="$1"
    local wks="$2"
    local wic_name="petalinux-sdimage-${label}.wic"

    if [ ! -f "$wks" ]; then
        echo "Missing WKS file: $wks"
        exit 1
    fi

    echo "Packaging wic image (${label}) using $wks"
    petalinux-package --wic --wks "$wks"
    mv "${WIC_OUTDIR}/petalinux-sdimage.wic" "${WIC_OUTDIR}/${wic_name}"

    local tar_name="images/zybo_obc_${label}_${BRANCH}_${HASH}${DIRTY}.tar.gz"
    echo "Creating tar file: $tar_name"
    tar -czvf "$tar_name" -C "$WIC_OUTDIR" "$wic_name"
}

package_wic "32gb" "$WKS_32"
package_wic "64gb" "$WKS_64"
