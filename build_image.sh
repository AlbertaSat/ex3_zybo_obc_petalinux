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
