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

search_service() {
  read -p "Enter a partial name or the name of a service: " service_name
  systemctl list-units --all --type=service --no-pager --no-legend | grep "$service_name"
}

display_processes_with_services() {
  ps -e -o "%p|%c|" -o unit | awk -F$'|' '$3 ~ ".*[.]service" && $3 != "user@1000.service"'
}

enable_service() {
  read -p "Enter the name of the service to enable: " service_name
  systemctl enable "$service_name" || true
}

disable_service() {
  read -p "Enter the name of the service to disable: " service_name
  systemctl disable "$service_name" || true
}

start_restart_service() {
  read -p "Enter the name of the service to start/restart: " service_name
  systemctl restart "$service_name" || true
}

stop_service() {
  read -p "Enter the name of the service to stop: " service_name
  systemctl stop "$service_name" || true
}

display_unit_file_contents() {
  read -p "Enter the name of the service to display unit file contents: " service_name
  systemctl cat "$service_name" || true
}

edit_unit_file() {
  read -p "Enter the name of the service to edit unit file: " service_name
  systemctl edit "$service_name" || true
}

service_menu() {
  while true; do
    internal_service_menu
  done
}

internal_service_menu() {
  cat <<EOF
Service Management

1) Enable Service
2) Disable Service
3) Start/Restart Service
4) Stop Service
5) Display Unit File Contents
6) Edit Unit File
7) Back to Main Menu
EOF
  read -p "[1-7] > " option

  case $option in
  1) enable_service ;;
  2) disable_service ;;
  3) start_restart_service ;;
  4) stop_service ;;
  5) display_unit_file_contents ;;
  6) edit_unit_file ;;
  7) main_menu ;;
  *) echo "Invalid option" ;;
  esac
}

journal_menu() {
  while true; do
    internal_journal_menu
  done
}

internal_journal_menu() {
  cat <<EOF
Event Search in the Journal

1) Search by Service Name
2) Search by Severity Level
3) Search by String
4) Back to Main Menu
EOF
  read -p "[1-4] > " option

  case $option in
  1) search_by_service_name ;;
  2) search_by_severity_level ;;
  3) search_by_string ;;
  4) main_menu ;;
  *) echo "Invalid option" ;;
  esac
}

search_by_service_name() {
  read -p "Enter the name of the service (leave blank for any service): " service_name
  # lol, exiting less without reading the whole thing results in a non-zero exit code, 
  # avoiding that
  journalctl -u "$service_name" || true
}

search_by_severity_level() {
  # weird shortening of the severity levels, but whatever
  read -p "Enter the severity level (emerg, alert, crit, err, warning, notice, info, debug): " severity_level
  journalctl -p "$severity_level" || true
}

search_by_string() {
  read -p "Enter the search string: " search_string
  journalctl -g "$search_string" || true
}

main_menu() {
  cat <<EOF
Main Menu

1) System Service Search
2) Display Processes with Services
3) Service Management
4) Event Search in the Journal
5) Quit
EOF
  read -p "[1-5] > " option

  case $option in
  1) search_service ;;
  2) display_processes_with_services ;;
  3) service_menu ;;
  4) journal_menu ;;
  5) cleanup ;;
  *) echo "Invalid option" ;;
  esac
}

parse_params "$@"

main() {
    check_root
    while true; do
        main_menu
    done
}

main