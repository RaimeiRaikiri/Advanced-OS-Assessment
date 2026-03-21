#!/usr/bin/env bash

LOG_DIR="./ArchiveLogs"
LOG_FILE="./system_monitor_log.txt"

# Using MiB and GiB as dealing with memory
FILE_SIZE_LIMIT=$((50 * 1024 * 1024))
DIR_SIZE_LIMIT=$((1024 * 1024 * 1024))

log_event(){
local msg="$1"
printf "%s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >> "$LOG_FILE"
check_log_size
}

print_main_menu(){
echo "1 - Display CPU and Memory"
echo "2 - List Top 10 Memory Users"
echo "3 - Terminate Process"
echo "4 - Inspect Disk Usage"
echo "5 - Exit"
echo
}

list_top10_memory(){
echo "Top 10 memory consuming processes"
echo

echo "$(ps -eo pid,ppid,user,%cpu,%mem --sort=-%mem | head)"
log_event "MEMORY top 10 memory consuming processes listed successfully"
}

terminate_processes(){
read -r -p "Select process to elimainate (enter PID): " pid
# To dev null so it prints what I dictate
if ! ps -p "$pid" > /dev/null; then
	log_event "PROCESS process to terminate not found"
	echo "PID $pid does not exist."
	exit 1
fi

while true; do

	read -r -p "Are you sure you want to terminate process of PID $pid (Enter Y to confirm, N to deny): " confirm
	if  [[ "$confirm" == "Y" ]] || [[ "$confirm" == "y" ]]; then

		if [ $(ps -o ppid= "$pid") == 1 ] ; then
			log_event "PROCESS PID $pid termination cancelled as root is 1"
			echo
			echo "Process termination canelled due to ppid = 1"
		elif [ $(ps -o user= "$pid") == "root" ] ; then
			log_event "PROCESS PID $pid  termination cancelled as user is root"
			echo
			echo "Termination of process $pid cancelled as user is root"
		else
			log_event "PROCESS PID $pid terminated successfully"
			kill "$pid" && echo && echo "PID $pid terminated"
		fi
		break

	elif [[ "$confirm" == "N" ]] || [[ "$confirm" == "n" ]];  then
		log_event "PROCESS PID $pid termination cancelled"
		echo "Termination of $pid cancelled"
		break
	else
		log_event "PROCESS termination failed, invalid confirmation"
		echo "Invalid choice, try again"
		continue
	fi
done
}

create_archive_directory() {
if [ ! -d "$LOG_DIR" ]; then
	mkdir "$LOG_DIR"
	echo "Archive directory created as it didn't exist"
	echo
	log_event "ARCHIVE archive directory created because one didn't exist"
fi

check_archive_directory
}

check_archive_directory(){
if [ -d "$LOG_DIR" ]; then
	if [ "$( du  -b $LOG_DIR | cut -f1)" -gt "$DIR_SIZE_LIMIT" ] ; then
		echo "Archive folder exceeds 1GB, please clear some space!" >&2
		echo
		log_event "ARCHIVE archive folder exceeds 1GB"
	fi
fi
}

check_log_size(){
local current_size=$(stat -c %s "$LOG_FILE")
if [ "$current_size" -ge "$FILE_SIZE_LIMIT" ]; then
	$(gzip "$LOG_FILE")
	local archive_log="$LOG_FILE.gz"
	mv "$archive_log" "$LOG_DIR/ArchivedLog_$(date '+%Y-%m-%d %H:%M:%S')"
	echo
	echo "Log file moved to archives as it exceeds the size limit"
	log_event "LOG current log file exceeds 50mb so is being moved to archives"
fi
}

inspect_disk_usage() {

while true; do
	read -r -p "Enter target directory path, relative to current directory: " path

	if [ -d "$path" ]; then
		# Cut to prevent path from being included in output to local variable
		local size=$(du -s "$path" | cut -f1)
		echo "Total size in bytes: $size"
		log_event "DISK INSPECT successfully inspect the disk usage of path $path"
		break
	else
		echo "Not a valid path to a directory, try again!"
		echo
		continue
	fi

done
}

exit_system(){

while true; do

	read -r -p "Are you sure you want to exit? (Y to confirm, N to deny): " confirm
	if [[ "$confirm" == "Y" ]] || [[ "$confirm" == "y" ]]; then
		log_event "EXIT system exited successfully"
		echo "Shutting down. See you next time!" && exit
	elif [[ "$confirm" == "N" ]] || [[ "$confirm" == "n" ]]; then
		log_event "EXIT system exit cancelled"
		echo "You've chosen to stay in the system."
		break
	else 
		log_event "EXIT system exit failed, invalid confirmation"
		echo "Invalid choice, try again!"
		continue
	fi
done
}

main_loop(){

create_archive_directory

while true; do
echo "Welcome to the Resource Management System"
echo
print_main_menu

read -r -p "Select choice: " choice
echo
case "$choice" in

	1) top && log_event "MEMORY CPU display cpu and memory successfully";;
	2) list_top10_memory ;;
	3) terminate_processes;;
	4) inspect_disk_usage;;
	5) exit_system ;;
	*) echo "Invalid choice" ;;
	esac
	echo
done
}

main_loop
