#! /bin/bash


#
# Mounts the "USER DATA" of the NAS. Not the OS related stuff. We
# specifically DON'T do this in /etc/fstab as we want to come up clean
# even if some drives are unavailable/ Missing file-systems used in /etc/fstab
# would drop us into the emergency shell.
#



# Where do we put these:

# $ /sbin/showmount -e nas
# Export list for nas:
# /svn           *  17  Mb
# /homes         * 615  Gb  **
# /git           * 547  Mb
# /Web           * 56   Kb
# /USBUploads    * 76   Kb
# /Recordings    * 44   Kb
# /Public        * 667  Gb  **
# /Multimedia    * 2.62 Tb  **
# /InternalAdmin * 39.5 Mb
# /Download      * 126  Mb

# Given we have:

# LC_ALL=C lsblk (elided)
# NAME    MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
# 
# |-sda9    8:9    0   512G  0 part  
# | `-md0   9:0    0   1.5T  0 raid5 
# `-sda10   8:10   0 379.4G  0 part  
# 
# |-sdb9    8:25   0   512G  0 part  
# | `-md0   9:0    0   1.5T  0 raid5 
# `-sdb10   8:26   0 845.2G  0 part  
# 
# |-sdc9    8:41   0   512G  0 part  
# | `-md0   9:0    0   1.5T  0 raid5 
# `-sdc10   8:42   0   3.1T  0 part  
# 
# |-sdd9    8:57   0   512G  0 part  
# | `-md0   9:0    0   1.5T  0 raid5 
# `-sdd10   8:58   0 845.2G  0 part  
# 
#  SD[abcd]9 is being used to make a raid array (md0)
# 
#  rest1 = SDA10 -  379.4G  0 part  
#  rest2 = SDB10 -  845.2G  0 part  - Public
#  rest3 = SDC10 -  3.1T    0 part  - Multimedia (Obviously)
#  rest4 = SDD10 -  845.2G  0 part  - svn git Web USBUploads Recordings InternalAdmin Download
#  raid  = MD0   -  1.5T            - homes

#export_flags="*(rw,sync,wdelay,hide,nocrossmnt,secure,root_squash,no_all_squash,no_subtree_check,secure_locks,acl,no_pnfs,anonuid=65534,anongid=65534,sec=sys,rw,secure,root_squash,no_all_squash)"

export_flags="*"
options='-o rw,no_root_squash'

function do_nonraid() {
    mount=$1; shift

    mkdir -p /QNAP/mounts/${mount}
    mount /dev/disk/by-label/${mount}  /QNAP/mounts/${mount}

    for d in $@
    do
	mkdir -p       /QNAP/mounts/${mount}/${d}  /${d}
	mount -o bind  /QNAP/mounts/${mount}/${d}  /${d}
	ln -fs -T      /QNAP/mounts/${mount}/${d}  /share/${d}
	exportfs      ${options}  "${export_flags}:/${d}"
    done
    }


function do_raid() {
    mount=$1; shift
    mkdir -p /QNAP/mounts/${mount}
    mount /dev/${mount}  /QNAP/mounts/${mount}
    
    for d in $@
    do
	mkdir -p       /QNAP/mounts/${mount}/${d}  /${d}
	mount -o bind  /QNAP/mounts/${mount}/${d}  /${d}
	ln -fs -T      /QNAP/mounts/${mount}/${d}  /share/${d}
	exportfs       ${options} "${export_flags}:/${d}"
    done
    }

REST1=""
REST2="Public"
REST3="Multimedia"
REST4="svn git Web USBUploads Recordings InternalAdmin Download"
RAID0="homes"

# Non-raid shares
do_nonraid rest1 ${REST1}
do_nonraid rest2 ${REST2}
do_nonraid rest3 ${REST3}
do_nonraid rest4 ${REST4}

# Actually its is in the usual place, fought long and hard to keep mdadm(8) stuff off initrd
# Gave up , now it gets assemebed on initrd (slowing boot and meaning you need to reflash
# more frequently. (/etc/mdadm/mdadm.conf)
# Not in the usual place (we don't want this visible at boot)
# mdadm  --assemble --scan --config /etc/QNAP-mdadm.conf


state=$(mdadm -D /dev/md0 | grep "State  *:")

if [[ ${state} =~ .*degraded.* ]] ; then
    echo "Warning the array md0 is running degraded" >&2
    echo "use mdadm -D /dev/md0, cat /proc/mdstat, then mdadm -a /dev/xxxx /dev/md0 to recover" >&2
fi

# Raid share(s)
do_raid md0 ${RAID0}

systemctl start QNAP_manage_disks # Make the disks spindown after 1 hour unused.
