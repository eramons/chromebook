#!/bin/sh
#set -x

# Bash script to build a bootable kernel for the ASUS C101PA Chromebook

# Set defaults
CMDLINE=./cmdline
ITS=./kernel.its

# Args
if [ "$#" -lt 1 ] 
	then echo "Usage: run partition [path to its file] [path to text file containing cmdline]"
	exit 1
fi

# Set partition
PART=$1

# Set its file path if provided
if [ "$#" -gt 1 ]
	then ITS=$2
fi

# Set cmdline file path if provided
if [ "$#" -gt 1 ]
	then CMDLINE=$3
fi

echo "---> Partition to flashed kernel to: $PART"
echo "---> Path to .its file: $ITS"
echo "---> Kernel command line:\n `cat $CMDLINE`"

# Run mkimage to build a kernel image. Input: its file Output: image in uimg format
mkimage "-D -I dts -O dtb -p 2048" -f $ITS vmlinux.uimg

if [ "$?" -ne 0 ]; 
	then echo "mkimage failed with $?"
	exit 1 
fi
echo "---> mkimage: SUCCESS"

# Check if bootloader.bin available before running vbutil, otherwise create it
	if ! [ -f bootloader.bin ]; then
	echo "---> Generating empty booloader.bin..."
	dd if=/dev/zero of=bootloader.bin bs=512 count=1
fi

# Run vbutil_kernel to get a bootable image for the chromebook
vbutil_kernel \
	--pack vmlinux.kpart \
	--version 1 \
	--vmlinuz vmlinux.uimg \
	--arch aarch64 \
	--keyblock /usr/share/vboot/devkeys/kernel.keyblock \
	--signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
	--config cmdline \
	--bootloader bootloader.bin

if [ "$?" -ne 0 ]; 
	then echo "vbutil failed."
	exit 1 
fi
echo "---> vbutil_kernel: SUCCESS"

# Flash kernel image to partition
if [ -b $PART ]; then
	sudo dd if=vmlinux.kpart of=$PART 
	echo "---> Successfully flashed to $PART"
	sudo sync
else
	echo "---> Partition $PART does not exist"	
fi

