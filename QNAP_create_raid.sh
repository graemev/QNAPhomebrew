#! /bin/bash -ue

# 10Oct23 Inital Version
# 21Oct23 Copes with "rerun" (bails out) still just echoing commands

# Need to rerun:
# dpkg-reconfigure mdadm
#
# And select that RAID array should NOT be auto assembled:
#
# See: https://unix.stackexchange.com/questions/166688/prevent-debian-from-auto-assembling-raid-at-boot

VERSION="0.1"

on_exit() {
    : echo 'ON_EXIT: Cleaning up...(remove tmp files, etc)'
#    rm -f ${TMP1}
}

trap 'on_exit' EXIT




usage() {
    cat <<EOF

USAGE: 
       $0 [-v|--verbose] [-V|--version] [-h|--help] [<name> [<n>] 

       Configure the drive with labels <name>1, <name>2, <name>3, <name>4 

       -v | --verbose       More messages (also passed ot mkfs)
       -V | --version       print version no and exit

       name defaults to "data"
       n defults to 4

       This script was created on a TS412, with 4 drives installed in trays + 1 eSATA SSD

       Tray1=/dev/sda , Tray2=/dev/sdb , Tray3=/dev/sdc , Tray4=/dev/sdd , eSATA/USB ...sde, sdf etc

       If you have only 3 bays populated, the eSATA (or USB) would become sdd (not sde)


       If you've followed the convention of "homebrew"  trays 1-4 will have a partition
       with the label data0...data4. It will have a filesystem on it, but this 
       script will blow it away. 

       If you only have 3 drives , set n to 3 n=5 would allow you to use eSATA
       (or USB) drives.


       NB. (https://superuser.com/questions/784606/forcing-ext4lazyinit-to-finish-its-thing)
       In order to 'force' ext4lazyinit to finish the thing it does with maximum
       priority, you need to mount the filesystem with 'init_itable=0'. By
       default it is 10 (for detail please see link below)

       I've fought a long battle to get boot to NOT assemble the RAID array, so
       we could assemble it via scripts when we do QNAPmount, it's difficult.

       So much effort has gone into ensuring that RAID arrays get assembled by
       initrd that you need to break a lot of things to prevent it. So I've
       given up and decided to go with flow. The RAID array will get assembled
       by initrd using information we store in /etc/mdadm/mdadm.conf



EOF
    lsblk -f 
}


typeset -i verbose
typeset -i verbose
typeset -i quiet

version=0
verbose=0
quiet=0

PROG=$0
ARGS=`getopt -o "hvV" -l "help,verbose,version" -n "${PROG}" -- "$@"`

n=4
name="data"
devices=""

typeset -i count
typeset -i i


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
	-v|--verbose) 
	    verbose+=1
	    shift;;
	-V|--version) 
	    version+=1
	    shift;;
	-q|--quiet) 
	    quiet+=1
	    shift;;
	-h|--help) 
	    usage ${PROG}
	    shift;;
	--)
	    shift
	    break;;
    esac
done

if [[ $# -gt 0 ]] ; then
    name=$1 ; shift
fi

if [[ $# -gt 0 ]] ; then
    n=$1 ; shift
fi

if [[ $# -gt 0 ]] ; then
    usage ${PROG}
    exit 1
fi

if [[ ${version} -gt 0 ]] ; then
    echo "${PROG} VERSION=${VERSION}" >&2
    exit 0
fi

if [[ ${verbose} -gt 0 ]] ; then
    echo "Verbose mode enabled VERSION=${VERSION}" >&2
fi

case "${n}" in
    3|4|5|6)
	count=${n}
	;;
    *)
	echo "This will be raid 5 , need 3-6 drives"
	exit 2
	;;
esac

# Check we have the drives we need.

volumes=""

for ((i=1; i<=n; i+=1))
do
   volume="/dev/disk/by-label/${name}${i}"
    if [[ -b ${volume} ]] ; then
	volumes+="${volume} "

	devname=$(readlink ${volume})
	base=$(basename ${devname})   # eg sda9

	devices+="${base} "
	
    else
	echo "Device ${volume} does not exist" >&2
	failed="yes"
    fi
done

if  [[ -n ${failed} ]] ; then


    cat >&2 << EOF

Aborting due to missing devices.  A common reason might be if you'd already
tried to create a RAID array, the labels will have been lost, e.g you
tried to used labels data1, data2, data3 and data4 . These exist in a ext filesystem.
A previous raid creation would have lost these labels.
Use QNAP_recreate_raid.sh instread. Beware this will destroy any data in that RAID array.
EOF

    exit 3
    
fi

cat <<EOF

Note (from WIKI)
For raid5 there is an optimisation: mdadm takes one of the disks and marks it as
'spare'; it then creates the array in degraded mode. The kernel marks the spare
disk as 'rebuilding' and starts to read from the 'good' disks, calculate the
parity and determines what should be on the spare disk and then just writes to
it.

Upshot is that you may find the array rebuiling for a whole day :-)

EOF

# See: https://www.cyberciti.biz/tips/linux-raid-increase-resync-rebuild-speed.html


sysctl dev.raid.speed_limit_min
sysctl dev.raid.speed_limit_max

# We want RAID to get recovered ASAP (otherwise the disk can't sleep)
# However choosing a high settting may be an issue. I had flash-kernel fail while md0 was in recovery
#
# I had dev.raid.speed_limit_min=100000 + dev.raid.speed_limit_max=5000000 used 75+% in process md0_raid5 
#
sysctl -w dev.raid.speed_limit_min=1000
sysctl -w dev.raid.speed_limit_max=2000000

cat > /etc/sysctl.d/10-QNAPraid.conf <<EOF
dev.raid.speed_limit_min=100000
EOF

if [[ ${verbose} -gt 0 ]] ; then
    echo "Building the array from ${volumes}" >&2
fi


mdadm --verbose --create /dev/md0 --level=5 --raid-devices=${n} ${volumes}

cat > /etc/mdadm/mdadm.conf  <<EOF

# by default (built-in), scan all partitions (/proc/partitions) and all
# containers for MD superblocks. alternatively, specify devices to scan, using
# wildcards if desired.
#DEVICE partitions containers

# automatically tag new arrays as belonging to the local system
HOMEHOST <system>

# instruct the monitoring daemon where to send mail alerts
MAILADDR root

# definitions of existing MD arrays

# This configuration was auto-generated on Sun, 30 Jul 2023 22:58:30 +0100 by mkconf

EOF

mdadm --detail --scan  >> /etc/mdadm/mdadm.conf

echo "$devices"  > /var/opt/homebrew/md0-devices


if [[ ${verbose} -gt 0 ]] ; then
    echo "Putting an ext4 filesystem on /dev/mt0 (the  Raid Array)" >&2
fi



# See: https://superuser.com/questions/784606/forcing-ext4lazyinit-to-finish-its-thing
EXTENDED_EXT4_OPTIONS="lazy_itable_init=0"  # Do the whole job now, otherwise the disk stays spun up for days

mkfs -v -text4 -E ${EXTENDED_EXT4_OPTIONS} /dev/md0

cat /proc/mdstat
