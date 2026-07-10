#!/usr/bin/env bash
set -euo pipefail
#    ___                    
#   / _ \___ _    _____ ____
#  / ___/ _ \ |/|/ / -_) __/
# /_/   \___/__,__/\__/_/   
#                           

terminate_clients() {
  	TIMEOUT=5
	# Get a list of all client PIDs in the current Hyprland session
	client_pids=$(hyprctl clients -j | jq -r '.[] | .pid')

	# Send SIGTERM (kill -15) to each client PID and wait for termination
	for pid in $client_pids; do
		echo ":: Sending SIGTERM to PID $pid"
		kill -15 "$pid" 2>/dev/null || true
	done

	start_time=$(date +%s)
	for pid in $client_pids; do
		# Wait for the process to terminate
		while kill -0 "$pid" 2>/dev/null; do
		current_time=$(date +%s)
		elapsed_time=$((current_time - start_time))

		if [ $elapsed_time -ge $TIMEOUT ]; then
			echo ":: Timeout reached."
			bash "$HOME"/.config/shayar/listeners.sh --stopall
			return 0
		fi

		echo ":: Waiting for PID $pid to terminate..."
		sleep 1
		done

		echo ":: PID $pid has terminated."
	done
	bash "$HOME"/.config/shayar/listeners.sh --stopall
}

if [ -z "${1:-}" ]; then
	echo "Error: Action required (exit|lock|reboot|shutdown|suspend|hibernate)."
	exit 1
fi

case "$1" in
	exit)
		echo ":: Exit"
		terminate_clients
		sleep 0.2
		hyprctl dispatch exit
		;;
	lock)
		echo ":: Lock"
		sleep 0.2
		hyprlock
		;;
	reboot)
		echo ":: Reboot"
		terminate_clients
		sleep 0.2
		systemctl reboot
		;;
	shutdown)
		echo ":: Shutdown"
		terminate_clients
		sleep 0.2
		systemctl poweroff
		;;
	suspend)
		echo ":: Suspend"
		sleep 0.2
		systemctl suspend
		;;
	hibernate)
		echo ":: Hibernate"
		sleep 0.2
		systemctl hibernate
		;;
	*)
		echo "Error: Unknown action '$1'. Choose from: exit|lock|reboot|shutdown|suspend|hibernate."
		exit 1
		;;
esac
