#! /bin/bash -ue
# VERSION 1.0
: ${DIR:=/var/opt/homebrew}
: ${HOMEBREW:=/var/opt/homebrew}

# Use dl_flash_kernel.sh to make mtd1 amd mtd2 in /var/opt/homebrew/

dl_flash_kernel "$@"

if [[ $? -ne 0 ]] ; then
    echo "Something when wrong making mtd1 and mtd2, check for errors above .. bailing" >&2
    exit 2
fi

while [[  $# -gt 0 &&  $1 =~ ^-  ]]
do
    shift  # ignore flags in the args (they were just for dl_flash_kernel)
done

if [[ $# -gt 0 ]] ; then
    kvers=$1
else
    echo "Latest version"
    kvers=$(linux-version list | linux-version sort | tail -1)
fi

# make e.g. dl-F_TS-412-MOUICHE_BOOKWORM_6.1.0-13-marvell (suitable for diskless/flashless boot)

. /etc/os-release 
echo $VERSION_CODENAME

NAME="dl-F_TS-412-MOUICHE_${VERSION_CODENAME}_${kvers}"


TARGET=${DIR}/${NAME}


K_FILE=${HOMEBREW}/mtd1
I_FILE=${HOMEBREW}/mtd2

typeset -i k_size
typeset -i i_size

typeset -i k_limit
typeset -i i_limit

k_size=$(stat -c %s ${K_FILE})
i_size=$(stat -c %s ${I_FILE})

let k_limit=3*1024*1024
let i_limit=12*1024*1024   # Good reasons for this to be 11 (allowing PiXE to work)

typeset -i fail
fail=0

if [[ k_size -gt k_limit ]] ; then
    echo "Kernel is too big limit is ${k_limit} bytes; ${K_FILE} is ${k_size} bytes" >&2
    fail=1
fi
if [[ i_size -gt i_limit ]] ; then
    echo "Initrd is too big limit is ${i_limit} bytes; ${I_FILE} is ${i_size} bytes" >&2
    fail=1
fi

if [[ fail -gt 0 ]] ; then
    echo "No dl- image has been created." >&2
    exit 2
fi

dd if=/dev/zero of=${TARGET}  bs=1M count=15   # file with block of zeros

dd if=${K_FILE} of=${TARGET}  bs=1M conv=nocreat,notrunc  # Kernel at the start (compressed bzimage)
dd if=${I_FILE} of=${TARGET}  bs=1M conv=nocreat oseek=3  # initrd (compressed) starts 3MB in (truncate is OK)


exit 0
