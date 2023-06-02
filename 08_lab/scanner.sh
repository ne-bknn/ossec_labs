#!/usr/bin/env bash

# Function to check if a file has write permissions for a different user
check_file_permissions() {
  local file="$1"
  local user="$2"

  # Check owner's write permission
  if [[ -w "$file" && $(stat -c '%U' "$file") != "$user" ]]; then
    return 1
  fi

  # Check group's write permission
  if [[ -w "$file" && $(stat -c '%G' "$file") != "$user" ]]; then
    return 1
  fi

  # Check ACL permissions
  if getfacl -p "$file" | grep -q "other:$user:w"; then
    return 1
  fi

  return 0
}

# Function to check if a service runs a SUID executable owned by root
check_suid_executable() {
  local service="$1"
  local suid_executable

  # Get the SUID executable path from the service unit file
  suid_executable=$(systemctl show -p ExecStart --value "$service" | awk '{print $1}')

  # Check if the SUID executable exists and is owned by root
  if [[ -n "$suid_executable" && -x "$suid_executable" && $(stat -c '%U' "$suid_executable") == "root" ]]; then
    return 0
  fi

  return 1
}

# Function to scan services for security violations
scan_services() {
  local services=($(systemctl list-unit-files --type=service --state=enabled --no-pager --no-legend | awk '{print $1}'))

  for service in "${services[@]}"; do
    echo "Checking service: $service"
    # Get the user under which the service runs
    user=$(systemctl show -p User --value "$service")

    # Check file permissions for the unit file
    unit_file=$(systemctl show -p FragmentPath --value "$service")
    if check_file_permissions "$unit_file" "$user"; then
      echo "Violation: Service '$service' has insecure file permissions for the unit file: $unit_file"
    fi

    # Check file permissions for files launched by the service
    files_launched=$(systemctl show -p ExecStart --value "$service" | awk '{print $2}' | sed 's/path=//g')
    for file in $files_launched; do
      if check_file_permissions "$file" "$user"; then
        echo "Violation: Service '$service' has insecure file permissions for the launched file: $file"
      fi
    done

    # Check if the service runs a SUID executable owned by root
    if check_suid_executable "$service"; then
      echo "Violation: Service '$service' runs a SUID executable owned by root"
    fi
  done
}

# Run the security scan
scan_services
