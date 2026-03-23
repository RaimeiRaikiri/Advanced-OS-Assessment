#!/usr/bin/env bash

menu(){
local choice=$1

if [ "$choice" == "true" ]; then
	echo "1 Submit an assignment"
	echo "2 Check if a file has been submitted"
	echo "3 List all submitted assignments"
	echo "4 Simulate login attempt"
	echo "5 Sign out"
	echo "6 Exit system"
	echo
else
	echo "1 Submit an assignment"
	echo "2 Check if a file has been submitted"
	echo "3 List all submitted assignments"
	echo "4 Simulate login attempt"
	echo "5 Exit system"
	echo
fi
}

get_file_extension(){
local name="$1"
echo "${name##*.}"

}

check_file_submitted(){
read -r -p "Enter full file path relative to current directory: " path
local arr=("$@")

if [ -n "$path" ]; then
	for element in "${arr[@]}"; do
		if [ "$element" == "$path" ]; then
			echo "$path"
			return
		fi
	done
fi
}

submit_file() {
local id="$1"
local -a all_files=("$2")
local files=()

# Put all possible submission files in an array excluding git files
# Including files in subdirectories
mapfile -t files < <(find . -type f ! -path "./.git/*")

while true; do
	# Print the submission options and ask for the user choice
	local itr=$(print_numbered_list "${files[@]}")
	echo >&2
	read -r -p "Select a file to upload from this directory (from the numbered list): " choice
	
	if [[ "$choice" -gt 0 ]] && [[ "$choice" -le "$itr" ]]; then
		break
	else
		# If the user doesn't input a valid choice
		echo >&2
		echo "You have not selected a valid file from the list, try again (numbers 1 - $itr)" >&2
		echo >&2
		continue
	fi

done

local file_path="${files[(($choice -1))]}"
local file_size=$(wc -c < "$file_path")
local file_extension=$(get_file_extension "$file_path")

# Check if the selected file is appropriate for submission
if [[ "$file_extension" == "docx" ]] || [[ "$file_extension" == "pdf" ]]; then 

	if [[ "$file_size" -lt $((5 * (1024 * 1024))) ]]; then

		local identical_filepath=false
		for file in "$all_files"; do

			if [[ "$file_path" == "$file" ]]; then
				identical_filepath=true
				break
			fi
		done
 
		if [[ "$identical_filepath" == false ]]; then

			local -a identical_filesizes=()
			if [ ${#all_files[@]} -ge 1 ]; then
				for file in ${all_files[@]}; do
					if [[ "$file_size" != $(wc -c < "$file") ]]; then
						continue
					else
						identical_filesize+=("$file")
						continue
					fi
				done
			fi
			
			if [[ ${#identical_filesize[@]} -eq 0 ]]; then
				log_event "$id" "$file_path" "Submission"
				echo >&2
				echo "File submitted successfully!" >&2
			
				echo "$file_path"
			else
				local identical_file=false
				for file in "${identical_filesize[@]}"; do

					if cmp -s "$filepath" "$file"; then
						identical_file=true
						break
					fi
				done
				if [ identical_file == true ]; then
					log_event "$id" "$file_path" "Submission"
					echo >&2
					echo "File submitted successfully!" >&2
					
					echo "$file_path"
				else
					echo >&2
					echo "This files content is identical to another that has been previously submitted, and therefore cannot be accpeted!" >&2
				fi
			fi
		else
			echo >&2
			echo "This filepath is identical to another previously submitted and thereore cannot be accepted!" >&2
		fi
	else
		echo >&2
		echo "This file is larger than 5 mb and therefore cannot be accepted!" >&2
	fi
else
	echo >&2
	echo "This file is not a pdf or docx and therefore cannot be accepted!" >&2
fi 

}

print_numbered_list(){
local itr=0

for item in "$@"; do
	((itr++)) 
	# Sending the printed output to stderr so that the itr does not get printed
	echo "$itr - $item" >&2
done

echo "$itr"
}

log_event() {
	printf "%-30s%-20s" "$(date '+%Y-%m-%d %H:%M:%S')" "$3" >> "submission_log.txt" 
	local arr=("$@")

	for ((z=0; z<2; z++)); do
		if [ -z "${arr[z]}" ]; then
			printf "%-20s" "" >> "submission_log.txt" 
		else
			printf "%-20s" "${arr[z]}" >> "submission_log.txt" 
		fi
	done
		
	printf "\n" >> "submission_log.txt"

}


get_logins() {
	local logins=()

	if [[ -f "login_details.txt" ]]; then
		while IFS=":" read -r username password locked; do
			if [ ${#username} -gt 0 ]; then
				logins+=("$username:$password:$locked")
			fi
		done < "login_details.txt"
	
		echo "${logins[@]}"
	else
		touch "login_details.txt"
	fi
}

login() {
local -a all_files=()
local logins=$(get_logins)

for log in ${logins[@]}; do
	IFS=":" read -r user value <<< "$log"
	all_logins["$user"]="$value"
done


if [ ${#all_logins[@]} == 0 ]; then
	while true ; do
		create_new_login
		if [ ${#Gusername} -gt 0 ] && [ ${#Gpassword} -gt 0 ] && [ ${#Gnew} -gt 0 ]; then
			echo "$Gusername"
			echo "$Gpassword"
			echo "$Gnew"
			return
		fi
	done

fi

read -r -p "Enter Y to create new login: " choice

if [ "$choice" == "Y" ] ||[ "$choice" == "y" ]; then
	echo >&2
	echo "You have chosen to create a new login" >&2
	
	while true; do
		create_new_login
		if [ ${#Gusername} -gt 0 ] && [ ${#Gpassword} -gt 0 ] && [ ${#Gnew} -gt 0 ]; then
			echo "$Gusername"
			echo "$Gpassword"
			echo "$Gnew"
			return
		fi
	done
else
	echo >&2
	echo "You have chosen to login to an existing account" >&2

	read -r -p "Enter username: " username

	local locked=$(check_account_locked ${all_logins[$username]} )
	
	if [[ "$locked" == "true" ]]; then
		echo >&2
		echo "Account -$username- LOCKED! Administrator required to edit files to unlock!" >&2
		echo >&2

		log_event "" "" "Account Locked"
		echo "@"
		return
	elif [[ "$locked" == "@" ]]; then
		echo "@"
		return
	elif [[ "$locked" == "false" ]]; then

		IFS=":" read -ra arr <<< "${all_logins[$username]}"

		local stored_password="${arr[0]}"
		local login_attempts=()

		for ((i=3; i>0; i--)); do
			read -r -p "Enter password: " password < /dev/tty


			if [[ "$password" == "$stored_password" ]]; then

				echo "$username"
				echo "$password"
				echo "false"
				return
				
			else

				
					echo >&2
					echo "Incorrect password you have $i attempts remaining to try again!" >&2
					echo >&2 

					login_attempts+=($(date +%s))
					log_event "" "" "Login:Failed" >&2
		
			fi
		done

		local diff=$(( login_attempts[-1] - login_attempts[-3] ))

		if [[ $diff -le 60 ]]; then
			echo >&2
			echo "Suspicious activity! Login attempts are too fast" >&2
			echo >&2

			log_event "" "" "Suspicious Activity"

		fi

		echo >&2
		echo "Account with the username -$username- has been locked due to 3 incorrect password entries" >&2
		echo >&2
		
		log_event "" "" "Account Locked"

		# Overwrite old file with new line inserted
		local lines=()
		local y=0
		local target=0
		local pass=""

		while IFS= read -r line; do

			local first="${line%%:*}"
			# Correct index when username matches first field of line
			if [[ "$first" == "$username" ]]; then
				target="$y"
				pass=$(echo "$line" | cut -d':' -f2)
			fi

			lines+=("$line")
			((y++))

		done < "login_details.txt"

		lines["$target"]="$username:$pass:True"
		printf "%s\n" "${lines[@]}" > "login_details.txt"

		echo "$username"
		echo "/"
		echo "False"
		return
	fi

	
fi


}

create_new_login() {
echo 

read -r -p "Enter new username (minimum length 6 chars): " Gusername 

read -r -p "Enter new password (minimum length 8 chars): " Gpassword 

if [ ${#Gusername} -gt 5 ]; then
	if [ ${#Gpassword} -gt 7 ]; then
		Gnew="true"
		return
	else
		echo >&2
		echo "Password is too short, try again!" >&2
		echo >&2

		echo ""
		return
	fi

	echo >&2
	echo "Username is too short, try again!" >&2
	echo >&2

	echo ""
	return
fi
}

check_account_locked() {
	local entry="$1"

	if [[ -z "$entry" ]]; then
		echo >&2
		echo "Username does not exist!" >&2
		echo "@"
		return
	fi

	local locked_status="${entry##*:}"

	if [[ "${locked_status,,}" == "true"  ]]; then
		echo "true"
	else
		echo "false"
	fi
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
	fi

done
}

main_loop(){
echo "Welcome to the secure examination and access control system!"
echo

# Get all logins at program start
declare -A all_logins
declare -a order

local logins=$(get_logins)

for log in ${logins[@]}; do
	IFS=":" read -r user value <<< "$log"
	all_logins["$user"]="$value"
	order+=("$user")
done


local current_student_id=""
local logged_in=false

# Create submission log with heading if its not already made, or doesn't have a heading
if [ -f "submission_log.txt" ]; then
	if ! [ -s "submission_log.txt" ]; then
		printf "%-30s%-20s%-20s%-30s\n" "Timestamp" "Type" "Student ID" "Filename" >> "submission_log.txt"
	fi
else
	printf "%-30s%-20s%-20s%-30s\n" "Timestamp" "Type" "Student ID" "Filename" > "submission_log.txt"
fi

# Read submission log and put all submitted files into array for future checks
local -a all_files=()
local itr=0

while IFS= read -r line; do
if [ "$itr" -ge 1 ]; then
	IFS=' '
	read -a arr <<< "$line"
	if [[ ${arr[2]} == "Submission" ]]; then
		all_files+=(${arr[-1]})
	fi
fi

((itr++))
done < "submission_log.txt"


while true; do 

if [ "$logged_in" == true ]; then
	local num
	num=$((current_student_id - 1))
	local user="${order[$num]}"

	printf '%.0s-' {1..20}
	printf "\n"
	echo
	echo "Logged in as -$user- with Student ID NO. $current_student_id"
	printf "\n"
fi
printf '%.0s-' {1..20}
printf "\n"
echo

menu "$logged_in"

read -r -p "Select choice: " choice
echo
case "$choice" in

	1) 
		local temp=$(submit_file "$current_student_id" ${all_files[@]})
		all_files+=("$temp") ;;
	2) 
		local file_submitted=$(check_file_submitted ${all_files[@]})
		if [ -n "$file_submitted" ]; then
			IFS=
			echo
			printf "File %s was submitted previously!\n" "$file_submitted"
		else
			echo
			printf "This file has not been submitted previously!"
		fi ;;
	3) 
		if [ ${#all_files[@]} == 0 ]; then
			echo "No submissions yet!"
		else
			echo "All previous submissions: "
			echo
		
			for file in ${all_files[@]}; do
				echo "$file"
			done 
		fi
		;;
	4) 
		mapfile -t login_details <<< "$(login ${all_logins[@]})"

		if [[ "$login_details" != "@" ]]; then
			
			if [[ ${login_details[-1]} == "true" ]]; then
				printf "%s\n" "${login_details[-3]}:${login_details[-2]}:False" >> "login_details.txt"

				all_logins[login_details[-3]]="${login_details[-2]}:False}"
				order+=(${login_details[-3]})

				echo 
				echo "New login details saved!"
				
				current_student_id=${#order[@]}
				logged_in=true

				echo "Student id = $current_student_id"
				echo

			else

				if [[ ${login_details[-2]} == "/" ]]; then
					all_logins[login_details[-3]]="${all_logins[login_details[1]]%%:*}:True"
					logged_in=false
					current_student_id=""

				else

					logged_in=true
					local x=1

					for name in ${order[@]}; do
						if [[ "$name" == ${login_details[-3]} ]]; then
							break
						fi
						((x++))
					done
					current_student_id="$x"
					echo "Login successful, Hello ${login_details[-3]}!"
				fi
			fi
		fi
;;
	5) 
		if [ "$logged_in" == true ]; then
		 	logged_in=False
			current_student_id=""
		else
			exit_system
		fi ;;
	6)
		if [ "$logged_in" == true ]; then
			exit_system
		else
			echo "Invalid choice"
		fi;;
	*) echo "Invalid choice" ;;
	esac
	echo
done
}


main_loop
