#!/bin/bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Audit Manager

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
EOF
  exit
}

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
    --no-color) NO_COLOR=1 ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}



# Function to search audit events
search_audit_events() {
    read -p "Enter the event type: " event_type
    read -p "Enter the username (leave empty for any user): " username
    read -p "Enter the search string: " search_string

    # Argument is required for -ui, so
    # if username is empty, set it to '*'
    if [ -z "$username" ]; then
        ausearch -ts today -m "$event_type" -k "$search_string" || true
    else
        ausearch -ts today -m "$event_type" -ui "$username" -k "$search_string" || true
    fi
}

# Function to generate audit reports
generate_audit_reports() {
    read -p "Enter the report period (1d, 1w, 1m, 1y): " report_period

    case $report_period in
        1d)
            aureport --start today --end today || true ;;
        1w)
            aureport --start 'this-week' || true ;;
        1m)
            aureport --start 'this-month' || true ;;
        1y)
            aureport --start 'this-year' || true ;;
        *)
            echo "Invalid report period." || true ;;
    esac
}

# Function to configure file monitoring
configure_file_monitoring() {
    read -p "Enter 'add' to add a directory or file, 'remove' to remove a directory: " action

    case $action in
        add)
            read -p "Enter the path of the directory or file to monitor: " path
            auditctl -w "$path" -p wa || true ;;
        remove)
            read -p "Enter the path of the directory to stop monitoring: " path
            auditctl -W "$path" || true ;;
        *)
            echo "Invalid action." ;;
    esac
}

check_root() {
    if [ $EUID -ne 0 ]; then
        echo "This script must be run as root"
        exit 1
    fi
}

parse_params "$@"

check_root

while true; do
    echo "----- Security Event Management -----"
    echo "1. Search Audit Events"
    echo "2. Generate Audit Reports"
    echo "3. Configure File Monitoring"
    echo "4. Exit"
    read -p "Enter your choice (1-4): " choice

    case $choice in
        1)
            echo "----- Search Audit Events -----"
            search_audit_events ;;
        2)
            echo "----- Generate Audit Reports -----"
            generate_audit_reports ;;
        3)
            echo "----- Configure File Monitoring -----"
            configure_file_monitoring ;;
        4)
            echo "Exiting..."
            exit 0 ;;
        *)
            echo "Invalid choice. Please try again." ;;
    esac

    echo # Empty line for readability
done
