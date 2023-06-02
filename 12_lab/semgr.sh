#!/bin/bash

check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root"
    fi
}

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

SELinux manager

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
EOF
    exit
}

trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    echo >&2 -e "\nExiting..."
    exit 0
}

parse_params() {
    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    return 0
}

# Function to check the exit status of a command
check_status() {
    if [ $1 -eq 0 ]; then
        echo "$2"
    else
        echo "$3"
    fi
}

# Function to manage service ports
manage_ports() {
    local service=$1
    while true; do
        echo "Choose an operation for the ports of service: $service"
        echo "1. Add a new service port"
        echo "2. Delete a service port"
        echo "3. Modify an existing service port"
        echo "4. Help"
        echo "5. Back"
        read -p "Enter your choice: " choice
        case $choice in
            1)
                read -p "Enter the new port number: " port
                semanage port -a -t "$service" -p tcp "$port"
                check_status $? "Port added" "Error adding port"
                ;;
            2)
                read -p "Enter the number corresponding to the desired port: " port_num
                readarray -t ports < <(semanage port -l | grep -E "^$service\s" | awk '{$1=$2=""; print $0}' | sed 's/,/\n/g' | sed 's/\s//g')
                if [ "$port_num" -gt 0 ] && [ "$port_num" -le "${#ports[@]}" ]; then
                    port=${ports[port_num - 1]}
                    semanage port -d -t "$service" -p tcp "$port"
                    check_status $? "Port deleted" "Error deleting port"
                fi
                ;;
            3)
                read -p "Enter the number corresponding to the desired port: " port_num
                readarray -t ports < <(semanage port -l | grep -E "^$service\s" | awk '{$1=$2=""; print $0}' | sed 's/,/\n/g' | sed 's/\s//g')
                if [ "$port_num" -gt 0 ] && [ "$port_num" -le "${#ports[@]}" ]; then
                    port=${ports[port_num - 1]}
                    read -p "Enter the new port number: " new_port
                    semanage port -d -t "$service" -p tcp "$port"
                    check_status $? "Port deleted" "Error deleting port"
                    semanage port -a -t "$service" -p tcp "$new_port"
                    check_status $? "Port modified" "Error modifying port"
                fi
                ;;
            4)
                echo "Choose an operation for the ports of service: $service"
                ;;
            5)
                break
                ;;
            *)
                echo "Invalid choice: $choice"
                ;;
        esac
    done
}

# Function to manage files
manage_files() {
    while true; do
        echo "Choose an operation for file and directory domains"
        echo "1. Relabel a directory"
        echo "2. Trigger a full filesystem relabel on the next reboot"
        echo "3. Change the file or directory domain"
        echo "4. Help"
        echo "5. Back"
        read -p "Enter your choice: " choice
        case $choice in
            1)
                read -e -p "Enter the directory name: " path
                restorecon -Rvv "$path"
                check_status $? "Relabeling completed" "Error relabeling directory"
                ;;
            2)
                touch /.autorelabel
                check_status $? "Filesystem relabel triggered" "Error triggering filesystem relabel"
                ;;
            3)
                read -e -p "Enter the file or directory name: " path
                read -e -p "Enter the new domain: " domain
                chcon "$domain" "$path"
                check_status $? "Domain changed" "Error changing domain"
                ;;
            4)
                echo "Choose an operation for file and directory domains"
                ;;
            5)
                break
                ;;
            *)
                echo "Invalid choice: $choice"
                ;;
        esac
    done
}

# Function to manage switches
manage_switches() {
    while true; do
        echo "Choose an operation for switches"
        echo "1. Enable a switch"
        echo "2. Disable a switch"
        echo "3. Help"
        echo "4. Back"
        read -p "Enter your choice: " choice
        case $choice in
            1)
                read -p "Enter the switch name or part of it: " switch_name
                switches=("switch1" "switch2" "switch3")  # Add actual switches here
                select_switch "$switch_name" "${switches[@]}"
                ;;
            2)
                read -p "Enter the switch name or part of it: " switch_name
                switches=("switch1" "switch2" "switch3")  # Add actual switches here
                select_switch "$switch_name" "${switches[@]}"
                ;;
            3)
                echo "Choose an operation for switches"
                ;;
            4)
                break
                ;;
            *)
                echo "Invalid choice: $choice"
                ;;
        esac
    done
}

# Function to select a switch
select_switch() {
    local switch_name=$1
    shift
    local switches=("$@")
    PS3="Enter the number corresponding to the desired switch: "
    select switch in "${switches[@]}"; do
        case $REPLY in
            [1-9]*)
                if [ "$switch_name" = "" ] || [[ "$switch" == *"$switch_name"* ]]; then
                    break
                fi
                ;;
            *)
                echo "Invalid choice: $REPLY"
                ;;
        esac
    done

    if [ "$switch" != "" ]; then
        case $choice in
            1)
                setsebool -P "$switch" on
                check_status $? "Switch enabled" "Error enabling switch"
                ;;
            2)
                setsebool -P "$switch" off
                check_status $? "Switch disabled" "Error disabling switch"
                ;;
        esac
    fi
}

check_root

parse_params "$@"

# Main menu loop
while true; do
    echo "SELinux Management Script"
    echo
    echo "Options:"
    echo "1. Manage Ports: Add, delete, or modify service ports"
    echo "2. Manage Files: Relabel directories, trigger a filesystem relabel, or change file/directory domains"
    echo "3. Manage Switches: Enable or disable switches"
    echo "4. Help"
    echo "5. Exit"
    echo
    read -p "Enter your choice: " choice
    case $choice in
        1)
            read -p "Enter the service name: " service
            manage_ports "$service"
            ;;
        2)
            manage_files
            ;;
        3)
            manage_switches
            ;;
        4)
            echo
            echo "SELinux Management Script"
            echo "This script provides options to manage various SELinux settings."
            echo "Use the menu to select an operation."
            echo
            ;;
        5)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid choice: $choice"
            ;;
    esac
done

