# Zybo Test OBC Petalinux Project

This project contains the petalinuxz configuration for the Zybo Test OBC.

## Usage

### Docker

The main usecase for the docker image if for the CI/CD pipeline, however, it can also be used to build the petalinux project locally if you do not want to pollute your system with the petalinux tools and dependencies.

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
# Sometimes previous configurations can cause issues due to absolute pathing, so it is recommended to start with a clean configuration
# Subsequent builds can skip this step
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

Simply run the following command to emulate the system using QEMU after you have created the image:

```bash
# Run QEMU
petalinux-boot --qemu --kernel
```

To quit QEMU `Ctrl + A` then `x`.

### Flash SD Card

To flash a blank SD card, insert the SD card into the computer and run the following command:

```bash
# Flash SD card, where /dev/sdX is the SD card
# Caution: This command can be dangerous if the wrong device is selected
# please ensure the correct device is selected!!!!
sudo dd if=images/linux/petalinux-sdimage.wic of=/dev/sdX conv=fsync bs=4M status=progress oflag=direct

# conv=fsync: Flush the write cache after each block
# bs=4M: Write in 4MB blocks
# status=progress: Show progress
# oflag=direct: Write directly to the device
# note that oflag is a GNU extension, not found on MacOS/BSD
```

This process of flashing the SD card will end up with empty unpartitioned space on the SD card. The root filesystem partition can be resized to fill the entire SD card using the following commands:

```bash
# Resize partition
sudo parted /dev/sdX resizepart 2 100%
sudo e2fsck -f /dev/sdX2
sudo resize2fs /dev/sdX2
```

## Zybo Setup

Ensure the Right side jumper is set to SD, this will allow the Zybo to boot from the SD card. Also ensure that the left jumper by the power switch is set to WALL so that the zybo is powered by the wall adapter and not the USB.

After the SD card is flashed, insert it into the Zybo and power it on. The Zybo should boot into the petalinux image.

To access the Zybo, connect the USB UART to the Zybo and open a serial terminal with a baud rate of 115200. The Zybo should output the boot process and eventually a login prompt.

A simple process to connect to the Zybo using `screen`:

```bash
# To find the device, run 
dmesg | grep ttyUSB
# after connecting the USB UART to the computer
# The most recent messages containing 'FTDI' should show the device name for the Zybo
# Usually the console is outputted on the second device (e.g. ttyUSB1 if there is both a ttyUSB0 and ttyUSB1)
# Then just run
screen /dev/ttyUSBX 115200
```


## CICD (WIP)

The project includes a GitHub Actions workflow that will build the petalinux project and create a wic image. The workflow can be triggered by creating a new tag with the format `v*.*.*`.

As petalinux is a somewhat under export control restrictions, the workflow is set to run on a self-hosted runner using a locally built verion of the included Dockerfile. All built zybo images will also be stored on the runners machine.

To ensure that the runner is secure, a repository should be private. If the repository is public, the setting `Actions -> General -> Fork pull request workflows from outside collaborators` must be set to `Require approval for all outside collaborators` so that the runner is not exposed to malicious code by unknown collaborators through PR'sc.

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
