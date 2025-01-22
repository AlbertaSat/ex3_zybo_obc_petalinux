# Zybo Test OBC Petalinux Project

This project contains the petalinux configuration for the Zybo Test OBC. The Vivado project and subsequent bitstream and hardware documentation can be found in the [ex3_zybo_obc_config](https://github.com/AlbertaSat/ex3_zybo_obc_config) repository.

## Instructions

The following is step-by-step instructions for setting up the required tools for the Zybo Test OBC Petalinux project, building the project, and flashing the SD card.

**NOTE:** *If your are using MacOS or Windows see [Mac OS and Windows Troubleshooting](#mac-os-and-windows).*

1. Download and install [Docker](https://docs.docker.com/engine/install/)
2. Download [Petalinux 2022.2](https://www.xilinx.com/member/forms/download/xef.html?filename=petalinux-v2022.2-10141622-installer.run) (Requires free AMD account to download) and place it in this folder
3. Download and install [Balena Etcher v1.18.11](https://github.com/balena-io/etcher/releases/tag/v1.18.11)
4. Run the docker build command outlined in the [Docker Build](#build-image) section
5. Run the docker container using the command outlined in the [Docker Run](#run-container) section
6. In the docker container shell:
    1. Change your working directory to the project directory using: `cd /home/petalinux/project`
    2. Follow the [Build Petalinux](#build-project) section to build the petalinux project
    3. Follow the [Create Boot Image](#create-boot-image) section to create the boot image
    4. (Optional) Follow the [Qemu Emulation](#qemu-emulation) section to emulate the system
7. Follow the [Flash SD Card](#flash-sd-card) section to flash the SD card

## Documentation

### Docker

The main usecase for the docker image if for the CI/CD pipeline, however, it can also be used to build the petalinux project locally if you do not want to pollute your system with the petalinux tools and dependencies.

#### Build Image

To build the docker image, download the desired petalinux install and place it in this projects root folder then run the following command:

```bash
# Optional build arguments:
# --build-arg PETA_RUN_FILE=<name-of-run-file> (default: "petalinux-v2022.2-10141622-installer.run"
docker build -t zybo_obc_petalinux .
```

#### Run Container

To use the docker image, you will need to bind mount the project directory to the `/project` directory in the container. The following command will start the container and open a shell in the project directory:

```bash
docker run -it --rm -v $(pwd):/home/petalinux/project zybo_obc_petalinux
```

### Petalinux

Most petalinux commands should either be ran from the project directory (`/home/petalinux/project` in the docker container, you can change your working directory to it using `cd /home/petalinux/project`) or specifying the project directory with the `-p`/`--project` argument.

Example:
`petalinux-config --silentconfig -p /home/petalinux/project`
`petalinux-build --project /home/petalinux/project`

Note: `petalinux-boot` does not have the `-p` argument so you must ensure your working directory is the petalinux project.

#### Build Project

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

#### Update bitstream

If the vivado project gets updated, the bitstream should be exported and configured in the petalinux project.

```bash
petalinux-config --get-hw-description="<path-to-xsa-file>"
```

#### Create Boot Image

After building the petalinux project, the boot image can be created using the following command:

```bash
# Create boot stuff
petalinux-package --boot --force --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot

# Create wic image, will be outputted to images/linux/petalinux-sdimage.wic
petalinux-package --wic
```

The wic image can then be used to either create a bootable SD card or emulate the system using QEMU.

#### Qemu Emulation

First ensure your working directory is the petalinux project (use `cd /home/petalinux/project`) then simply run the following command to emulate the system using QEMU after you have created the image:

```bash
# Run QEMU
petalinux-boot --qemu --kernel
```

To quit QEMU `Ctrl + A` then `x`.

#### Device Tree

##### Modify Device Tree

##### View Final Tree

To view the final device tree after building the image, you can use the following command:

```bash
# From the project directory in a linux enviornment 
# with the device tree compiler installed (basically just use the docker container)
dtc images/linux/system.dtb -o dts
```

This will output a text file named `dts` that can be opened using any text editor.

### Flash SD Card

#### Method 1: Full image using Balena Etcher (Recommended)

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

### Yocto

To get acces to the bitbake commands, run the following:

```bash
source components/yocto/environment-setup-cortexa9t2hf-neon-xilinx-linux-gnueabi
source components/yocto/layers/core/oe-init-build-env 
```

### Zybo

#### Setup

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

#### Testing interfaces

##### UART

To test a SPI interface, you can connect the interface in a loopback (i.e. connect TX to RX) then open up to terminal sessions to the zybo (either two ssh sessions or one ssh and one serial connection).

In the first terminal, run the command `cat /dev/tty<port>`.

In the second terminal, run the command `echo "This is a test!" > /dev/ttyUL1`.

If it is working, the message should be recieved in the first terminal.

##### SPI

To test a SPI interface, you can connect the interface in a loopback (i.e. connect MISO to MOSI) then run the following command:

```bash
spidev_test -v -D /dev/spidev<port>.0
```

When its working, it should output the following:

```bash
spi mode: 0x0
bits per word: 8
max speed: 500000 Hz (500 kHz)
TX | FF FF FF FF FF FF 40 00 00 00 00 95 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF F0 0D  |......@.........................|
RX | FF FF FF FF FF FF 40 00 00 00 00 95 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF F0 0D  |......@.........................|
```

Note how the TX and RX messages are the same, this means the interface is working correctly. If they are not the same, something went wrong somewhere.

##### CAN (WIP)

Before CAN cna be used, the following must be done

1. Set the can bit-timing: `sudo ip link set can0 type can bitrate 200000`
    - Expected output: `xilinx_can e0008000.can can0: bitrate error 0.0%`
2. Enable can network: `sudo ip link set can0 up`
    - Expected output: `IPv6: ADDRCONF(NETDEV_CHANGE): can0: link becomes ready`

#### Copy files to Zybo

Easiest way to copy a folder from your computer to a Zybo connected to ethernet would be the `scp` command as follows:

```bash
# Copy to home directory on zybo
scp -r <path_to_folder> petalinux@142.244.38.28:/home/petalinux/.
```

You can also copy files from the zybo using:

```bash
# Copy from Zybo to your home directory
scp -r petalinux@142.244.38.28:<path_to_folder> ~/.
```

### CICD (WIP)

The project includes a GitHub Actions workflow that will build the petalinux project and create a wic image. The workflow can be triggered by creating a new tag with the format `v*.*.*`.

As petalinux is a somewhat under export control restrictions, the workflow is set to run on a self-hosted runner using a locally built verion of the included Dockerfile. All built zybo images will also be stored on the runners machine.

To ensuretestspi that the runner is secure, a repository should be private. If the repository is public, the setting `Actions -> General -> Fork pull request workflows from outside collaborators` must be set to `Require approval for all outside collaborators` so that the runner is not exposed to malicious code by unknown collaborators through PR'sc.

## Troubleshooting

### Mac OS and Windows

Currently there are issues during build on Mac OS and issues creating WIC images on Windows when using the docker container from the native hosts. To get around this a VM needs to be used. Please see [this guide](https://docs.qualcomm.com/bundle/publicresource/topics/80-70015-41/getting-started.html) for setting up an Ubuntu VM on Mac OS and Windows.

For windows, see [this manual](https://docs.docker.com/desktop/features/wsl/#enabling-docker-support-in-wsl-2-distributions) on how to enable access to docker from WSL and [this guide](https://joe.blog.freemansoft.com/2022/01/setting-your-memory-and-swap-for-wsl2.html) on how to increase available RAM and virtual CPU's WSL has access to.

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
# Device Drivers > I2C Support > I2C hardware Bus Support > Xilinx I2C Controller
# Device Drivers > Character Devices > Serial drivers > Xilinix uartlite serial port support

petalinux-config -c rootfs
# Set the following options:
# User packages > spitools
# User packages > spidev-test
# User packages > memtester
# User packages > smem
# User packages > stressapptest
# User packages > nano
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
