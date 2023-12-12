#! /bin/bash -ue

echo "args to $0 $@"  > /var/log/flash-kernel
count_flash_attempts    # Count how mnay were tried (timestmap also denotes when)
construct_dl_image	# Make an image suitable for diskless(flashless) boot

exit 0

