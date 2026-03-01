#!/user/bin/env bash

BASE_DIR="$HOME"
LOG_FILE="$BASE_DIR/system_monitor_log.txt"

log_event(){
local msg="$1"
printf "%s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >> "$LOG_FILE"
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

ps -eo pid,ppid,user,%cpu,%mem --sort=-%mem | head
}

main_loop(){

while true; do
echo "Welcome to the Resource Management System"
echo
print_main_menu

read -r -p "Select choice: " choice
echo
case "$choice" in

	1) ;;
	2) list_top10_memory ;;
	3) ;;
	4) ;;
	5) ;;
	*) echo "Invalid choice" ;;
	esac
	echo
done
}

main_loop
