#! /bin/bash -ue

# 21Oct23 Inital Version

VERSION="0.1"

on_exit() {
    : echo 'ON_EXIT: Cleaning up...(remove tmp files, etc)'
#    rm -f ${TMP1}
}

trap 'on_exit' EXIT




usage() {
    cat <<EOF

USAGE: 
       $0 [-v|--verbose] [-V|--version] [-h|--help] {-p | --partition} <part no> <no drives>

       Assumes the device /dev/md0 was created (or attempted to be created)
       using the device names described.

       $0 -p9 3

       Would wipe all the data in /dev/sda9 /dev/sdb9 /dev/sdc9  (3 devices)

       $0 -p9 4

       Would wipe all the data in /dev/sda9 /dev/sdb9 /dev/sdc9 /dev/sdd9 (4 devices)

       -v | --verbose       More messages (also passed ot mkfs)
       -V | --version       print version no and exit
       -p | --partition	    The partition No on each drive (FYI data was usually partition#9 )

       n defults to 4

       This script was created on a TS412, with 4 drives installed in trays + 1 eSATA SSD

       Tray1=/dev/sda , Tray2=/dev/sdb , Tray3=/dev/sdc , Tray4=/dev/sdd , eSATA/USB ...sde, sdf etc

       If you have only 3 bays populated, the eSATA (or USB) would become sdd (not sde)


       If you've followed the convention of "homebrew" trays 1-4 will have a
       partition (number 9) with the label data0...data4. It will have a
       filesystem on it, but this script will blow it away.

       If you only have 3 drives , set n to 3; similarly n=5 would allow you to use eSATA
       (or USB) drives.

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
ARGS=`getopt -o "p:hvV" -l "partition:,help,verbose,version" -n "${PROG}" -- "$@"`

n=4
partition=""

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
	-p|--partition) 
	    partition=$2
	    shift 2;;
	-h|--help) 
	    usage ${PROG}
	    shift;;
	--)
	    shift
	    break;;
    esac
done

if [[ -z "${partition}" ]] ; then
    echo "Partition MUST be defined" >&2
    usage ${PROG}
    exit 1
fi

if [[ $# -eq 1 ]] ; then
    n=$1 ; shift
else
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


drives=( sda sdb sdc sdd sde sdf )


volumes=""

for ((i=0; i<n; i+=1))
do
   volume="/dev/${drives[i]}${partition}"
    if [[ -b ${volume} ]] ; then
	volumes+="${volume} "
    else
	echo "Device ${volume} does not exist" >&2
	failed="yes"
    fi
done

if  [[ -n ${failed} ]] ; then


    cat >&2 << EOF
    Some of the required devices (partition) are misssing. Possibly the disks are not partitioned
    as you expect
    
EOF

    exit 3
    
fi

echo "We are about to trash the following devices ${volumes}, press any key to continue" >&2
read reply

echo "Don't be concerned about errors relating to stopping the RAID array (it may not exist)"

# Some cockups in inital setup can create /dev/md127 instead of /dev/md0
for md in /dev/md*
do
    mdadm -S ${md}
done

for volume in ${volumes}
do
    wipefs -a ${volume}
done

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
sysctl -w dev.raid.speed_limit_min=100000
sysctl -w dev.raid.speed_limit_max=5000000

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



if [[ ${verbose} -gt 0 ]] ; then
    echo "Putting an ext4 filesystem on /dev/mt0 (the  Raid Array)" >&2
fi



# See: https://superuser.com/questions/784606/forcing-ext4lazyinit-to-finish-its-thing
EXTENDED_EXT4_OPTIONS="lazy_itable_init=0"  # Do the whole job now, otherwise the disk stays spun up for days
wipefs -a /dev/md0
mkfs -v -text4 -E ${EXTENDED_EXT4_OPTIONS} /dev/md0

cat /proc/mdstat
