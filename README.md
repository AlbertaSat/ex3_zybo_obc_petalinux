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

### Method 1: Full image using Balena Etcher (Recommended)

One of the most popular tools for flashing SD cards is [Balena Etcher](https://www.balena.io/etcher/). It is easy to use, multi-platform, post-flashing validation, and can make clones of SD cards.

Note: There seems to be some issues with the current version of Balena Etcher not spawning its utility program correctly (see [this issue](https://github.com/balena-io/etcher/issues/4150)), it is recommended to use an version 1.18.11 from their [github releases page](https://github.com/balena-io/etcher/releases/tag/v1.18.11).

1. Download and install Balena Etcher
2. Open Balena Etcher
3. Click `Flash from file` and select the wic image
4. Click `Select target` and select the SD card you want to flash
5. Click `Flash!` and wait for the process to complete
6. Once the process is done, you should use the following command to resize the root filesystem partition to fill the entire SD card:

    ```bash
    # This should ideally be a script ran in u-boot on first boot
    # Resize partition
    sudo parted /dev/sdX resizepart 2 100%
    sudo e2fsck -f /dev/sdX2
    sudo resize2fs /dev/sdX2
    ```

#### Method 2: Full image using dd

To flash a blank SD card, insert the SD card into the computer and run the following command:

Note: It is recommended to format the SD card before flashing to ensure that the card is empty with no partitions.

```bash
# Flash SD card, where /dev/sdX is the SD card
# Caution: This command can be dangerous if the wrong device is selected
# potentially overwriting important data and corrupting your system
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
# This should ideally be a script ran in u-boot on first boot
# Resize partition
sudo parted /dev/sdX resizepart 2 100%
sudo e2fsck -f /dev/sdX2
sudo resize2fs /dev/sdX2
```

#### Method 3: Individual partitions (Not recommended)

If you already have a bootable SD card that is partitioned correctly, you can copy the individual partitions files to the SD card.

First mount the boot partition and copy the following files from `images/linux/` to the boot partition:

- BOOT.BIN
- boot.scr
- uImage

Then use the following command to copy the root fs tarball onto the root partition:

```bash
sudo dd if=images/linux/rootfs.tar.gz of=/dev/sdX2 conv=fsync bs=4M status=progress oflag=direct
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
# Filesystem packages -> base -> e2fsprogs -> e2fsprogs
# Filesystem packages -> base -> e2fsprogs -> e2fsprogs-resize2fs
# Filesystem packages -> base -> e2fsprogs -> e2fsprogs-e2fsck
# Filesystem packages -> base -> i2ctools -> i2ctools
# Filesystem packages -> base -> i2ctools -> i2ctools-dev
# Filesystem packages -> base -> tzdata -> tzdata
# Filesystem packages -> base -> tar -> tar
# Filesystem packages -> base -> xz -> xz
# Filesystem packages -> base -> shell -> bash
# Filesystem packages -> base -> dnf -> dnf
# Filesystem packages -> benchmark -> tests -> dhrystone -> dhrystone
# Filesystem packages -> benchmark -> tests -> linpack -> linpack
# Filesystem packages -> benchmark -> tests -> whetstone -> whetstone
# Filesystem packages -> console -> network -> wget -> wget
# Filesystem packages -> console -> network -> curl -> curl
# Filesystem packages -> console -> network -> rsync -> rsync
# Filesystem packages -> console -> tools -> parted -> parted
# Filesystem packages -> console -> utils -> bash-completion -> bash-completion
# Filesystem packages -> console -> utils -> file -> file
# Filesystem packages -> console -> utils -> git -> git
# Filesystem packages -> console -> utils -> git -> git-bash-completion
# Filesystem packages -> console -> utils -> grep -> grep
# Filesystem packages -> console -> utils -> man -> man
# Filesystem packages -> console -> utils -> man-pages -> man-pages
# Filesystem packages -> console -> utils -> screen -> screen
# Filesystem packages -> console -> utils -> sed -> sed
# Filesystem packages -> console -> utils -> unzipo -> unzip
# Filesystem packages -> console -> utils -> vim -> vim
# Filesystem packages -> console -> utils -> zip -> zip
# Filesystem packages -> devel -> autoconf -> autoconf
# Filesystem packages -> devel -> automake -> automake
# Filesystem packages -> devel -> binutils -> binutils
# Filesystem packages -> devel -> expect -> expect
# Filesystem packages -> devel -> make -> make
# Filesystem packages -> misc -> ca-certificates -> ca-certificates
# Filesystem packages -> misc -> gdb -> gdb
# Filesystem packages -> misc -> gdb -> gdbserver
# Filesystem packages -> misc -> net-tools -> net-tools
# Filesystem packages -> misc -> packagegroup-core-buildessential -> packagegroup-core-buildessential
# Filesystem packages -> misc -> packagegroup-core-tools-debug -> packagegroup-core-tools-debugl
# Filesystem packages -> net -> netcat -> netcat
# Filesystem packages -> net -> tcpdump -> tcpdump
# Petalinux Package Groups -> packagegroup-petalinux -> packagegroup-petalinux
# Petalinux Package Groups -> packagegroup-petalinux-networking-debug -> packagegroup-petalinux-networking-debug
# Petalinux Package Groups -> packagegroup-petalinux-networking-stack -> packagegroup-petalinux-networking-stack
# Petalinux Package Groups -> packagegroup-petalinux-lmsensors -> packagegroup-petalinux-lmsensors
```
