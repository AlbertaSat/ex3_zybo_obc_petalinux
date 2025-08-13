# Script automate the petalinux image build process

# Add optional project location argument
PROJECT_LOCATION=${1:-"/home/petalinux/project"}

cd $PROJECT_LOCATION

echo "Using petalinux project location: $PROJECT_LOCATION"

# Build the petalinux project
# echo "Cleaning project"
# petalinux-build -x mrproper
echo "Configuring project"
petalinux-config --silentconfig
echo "Building project"
petalinux-build

# Create the image
echo "Packaging boot image"
petalinux-package --boot --force --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot
echo "Packaging wic image"
petalinux-package --wic

# Get the current branch name and hash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
HASH=$(git rev-parse --short HEAD)

# Check if the working directory is dirty
if [ -n "$(git status --porcelain)" ]; then
    DIRTY="_dirty"
else
    DIRTY=""
fi

# Create the tar file
TAR_NAME="images/zybo_obc_${BRANCH}_${HASH}${DIRTY}.tar.gz"
echo "Creating tar file: $TAR_NAME"
tar -czvf "$TAR_NAME" -C images/linux petalinux-sdimage.wic
