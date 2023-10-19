#! /bin/bash -ue

# 03Oct23 Inital Version


VERSION="0.1"

on_exit() {
    : echo 'ON_EXIT: Cleaning up...(remove tmp files, etc)'
#    rm -f ${TMP1}
}

trap 'on_exit' EXIT




usage() {
    cat <<EOF

USAGE: 
       $0 [-v|--verbose][-s <n> | --spindown <n> ] <drive>

       Configure the drive <drive> so that it spins down if idle for <n>.

       -c | --check passes  The check flag to mkfs (can be specified twice, see mkfs(8) man page
       -b | --bootorder     Normally sda is boot1, sdb=boot2 , but you may need to override
       -v | --verbose       More messages (also passed ot mkfs)


       This script was created on a TS412, with 4 drives installed in trays + 1 eSATA SSD

       Tray1=/dev/sda , Tray2=/dev/sdb , Tray3=/dev/sdc , Tray4=/dev/sdd , eSATA/USB ...sde, sdf etc

       If you have only 3 bays populated, the eSATA (Uor USB) would become sdd (not sde)


       Note boot order determines which disk becomes the root filesystem (also
       usually defines /home /tmp etc) normally tray1(sda) is bootorder1 , tray2 bootorder 2 etc 

       Normal usage, Trays1-4 have a bootable system on them but an eSATA SSD has the "best one"
       (because it's silent. So choose 5 or greater for the SSD.
       
       So a typical 4 Bay + 1 eSATA would be:

       TRAY1 = sda = boot1
       TRAY2 = sdb = boot2
       TRAY3 = sdc = boot3
       TRAY4 = sdd = boot4
       Esata = sde = boot5

       If you only have 2 bays populated, it proably a good idea to make the eSATA boot5
       so that you have an upgrade path.

       TRAY1 = sda = boot1
       TRAY2 = sdb = boot2
       Esata = sdc = boot5


       You need to run this as root.

       Before using this script you need to initialise the disk (fdisk, parted etc) in the NAS
       or in another computer. This is to ensure we don't destroy data. You should specify a GPT
       label.
       
       This script will create the following (sizes are the defaults):

       Partition#1  => /boot   	   
       Partition#2  => root (/)
       Partition#5  => /var
       Partition#6  => SWAP
       Partition#7  => /tmp
       Partition#8  => /home
       Partition#9  => /data
       Partition#10 => /rest
       
       You don't need to use this script. You don't need to use GPT. You DO need to ensure
       the minimal filesystems exist and, most importantly, that the labels are correct.
EOF

}


# Dump of SDE (external SSD)
#
# /dev/sde1 : start=        2048, size=     2316289, type=83, bootable
# /dev/sde2 : start=     2320384, size=    48828417, type=83
# /dev/sde3 : start=    51150848, size=   886552240, type=5
# /dev/sde5 : start=    51152896, size=    19529729, type=83
# /dev/sde6 : start=    70686720, size=     1486849, type=83
# /dev/sde7 : start=    72177664, size=     3903489, type=83
# /dev/sde8 : start=    76085248, size=   861617840, type=83

typeset -i verbose

fsflags=""
bootorder=0
verbose=0
PROG=$0
ARGS=`getopt -o "chvb:" -l "check,help,verbose,bootorder:" -n "${PROG}" -- "$@"`

#Bad arguments
if [ $? -ne 0 ];
then
    usage
    exit 1
fi


eval set -- "$ARGS"

while true;
do
    case "$1" in
	-c|--check) 
	    fsflags+="-c "
	    shift;;
	-v|--verbose) 
	    verbose+=1
	    fsflags+="-v "
	    shift;;
	-b|--bootorder) 
	    bootorder=$2
	    shift 2;;
	-h|--help) 
	    usage ${PROG}
	    shift;;
	--)
	    shift
	    break;;
    esac
done

if [[ $# -ne 1 ]] ; then
    usage ${PROG}
    exit 1
fi

DEV=$1


case "${DEV}" in
    tray1|Tray1|1)
	DEV="/dev/sda"
	;;
    tray2|Tray2|2)
	DEV="/dev/sdb"
	;;
    tray3|Tray3|3)
	DEV="/dev/sdc"
	;;
    tray4|Tray4|4)
	DEV="/dev/sdd"
	;;
esac

