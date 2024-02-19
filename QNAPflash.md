% QNAP flash image utilities Documentation

NAME
====

**action\_flash\_kernel** — Does a real flash kernel

**dl\_flash\_kernel** — Does a fake flash kernel

**/usr/local/lib/QNAPhomebrew** - script body of dl\_flash\_kernel

**fake\_flash\_kernel.sh** - replaces flash_kernel and **DOES NOT flash** (instead calls construct_dl_image)

**construct\_dl\_image** - takes /var/opt/homebrew/mtd[12] and Builds images in /var/opt/homebrew/dl_<somename> 

**count\_goes.sh** - utility that counts attempts to do things

**dl\_flash\_kernel** - Just creates /var/opt/homebrew/mtd1 (kernel) and /var/opt/homebrew/mtd2 (initrd)

SYNOPSIS
========

These scripts can be combined to create a "DEV build" environment suitable fot QNAPhowbrew. They are NOT required.


DESCRIPTION
===========

First some background. In developing QNAPhomebrew my motherboard "died" , it got
errors reflashing the NOR memory (kernel & initrd) this may well be due to "wearing out" the NOR memory by repeated flashing . To avoid this in future I
produced a system to allow the NAS to be booted via BOOTP, avoiding the need to
flash the system at all.

The next issue is the "flash layout" initially installed with the QNAP is unable
to support modern kernels since it does not reserve enough space for the kernel.
There are multiple solutions to this each has different issues:

	QTS      - 2 MB Kernel + 9MB Inintrd. Original , runs QTS software and old linux kernel
	Saboteur - 3 MB Kernel + 9MB Inintrd. Original partitions, but repurposed
	Mouiche  - 3 MB Kernel + 12Mb initrd. Repartitioned moves kernel into lower NOR memory
	M11      - 3 MB Kernel + 11Mb initrd. Repartitioned leaves kernel at original location.

Deciding what layout suits you best if out of scope for this document, however
the decision made has effects on how you use these scripts.

The QNAP supports a PiXE recovery mode. With this you create a "PiXE image" and
save this on a box running TFTP and DHCP. Holding the reset pin on the QNAP
while powering on until it beeps causes a "recovery" via the network. An image
is loaded over TFTP (using PiXE rules) and is flashed into the NOR memory, the
system then boots from this image. The format of this image is slightly odd. The
image saved and loaded by TFTP is up to 16MB is size starting at offset 0
(zero).  HOWEVER the 1st 2MB are IGNORED (skipped) . This is because the UBOOT
loader uses the lower part of the flash and is not overwritten by recovery
(implying you cannot recover from UBOOT corruption using thise scheme. I know of
no mechansims that does allow UBOOT to be recovered). 

One side-effect of this PiXE recovery mechanism is that YOU CANNOT USE PiXE to
recover a Mouiche layout.  So I'd suggest Saboteur or M11 layouts.

However **there is a totally different way to boot the QNAP**. You can use BOOTP
to load a kernel and initrd directly into RAM (starting at address 0x80000)

So in order to use BOOTP you need a different image, the naming convention used
here is dl-*name* , so you might have:


    16777216 Dec  8 00:04 F_TS-412-M11_bookworm_6.1.0-13-marvell
    14680064 Dec  7 23:48 dl-F_TS-412-M11_bookworm_6.1.0-13-marvell-sans-LVM2

The dl- version is 2MB smaller. It starts with the kernel (loaded at 0x800000)
missing out the unused UBOOT sections.


I have the system setup to boot; 1st attempt BOOT from a DHCP server (using
BOOTP), if that fails it boots from flash using the M11 layout.

For reference this is the UBOOT setup I use (it's based on M11)


    # Need 2 X DHCP, 1st fails but causes a long delay.
    setenv mtdparts spi0.0:512k@0(uboot)ro,3M@0x200000(Kernel),11M@0x500000(RootFS1),2M@0x200000(Kernel_legacy),256k@0x80000(U-Boot_Config),1280k@0xc0000(NAS_Config),16M@0(all)ro
    setenv bootargs console=ttyS0,115200 root=/dev/ram initrd=0xb00000,0xB00000 ramdisk=34816 cmdlinepart.mtdparts=${mtdparts} mtdparts=${mtdparts}
    setenv fbootcmd echo flash\;cp.l 0xf8200000 0x800000 0xc0000\;cp.l 0xf8500000 0xb00000 0x2C0000\;bootm 0x800000
    setenv nbootcmd echo net\;dhcp\;dhcp\;tftpboot 0x800000 dl-\${bootfile}\;bootm 0x800000
    setenv bootcmd  uart1 0x68\;${nbootcmd}\;${fbootcmd}
    setenv bootdelay=5


So the normal workflow is:

* All events that would normally cause flash-kernel(8) to be called (e.g. rebuilding initrd) instead call fake\_flash\_kernel(8) which creates a dl-*name* image
* the dl-*name* image is copied (by hand) to a TFTP server and the config setup suitably
* In the M11 layout the md6 partion defines the full 16MB NOR flash (in other layouts you need to concatenate multiple md partitions) this can be also transferred as PiXE recovery image on the TFTP server.
* Eventually the real flash can be rewritten using action\_flash\_kernel(8)




Options
-------

FILES
=====

* /var/opt/homebrew/ various files used in making PiXE boot images
* /var/opt/homebrew/count_flash_attempts - Number of time an attempt to reflash was intercepted
* /var/opt/homebrew/count_flash_actuals  - Number of time an attempt to reflash was actioned


ENVIRONMENT
===========

The Saboteur and Mouiche layouts have instructions and in the latter case a script to set them up. If you want to try the M11 layout then
the only way (currently) is to use a Serial console and UBOOT commands.

The locations of the config of these "helpful" scripts are realy an exercise of the reader. I've found I needed to actually replace
the binary flash\-kernel(8) as overriding using /usr/local/sbin was bypassed in some cases.



BUGS
====

See GitHub Issues: https://github.com/graemev/QNAPhomebrew/issues

AUTHOR
======

Graeme Vetterlein <graeme.debian@vetterlein.com>

SEE ALSO
========


**action\_flash\_kernel(8)**
**dl\_flash\_kernel(8)**
**fake\_flash\_kernel(8)**
**construct\_dl\_image(8)**
**count\_goes.sh(8)**
**dl\_flash\_kernel(8)**

