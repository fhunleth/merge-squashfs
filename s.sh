#!/bin/bash

set -e

perm_to_num() {
    case $1 in
        ?rwsr-xr-x) echo "4755" ;;
        ?rws--x--x) echo "4711" ;;
        ?rwxrwxrwt) echo "1777" ;;
        ?rwxrwxrwx) echo "777" ;;
        ?rwxr-xr-x) echo "755" ;;
        ?rwx------) echo "700" ;;
        ?rw-rw-rw-) echo "666" ;;
        ?rw-r--r--) echo "644" ;;
        ?rw--w--w-) echo "622" ;;
        ?rw-------) echo "600" ;;
        ?r--r--r--) echo "444" ;;
        ?r--------) echo "400" ;;
        *) echo "huh"
    esac
}

owner_to_uid_gid() {
    echo $1 | sed -e "s/\// /g"
}

get_path() {
    echo $1 | sed -e 's/squashfs-root//'
}

char_device_file() {
    echo "$(get_path $7) c $(perm_to_num $1) $(owner_to_uid_gid $2) $(echo $3 | sed -e 's/,//g') $4"
}

block_device_file() {
    echo "$(get_path $7) b $(perm_to_num $1) $(owner_to_uid_gid $2) $(echo $3 | sed -e 's/,//g') $4"
}

symlink_file() {
    # symlinks are the handled the same as files currently.
    echo "$(get_path $6) m $(perm_to_num $1) $(owner_to_uid_gid $2)"
}

directory_file() {
    pathname=$(get_path $6)
    # mksquashfs doesn't support setting permissions and ownership
    # on the root directory
    if [[ ! -z $pathname ]]; then
        echo "$pathname m $(perm_to_num $1) $(owner_to_uid_gid $2)"
    fi
}

regular_file() {
    echo "$(get_path $6) m $(perm_to_num $1) $(owner_to_uid_gid $2)"
}

while read perms owner rest; do
    case $perms in
        c*)
            char_device_file $perms $owner $rest
            ;;
        b*)
            block_device_file $perms $owner $rest
            ;;
        l*)
            symlink_file $perms $owner $rest
            ;;
        d*)
            directory_file $perms $owner $rest
            ;;
        -*)
            regular_file $perms $owner $rest
            ;;
        *)
    esac
done < <(unsquashfs -n -ll rootfs.squashfs)

