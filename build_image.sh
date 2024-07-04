# Script automate the petalinux image build process

# Add optional project location argument
PROJECT_LOCATION=${1:-"/home/petalinux/project"}

echo "Building petalinux project at $PROJECT_LOCATION"

# Build the petalinux project
petalinux-build -p $PROJECT_LOCATION -x mrproper
petalinux-config -p $PROJECT_LOCATION --silentconfig
petalinux-build -p $PROJECT_LOCATION

# Create the image
petalinux-package -p $PROJECT_LOCATION --boot --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system_wrapper.bit --u-boot --force
petalinux-package -p $PROJECT_LOCATION --wic
