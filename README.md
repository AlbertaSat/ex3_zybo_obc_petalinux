# Zybo Test OBC Petalinux Project

This project contains the petalinuxz configuration for the Zybo Test OBC.

## Usage

### Docker

To build the docker image, download the desired petalinux install and place it in this projects root folder then run the following command:

```bash
# Optional build arguments:
# --build-arg PETA_RUN_FILE=<name-of-run-file> (default: "petalinux-v2022.2-10141622-installer.run"
docker build -t zybo_obc_petalinux .
```

To use the docker image, you will need to bind mount the project directory to the `/project` directory in the container. The following command will start the container and open a shell in the project directory:

```bash
docker run -it --rm -v $(pwd):/home/petalinux/project zybo_obc_petalinux
```

### Build Petalinux

Since this project should already be preconfigured and include an exported Vivado bitstream, the following commands should be sufficient to build the project:

```bash
# Sometimes previous configurations can cause issues, so it is recommended to start with a clean configuration
petalinux-build -x mrproper 

# Configure the project
petalinux-config --silentconfig

# Build the project
petalinux-build
```

### Update bitstream (Untested)

If the vivado project gets updated, the bitstream should be exported and configured in the petalinux project.

```bash
petalinux-config --get-hw-description="<path-to-xsa-file>"
```

### Create Boot Image

After building the petalinux project, the boot image can be created using the following command:

```bash
# Create boot stuff
petalinux-package --boot --force --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot

# Create wic image, will be outputted to images/linux/petalinux-sdimage.wic
petalinux-package --wic
```

The wic image can then be used to either create a bootable SD card or emulate the system using QEMU.

### Qemu Emulation

Simply run the following command to emulate the system using QEMU after you have created the boot image:

```bash
# Run QEMU
petalinux-boot --qemu --kernel
```

To quit QEMU `Ctrl + A` then `x`.

### Flash SD Card

To flash the SD card, insert the SD card into the computer and run the following command:

```bash
# Flash SD card, where /dev/sdX is the SD card
# Caution: This command can be dangerous if the wrong device is selected
# please ensure the correct device is selected!!!!
sudo dd if=images/linux/petalinux-sdimage.wic of=/dev/sdX conv=fsync bs=4M status=progress
```

## Notes

### Base Configuration

Initial base configuration for the petalinux project is as follows:

```bash
petalinux-config --get-hw-description="../ex3_zybo_obc_config/zybo_obc_v0.0.1.xsa"
# Set the following options:
# Image Packaging Configuration > Root filesystem type > EXT4 (sdcard)

petalinux-config -c u-boot

petalinux-config -c kernel
# Set the following options:
# Library routines > Default contiguous memory area size > 256

petalinux-config -c rootfs
# Set the following options:
# Filesystem packages -> admin -> sudo
# Filesystem packages -> base -> busybox -> busybox
# Filesystem packages -> base -> shell -> bash
# Filesystem packages -> base -> dnf -> dnf
# Filesystem packages -> console -> network -> wget -> wget
# Filesystem packages -> misc -> packagegroup-core-buildessential -> packagegroup-core-buildessential
# Filesystem packages -> misc -> packagegroup-core-tools-debug -> packagegroup-core-tools-debug
# Petalinux Package Groups -> packagegroup-petalinux -> packagegroup-petalinux
# Petalinux Package Groups -> packagegroup-petalinux-networking-stack -> packagegroup-petalinux-networking-stack
```
