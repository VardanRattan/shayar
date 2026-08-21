#!/usr/bin/env bash
set -euo pipefail

# This script provides a central control for managing various background listener scripts.
# It allows starting, stopping, and restarting individual listeners or all registered listeners.

# Define an associative array to store listener names and their full paths.
# Add more listeners here as needed, following the format:
# LISTENERS["short-name"]="full/path/to/script.sh"
declare -A LISTENERS
LISTENERS["low-bat-notification"]="$HOME/.config/shayar/listeners/low-bat-notification.sh"

# Function to start a specific listener script
start_listener() {
    local script_name="$1"
    local init_flag="${2:-}" # New argument for initialization flag
    local script_path="${LISTENERS[$script_name]}"

    if [ -z "$script_path" ]; then
        echo "Error: Listener '$script_name' is not registered."
        return 1
    fi

    echo "Attempting to start '$script_name'..."

    # Check if the script file exists and is executable
    if [ ! -f "$script_path" ]; then
        echo "Error: Script file '$script_path' not found for '$script_name'."
        return 1
    fi
    if [ ! -x "$script_path" ]; then
        echo "Error: Script file '$script_path' is not executable. Please run 'chmod +x \"$script_path\"'."
        return 1
    fi

    # Check if the script is already running
    if pgrep -f "$script_path" >/dev/null; then
        echo "Listener '$script_name' is already running (PID: $(pgrep -f "$script_path"))."
        return 0
    fi

    # Start the script in the background using nohup to detach it from the terminal
    # Redirect stdout and stderr to /dev/null to prevent nohup.out files
    nohup "$script_path" "$init_flag" >/dev/null 2>&1 &
    echo "Listener '$script_name' started successfully."
}

# Function to stop a specific listener script
stop_listener() {
    local script_name="$1"
    local script_path="${LISTENERS[$script_name]}"

    if [ -z "$script_path" ]; then
        echo "Error: Listener '$script_name' is not registered."
        return 1
    fi

    # Find the PID of the running script
    local pid=$(pgrep -f "$script_path" || true)

    if [ -z "$pid" ]; then
        echo "Listener '$script_name' is not running."
        return 0
    else
        echo "Found PID(s) for '$script_name': $pid. Sending SIGTERM..."
        kill "$pid" 2>/dev/null || true
        # Fast poll up to 100ms for graceful shutdown
        local count=0
        while pgrep -f "$script_path" >/dev/null 2>&1 && [ $count -lt 5 ]; do
            sleep 0.02
            count=$((count + 1))
        done
        if pgrep -f "$script_path" >/dev/null 2>&1; then
            echo "Listener '$script_name' did not stop gracefully. Sending SIGKILL..."
            kill -9 "$pid" 2>/dev/null || true
            echo "Listener '$script_name' forcefully stopped."
        else
            echo "Listener '$script_name' stopped successfully."
        fi
    fi
}

# Function to restart a specific listener script
restart_listener() {
    local script_name="$1"
    stop_listener "$script_name"
    start_listener "$script_name"
}

# Main script logic based on command-line arguments
case "${1:-}" in
--startall)
    echo "Starting all registered listeners..."
    for key in "${!LISTENERS[@]}"; do
        start_listener "$key"
    done
    echo "All registered listeners processed."
    ;;
--stopall)
    echo "Stopping all registered listeners..."
    for key in "${!LISTENERS[@]}"; do
        stop_listener "$key"
    done
    echo "All registered listeners processed."
    ;;
--restartall)
    echo "Restarting all registered listeners..."
    for key in "${!LISTENERS[@]}"; do
        restart_listener "$key"
    done
    echo "All registered listeners processed."
    ;;
--start)
    if [ -z "${2:-}" ]; then
        echo "Error: Missing listener name for --start option."
        echo "Usage: $0 --start <listener_name>"
        exit 1
    fi
    start_listener "$2"
    ;;
--stop)
    if [ -z "${2:-}" ]; then
        echo "Error: Missing listener name for --stop option."
        echo "Usage: $0 --stop <listener_name>"
        exit 1
    fi
    stop_listener "$2"
    ;;
--restart)
    if [ -z "${2:-}" ]; then
        echo "Error: Missing listener name for --restart option."
        echo "Usage: $0 --restart <listener_name>"
        exit 1
    fi
    restart_listener "$2"
    ;;
*)
    echo "Usage: $0 [--startall | --stopall | --restartall | --startall-init | --start <listener_name> | --stop <listener_name> | --restart <listener_name> | --start-init <listener_name>]"
    echo ""
    echo "Registered listeners:"
    for key in "${!LISTENERS[@]}"; do
        echo "  - $key"
    done
    exit 1
    ;;
esac