if [[ ${bootorder} == "0" ]] ; then  # If it wasn't set , define it from Tray No
    case "${DEV}" in
	"/dev/sda")
	    bootorder=1
	    ;;
	"/dev/sdb")
	    bootorder=2
	    ;;
	"/dev/sdc")
	    bootorder=3
	    ;;
	"/dev/sdd")
	    bootorder=4
	    ;;
    esac
fi

if [[ ${bootorder} == "0" ]] ; then  # Then it's proably an external Drive
    bootorder=5
fi


if [[ ${verbose} -gt 0 ]] ; then
    echo "Verbose mode enabled VERSION=${VERSION}" >&2
fi

if [[ ! -b ${DEV} ]] ; then
    echo "${DEV} is not a block device" >&2
    exit 1
fi



# You can override these by setting as environment variables
# One easy way is SIZE_TMP:=  "3000 MiB" QNAP_commision_disk

: ${SIZE_BOOT:="2000MiB"}
: ${SIZE_ROOT:="24000MiB"}
: ${SIZE_VAR:="10000MiB"}
: ${SIZE_TMP:="2000MiB"}
: ${SIZE_SWAP:="2000MiB"}
: ${SIZE_HOME:="1GiB"}
: ${SIZE_DATA:="512GiB"}


b=${bootorder}

if [[ ${verbose} -gt 0 ]] ; then
    cat >&2 <<EOF
        Will format ${DEV}
	It will have a bootorder of ${bootorder}
	It will contain:
	BOOT${b} = ${SIZE_BOOT}
	ROOT${b} = ${SIZE_ROOT}
	VAR${b}  = ${SIZE_VAR}
	TMP${b}  = ${SIZE_TMP}
	SWAP     = ${SIZE_SWAP}
	HOME${b} = ${SIZE_HOME}
	DATA${b} = ${SIZE_DATA}
	REST${b} = The remains of the drive

EOF

fi


if [[ $(id -u) -ne 0 ]] ; then
    echo "You are $(id -un) you need to su or sudo to root before running this" >&2
    usage $0
    exit 2
fi

if (sfdisk -l ${DEV} | grep -q Sectors) ; then
    echo "The disk ${DEV} is not blank, create a blank GPT label (sfdisk, fdisk, parted)" >&2
    echo "This is a sanity check to make sure it's the device you intended." >&2
    exit 1
fi

echo "Last chance to bail out --- press enter to continue" >&2
read reply


echo -e "\n\nBefore:"

sfdisk -l ${DEV}

#cat <<EOF
sfdisk ${DEV} <<EOF
${DEV}1 : name=boot${b},  size=${SIZE_BOOT}, type=linux, bootable
${DEV}2 : name=root${b},  size=${SIZE_ROOT}, type=linux

${DEV}5 : name=var${b},   size=${SIZE_VAR},  type=linux
${DEV}6 : name=swap${b},  size=${SIZE_SWAP}, type=swap
${DEV}7 : name=tmp${b},   size=${SIZE_TMP},  type=linux
${DEV}8 : name=home${b},  size=${SIZE_HOME}, type=linux

${DEV}9 : name=data${b},  size=${SIZE_DATA}, type=linux
${DEV}10 : name=rest${b},                    type=linux


EOF




echo -e "\n\nAfter:"

sfdisk -l ${DEV}


echo -e "\n\nFormatting:"

wipefs -a ${DEV}1 
wipefs -a ${DEV}2 
wipefs -a ${DEV}5 
wipefs -a ${DEV}6
wipefs -a ${DEV}7 
wipefs -a ${DEV}8 
wipefs -a ${DEV}9 
wipefs -a ${DEV}10

echo "BOOT" ; mke2fs -text4 ${fsflags} -Lboot${b} ${DEV}1
echo "ROOT" ; mke2fs -text4 ${fsflags} -Lroot${b} ${DEV}2
echo "VAR"  ; mke2fs -text4 ${fsflags} -Lvar${b}  ${DEV}5
echo "SWAP" ; mkswap -L swap${b} ${DEV}6
echo "TMP"  ; mke2fs -text4 ${fsflags} -Ltmp${b}  ${DEV}7
echo "HOME" ; mke2fs -text4 ${fsflags} -Lhome${b} ${DEV}8
echo "DATA" ; mke2fs -text4 ${fsflags} -Ldata${b} ${DEV}9
echo "REST" ; mke2fs -text4 ${fsflags} -Lrest${b} ${DEV}10



