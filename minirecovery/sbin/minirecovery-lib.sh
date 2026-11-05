# Shared helpers for the sk1wg mini recovery scripts. Source it, don't run it.

# /dev/block/by-name/<NAME> -> /dev/mmcblk0pN, from the GPT names in sysfs.
make_by_name_links() {
    mkdir -p /dev/block/by-name
    for p in /sys/block/mmcblk0/mmcblk0p*; do
        n=${p##*/}
        name=$(sed -n 's/^PARTNAME=//p' "$p/uevent")
        [ -n "$name" ] && ln -sf "/dev/$n" "/dev/block/by-name/$name"
    done
}
