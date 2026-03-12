menu(){
echo "1 Submit an assignment"
echo "2 Check if a file has been submitted"
echo "3 List all submitted assignments"
echo "4 Simulate login attempt"
echo "5 Exit system"
echo
}

exit_system(){
while true; do

	read -r -p "Are you sure you want to exit (Y to confirm, N to deny): " confirm
	if [[ "$confirm"  == "Y" ]] || [[ "$confirm" == "y" ]]; then
		echo "Shutting down. See you next time!" && exit
	elif [[ "$confirm" == "N" ]] || [[ "$confirm" == "n" ]]; then
		echo "You've chosen to stay in the system."
		break
	else
		echo "Invalid choice, try again!"
		continue
}
main_loop(){
echo "Welcome to the secure examination and access control system!"
echo

while true; do 
menu

read -r -p "Select choice: " choice
echo
case "$choice" in

	1) ;;
	2) ;;
	3) ;;
	4) ;;
	5) exit_system ;;
	*) echo "Invalid choice" ;;
	esac
	echo
done
}
