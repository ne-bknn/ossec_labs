#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Filesystem & mount manager

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
EOF
  exit
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root"
    fi
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  echo >&2 -e "\nExiting..."
  exit 0
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1}
  msg "$msg"
  exit "$code"
}

parse_params() {
  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}


calculate_column_widths() {
    local data=("$@")
    local num_columns
    num_columns=$(echo "${data[0]}" | tr '|' '\n' | wc -l)

    # Initialize column widths to 0
    for ((i=0; i<num_columns; i++)); do
        column_widths[i]=0
    done

    # Find the maximum width for each column
    for row in "${data[@]}"; do
        IFS='|' read -r -a fields <<< "$row"
        for ((i=0; i<num_columns; i++)); do
            field_length=${#fields[$i]}
            if ((field_length > column_widths[i])); then
                column_widths[i]=$field_length
            fi
        done
    done
}

print_table() {
    local data=("$@")

    for row in "${data[@]}"; do
        IFS='|' read -r -a fields <<< "$row"
        for ((i=0; i<${#fields[@]}; i++)); do
            field="${fields[$i]}"
            width="${column_widths[$i]}"
            printf "| %-*s " "$width" "$field"
        done
        printf "|\n"
    done
}


table() {
    local data=("$@")
    calculate_column_widths "${data[@]}"
    print_table "${data[@]}"
}


main_menu() {
    cat <<EOF
Main Menu

1) Show filesystems
2) Mount filesystem
3) Unmount filesystem
4) Change filesystem options
5) Show filesystem options
6) Show detailed ext* filesystem info
7) Exit
EOF
   read -p "[1-7] > " option

   case $option in
        1) show_filesystems_menu ;;
        2) mount_filesystem ;;
        3) unmount_filesystem ;;
        4) change_filesystem_options ;;
        5) show_filesystem_options ;;
        6) show_ext_filesystem_info ;;
        7) exit 0 ;;
        *) echo "Invalid option" ;;
   esac
}

show_filesystems_menu() {
    show_filesystems
    read -p "Press enter to continue"
}

show_filesystems() {
    devices=$(lsblk -o KNAME --paths | tail -n +2)

    filesystems=()

    for device in $devices; do
        mntpoint=$(lsblk -o MOUNTPOINT --nodeps --paths $device | tail -n +2)
        if [[ -z $mntpoint ]]; then
            continue
        fi

        if [ "$mntpoint" == "[SWAP]" ]; then
            continue
        fi

        filesystem=$(lsblk -o FSTYPE --paths "$device" | tail -n +2)
        filesystems+=("$device|$mntpoint|$filesystem")
    done

    table "${filesystems[@]}"
}

is_file() {
    stat -c "%F" "$1" | grep -q "regular file"
}

is_dir() {
    stat -c "%F" "$1" | grep -q "directory"
}

is_block_device() {
    stat -c "%F" "$1" | grep -q "block special file"
}

exists() {
    if [ -e "$1" ]; then
        return 0
    else
        return 1
    fi
}

mount_filesystem() {
    read -p "Enter filesystem to mount: " filesystem

    if ! exists "$filesystem"; then
        echo "Filesystem does not exist"
        read -p "Press enter to continue"
        return
    fi

    read -p "Enter mount point: " mount_point

    if exists "$mount_point" && ! is_dir "$mount_point"; then
        echo "Mount point is not a directory"
        read -p "Press enter to continue"
        return
    fi

    if ! exists "$mount_point"; then
        mkdir -p "$mount_point"
    fi

    if is_block_device "$filesystem"; then
        if mount "$filesystem" "$mount_point"; then
            msg "Mounted $filesystem on $mount_point"
            read -p "Press enter to continue"
            return
        else
            echo "Failed to mount $filesystem on $mount_point"
            read -p "Press enter to continue"
            return
        fi
    fi

    if is_file "$filesystem"; then
        if mount -o loop "$filesystem" "$mount_point"; then
            msg "Mounted $filesystem on $mount_point"
            read -p "Press enter to continue"
            return
        else
            echo "Failed to mount $filesystem on $mount_point"
            read -p "Press enter to continue"
            return
        fi
        return
    fi
}

unmount_filesystem() {
    fs=$(show_filesystems)
    nl -s ') ' -w 2 <(echo "$fs")
    read -p "Select filesystem to unmount: " option
    n_lines=$(echo "$fs" | wc -l)
    if [ "$option" -gt "$n_lines" ]; then
        echo "Invalid option"
        read -p "Press enter to continue"
        return
    fi
    filesystem=$(echo "$fs" | sed -n "$option"p | awk -F'|' '{print $2}')

    if umount "$filesystem"; then
        msg "Unmounted $filesystem"
        read -p "Press enter to continue"
        return
    else
        echo "Failed to unmount $filesystem"
        read -p "Press enter to continue"
        return
    fi
}

change_filesystem_options() {
    fs=$(show_filesystems)
    nl -s ') ' -w 2 <(echo "$fs")
    read -p "Select filesystem to remount: " option
    n_lines=$(echo "$fs" | wc -l)
    if [ "$option" -gt "$n_lines" ]; then
        echo "Invalid option"
        read -p "Press enter to continue"
        return
    fi
    filesystem=$(echo "$fs" | sed -n "$option"p | awk -F'|' '{print $2}')

    cat <<EOF
1) Remount read-only
2) Remount read-write
EOF
    read -p "[1-2] > " option

    case $option in
        1) mount -o remount,ro "$filesystem" && msg "Successfully remounted ro" || msg "Failed to remount ro";;
        2) mount -o remount,rw "$filesystem" && msg "Successfully remounted rw" || msg "Failed to remount rw";;
        *) echo "Invalid option" ;;
    esac
    
    read -p "Press enter to continue"
}

show_filesystem_options() {
    fs=$(show_filesystems)
    nl -s ') ' -w 2 <(echo "$fs")
    read -p "Select filesystem to get options: " option
    n_lines=$(echo "$fs" | wc -l)
    if [ "$option" -gt "$n_lines" ]; then
        echo "Invalid option"
        read -p "Press enter to continue"
        return
    fi
    filesystem=$(echo "$fs" | sed -n "$option"p | awk -F'|' '{print $2}')

    echo "Options for $filesystem: $(findmnt -no OPTIONS "$filesystem")"
    read -p "Press enter to continue"
}

show_ext_filesystem_info() {
    fs=$(show_filesystems)
    nl -s ') ' -w 2 <(echo "$fs")
    read -p "Select filesystem to get options: " option
    n_lines=$(echo "$fs" | wc -l)
    if [ "$option" -gt "$n_lines" ]; then
        echo "Invalid option"
        read -p "Press enter to continue"
        return
    fi
    filesystem=$(echo "$fs" | sed -n "$option"p | awk -F'|' '{print $2}')

    dumpe2fs "$filesystem"
    read -p "Press enter to continue"
}

declare -a column_widths

main() {
    check_root
    while true; do
        main_menu
    done
}

parse_params "$@"

main