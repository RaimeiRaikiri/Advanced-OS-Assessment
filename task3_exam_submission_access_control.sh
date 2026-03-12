menu(){
echo "1 Submit an assignment"
echo "2 Check if a file has been submitted"
echo "3 List all submitted assignments"
echo "4 Simulate login attempt"
echo
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
	5) ;;
	*) echo "Invalid choice" ;;
	esac
	echo
done
}
