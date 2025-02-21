#! /bin/bash -ue




# GPV 27Sep23 Inital Version
# GPV 21Feb25 Force unmount of other flavours of OUR mount, otherwise it becomes read-only and so rsync(1) fails

VERSION="1.0"

on_exit() {
    : echo 'ON_EXIT: Cleaning up...(remove tmp files, etc)'
#    rm -f ${TMP1}
}

trap 'on_exit' EXIT




usage() {
    cat <<EOF

USAGE: 
       $0 [-v|--verbose] [-h|--help] [-q|--quiet] [-V|--version] -b <n>

       Clone a drive for use in NAS, using "homebrewNAS" config.

       -b | --bootorder     This is the "disk" we are making a clone to
       -v | --verbose       More messages (also passed to mkfs)
       -q | --quiet         Useful if you want to run in a script
       -v | --version	    Just print version number and exit


       This script was created on a TS412, with 4 drives installed in trays + 1 eSATA SSD

       Tray1=/dev/sda , Tray2=/dev/sdb , Tray3=/dev/sdc , Tray4=/dev/sdd , eSATA/USB ...sde, sdf etc

       If you have only 3 bays populated, the eSATA (Uor USB) would become sdd (not sde)


       The "trick" with the HomeBrew NAS is, the NAS can boot from ANY of the
       drives Trays 1-4 eSATA or USB drives. The script choose_root
       (/etc/initramfs-tools/scripts/local-top/choose-root) will choose a
       filesystem with a label of the form "root<n>" . It will choose the higest
       number. So a common setup is tray1 holds root1, tray2 root2 etc and the
       eSATA is root5. So normally it will choose root5 (the eSATA) . If this
       situation continues for some time (years) the the eSATA fails, at the
       next boot it will choose root4 (e.g. tray4) if it has been years sinice
       the last update this could go very badly. So this script attempts to keep
       a "drive" up to date:

       1: We don't go by "drive" name , slot etc. We rely totally on labels so
         -b 2 would update label=root2

       2: We assume the "best" image is this one we are currently running. If
          you do this regularly this should be true. If you wait until a drive
          has failed and you are running on a secondary, it may well downgrade a drive.

	  As an example, consider we run Debain Bullseye and we upgrade to
	  Bookworm, while runniing on the eSATA (root5) if we update 1 - 4, all
	  will move to Bookworm.  If we don#t update and at some later date,
	  boot from Tray4=root4, we will still be running bullseye, if we run this 
	  script with -b 1 then root1 will get downgraded. If we find the eSATA was unplugged
	  and plug it in an update, it will get downgraded to bullseye.
	  SO UPDATE OFTEN.

       3: We don't really "clone". First we only copy enough filesystems to get
          the system to run (with all it's installed software) we don't touch
          user data.  We cannot simply copy all the files: /etc/fstab needs to
          up created so that root2 mounts home2 and var2, while root3 mounte
          home3 etc.  The logs in /var/logs should relate to the system
          running. It would be confusing if they were logs from a totally
          different "system" Things like /dev, /sys, /proc are not really stored
          on disk they simply views into the running system, they "appear" to be
          regenerated (but that's not what really happens).

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

       Before using this script you need to initialise the disk (fdisk, parted
       etc) in the NAS or in another computer. This is to ensure we don't
       destroy data. You should specify a GPT label. Then you need to commision
       each drive using QNAP_commision_disk.sh.
       
       A commisioned drive will contain the following:

       Partition No    Mounted as  typical label      Cloned?
       #1   	       /boot   	   boot5   	      Yes
       #2   	       root (/)	   root5	      Yes (but updated)
       #5   	       /var 	   var5		      Partially (not log for example)
       #6   	       SWAP	   swap5	      No
       #7   	       /tmp	   tmp5		      No
       #8   	       /home	   home5	      Yes
       #9   	       /data	   data5	      No
       #10  	       /rest	   rest5	      No
       
       You don't need to use GPT. You DO need to ensure the minimal filesystems
       (marked Yes or Partly above) exist and, most importantly, that the labels
       are correct.

EOF
}


#
# Ensure other mounts of this fileystem are dropped.
#
AKA() {
    dev="$1"
    while read mount akadev fstype options 
    do
	rc=$?

	if [[ ${rc} -eq 0 ]] ; then
	    echo "$dev is already mounted as $mount [ $akadev ] ... umount forced" >&2
	    umount -f ${mount}
	fi
    done < <(findmnt -n ${dev})
}



typeset -i version
typeset -i verbose
typeset -i quiet

bootorder=X
version=0
verbose=0
quiet=0
PROG=$0
CMD="$@"
ARGS=`getopt -o "Vhqvb:" -l "version,help,quiet,verbose,bootorder:" -n "${PROG}" -- "$@"`

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

if [[ $# -ne 0 ]] ; then
    usage ${PROG}
    exit 1
fi


if [[ ${version} -gt 0 ]] ; then
    echo "${PROG} VERSION=${VERSION}" >&2
    exit 0
fi



if [[ ${bootorder} == "X" ]] ; then
    echo "You must specify -b to determine which drive we write to" >&2
    usage ${PROG}
    exit 1
fi

b=${bootorder}

DEV=/dev/disk/by-label/root${b}



if [[ ${verbose} -gt 0 ]] ; then
    echo "Verbose mode enabled VERSION=${VERSION}" >&2
fi

if [[ ! -b ${DEV} ]] ; then
    echo "${DEV} is not a block device...maybe it's not installed? or failed to spin up?" >&2
    exit 1
fi

# Determine OUR boot number (ugly)

x=$(df /)
ourbootnumber=$(echo ${x} | sed "s/.*by-label\/[a-z]*\([0-9]\).*/\1/")

# We can't copy to ourselves
if [[ ${bootorder} -eq ${ourbootnumber} ]] ; then
    echo "Hang on, we are booted with root${ourbootnumber} so we can't copy to root${bootorder}" >&2
    exit 3
fi

# $DEV is /root, so partition #2 (normally)
devname=$(readlink ${DEV})
base=$(basename ${devname})
dir=$(dirname ${devname})

typeset -a lookup
lookup=("zero" "sda2" "sdb2" "sdc2" "sdd2" "sde2") # Starts at tray1=boot1 (we don't use boot0 ...but you could)
expected=${lookup[$b]}

if [[ ${base} == ${expected} && ${dir} == "../.." ]] ; then
    echo "Clone is going to ${devname} , this is as expected"
else
    echo "WARNING Clone is going to ${devname} , this is as unexpected (you may have chosen irregular mappings)"
fi


if [[ ${verbose} -gt 0 ]] ; then
    cat >&2 <<EOF
        Will clone from the existing system (root${ourbootnumber}) to ${DEV} (and its related fileystems)
	This is what we are running right now:
EOF
    uname -a
    echo -e "\n\n"
    cat /etc/os-release
    echo -e "\n\n"
    df -h
fi


if [[ $(id -u) -ne 0 ]] ; then
    echo "You are $(id -un) you need to su or sudo to root before running this" >&2
    usage $0
    exit 2
fi

mkdir -p /run/QNAPHomebrew/boot
mkdir -p /run/QNAPHomebrew/root
mkdir -p /run/QNAPHomebrew/var
mkdir -p /run/QNAPHomebrew/home

mkdir -p /var/log/QNAPHomebrew

if [[ ${quiet} -gt 0 ]] ; then
    echo "Quiet mode enabled ... going ahead with drive ${bootorder}" >&2
else
    echo "Last chance to bail out --- press enter to continue" >&2
    read reply
fi
      


cd /var/log/QNAPHomebrew


#---- BOOT ------------------------------------------------------

if [[ ${verbose} -gt 0 ]] ; then
    echo -e "\n\nBOOT:"
fi

d=BOOT    # Don't make sparse files, do delete files not in source
from=/boot/.
to=/run/QNAPHomebrew/boot

set +e
umount -q /run/QNAPHomebrew/boot
AKA   "/dev/disk/by-label/boot${b} /run/QNAPHomebrew/boot"
mount /dev/disk/by-label/boot${b} /run/QNAPHomebrew/boot
set -e

rsync -aHAX --one-file-system --log-file=QNAP_clone.${d}.${b}.log  --super  --delete  ${from}  ${to} 2>QNAP_clone.${d}.${b}.errs
echo "$d Cloned from ${ourbootnumber} using [$PROG $CMD] at $(date)" > ${to}/@CLONED



#---- ROOT ------------------------------------------------------

if [[ ${verbose} -gt 0 ]] ; then
    echo -e "\n\nROOT:"
fi



set +e
# These SHOULD fail, but just in case they were left over from a previous run
umount -q "/dev/disk/by-label/root${b}"
# If fileystems is mounted elsewhere, it causes our mount to be read-only and so rsync fails
AKA   "/dev/disk/by-label/bootfs${b}"
mount /dev/disk/by-label/root${b} /run/QNAPHomebrew/root
set -e


d=ROOT    # Make sparse files, do delete files not in source
from=/.
to=/run/QNAPHomebrew/root

rsync -aHAXS --one-file-system --log-file=QNAP_clone.${d}.${b}.log  --super  --delete  ${from}  ${to} 2>QNAP_clone.${d}.${b}.errs
echo "$d Cloned from ${ourbootnumber} using [$PROG $CMD] at $(date)" > ${to}/@CLONED

# Fixup /etc/fstab ...BTW, this is why choosing root3 implies using home3 etc
sed "s/LABEL=\([a-z]*\)[0-9]/LABEL=\1${b}/"  /etc/fstab  > /run/QNAPHomebrew/root/etc/fstab

# Stop Hibernate/Resume from working (alternatively put the correct UUID)
# My existing contents of /etc/initramfs-tools/conf.d/resume was (single line):
# RESUME=UUID=9f4d1dae-eb75-4d30-8914-9864f6476a03
# Alternate solution
# echo "RESUME=UUID=$(lsblk -n -o UUID /dev/disk/by-label/root${b})"  > /run/QNAPHomebrew/root/etc/initramfs-tools/conf.d/resume 
echo "RESUME=NONE"  > /run/QNAPHomebrew/root/etc/initramfs-tools/conf.d/resume 

#---- VAR ------------------------------------------------------

if [[ ${verbose} -gt 0 ]] ; then
    echo -e "\n\nVAR:"
fi

set +e
umount -q /run/QNAPHomebrew/var
AKA   "/dev/disk/by-label/var${b}"
mount /dev/disk/by-label/var${b}  /run/QNAPHomebrew/var
set -e

d=VAR    # Make sparse files, Don't copy /var/log, do delete files not in source, but don't delete excluded files (/var/log should remain)
from=/var/.
to=/run/QNAPHomebrew/var

rsync -aHAXS --one-file-system --log-file=QNAP_clone.${d}.${b}.log  --super --exclude=/log --delete  ${from}  ${to} 2>QNAP_clone.${d}.${b}.errs
echo "$d Cloned from ${ourbootnumber} using [$PROG $CMD] at $(date)" > ${to}/@CLONED



#---- HOME ------------------------------------------------------

if [[ ${verbose} -gt 0 ]] ; then
    echo -e "\n\nHOME:"
fi

set +e
umount -q /run/QNAPHomebrew/home
AKA   "/dev/disk/by-label/home${b}"
mount /dev/disk/by-label/home${b} /run/QNAPHomebrew/home
set -e

d=HOME    # Make sparse files, do delete files not in source
from=/home/.
to=/run/QNAPHomebrew/home

rsync -aHAXS --one-file-system --log-file=QNAP_clone.${d}.${b}.log  --super  --delete  ${from}  ${to} 2>QNAP_clone.${d}.${b}.errs
echo "$d Cloned from ${ourbootnumber} using [$PROG $CMD] at $(date)" > ${to}/@CLONED



umount /run/QNAPHomebrew/boot
umount /run/QNAPHomebrew/root
umount /run/QNAPHomebrew/var
umount /run/QNAPHomebrew/home
