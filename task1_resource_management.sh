#!/user/bin/env bash

print_main_menu(){
echo "1 - Display CPU and Memory"
echo "2 - List Top 10 Memory Users"
echo "3 - Terminate Process"
echo "4 - Inspect Disk Usage"
echo "5 - Exit"
echo
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
	2) ;;
	3) ;;
	4) ;;
	5) ;;
	*) echo "Invalid choice" ;;
	esac
	echo
done
}

main_loop
