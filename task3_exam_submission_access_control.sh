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

local -a all_files=("$@")
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
				for file in "$all_files"; do
					if [[ "$file_size" != $(wc -c < "$file") ]]; then
						continue
					else
						identical_filesize+=("$file")
						continue
					fi
				done
			fi
			
			if [[ ${#identical_filesize[@]} -eq 0 ]]; then
				log_event "" "$file_path" "Submission"
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
					log_event "" "$file_path" "Submission"
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
	if [[ "$3" == "Submission" ]] || [[ "$3" == "submission" ]]; then
		printf "%-30s%-20s" "$(date '+%Y-%m-%d %H:%M:%S')" "$3" >> "submission_log.txt"
		local arr=("$@")

		for ((i=0; i<2; i++)); do
			if [ -z "${arr[i]}" ]; then
 				printf "%-20s" "" >> "submission_log.txt"
			else
				printf "%-20s" "${arr[i]}" >> "submission_log.txt"
			fi
		done
		
		printf $"\n" >> "submission_log.txt" 
	fi
}

get_logins() {
	local logins=()

	while IFS=":" read -r username password locked; do
		if [ ${#username} -gt 0 ]; then
			logins+=("$username:$password:$locked")
		fi
	done < "login_details.txt"
	
	echo "${logins[@]}"
}

login() {
local -a all_files=()
local logins=$(get_logins)

for log in ${logins[@]}; do
	IFS=":" read -r user value <<< "$log"
	all_logins["$user"]="$value"
done

echo ${#all_logins[@]}

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

		echo ""
		return
	elif [[ "$locked" == "" ]]; then
		echo "its empty" >&2
		return
	elif [[ "$locked" == "false" ]]; then

		IFS=":" read -ra arr <<< "${all_logins[$username]}"

		local stored_password="${arr[0]}"
		local fail_times=()

		local new_times=()

		for ((i=1; i<4; i++)); do
			read -r -p "Enter password: " password

			local current_time=$(date +%s)


			if [[ "$password" == "$stored_password" ]]; then
				echo "get in here" >&2
				local fast_attempts=0
				for t in "${fail_times[@]}"; do
					if (( start - t -le 60 )); then
						((fast_attempts++))
					fi
				done


				if (( fast_attempts >= 3 )); then
					echo >&2
					echo "Suspicious activity detected! Repeated login attempts within 60s" >&2
				fi

				echo "$username"
				echo "$password"
				echo "false"
				return
				
			else
				echo >&2
				echo "Incorrect password you have $((3 - $i)) attempts remaining to try again!" >&2
				echo >&2

				fail_times+=("$current_time")
			fi
		done

		echo >&2
		echo "Account with the username -$username- has been locked due to 3 incorrect password entries" >&2
		echo >&2
		

		# Overwrite old file with new line inserted
		local lines=()
		local i=0
		local target=0

		while IFS= read -r line; do

			local first="${line%%:*}"
			# Correct index when username matches first field of line
			if [[ "$first" == "$username" ]]; then
				target=i
			fi

			lines+=("$line")
			((i++))

		done < "login_details.txt"

		lines[target]="$username:$password:True"
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
		echo "we through new login" >&2
		echo "$Gusername $Gpassword $Gnew" >&2
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
		echo "username doesnt exist" >&2
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
		local temp=$(submit_file ${all_files[@]})
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
		echo "all dets"
		echo ${login_details[@]}
		if [ ${#login_details[@]} -gt 0 ]; then
			if [[ ${login_details[-1]} == "true" ]]; then
				echo "details"
				echo ${login_details[0]}
				echo ${login_details[1]}
				printf "%s\n" "${login_details[0]}:${login_details[1]}:False" >> "login_details.txt"

				all_logins[login_details[0]]="${login_details[1]}:False}"
				order+=(${login_details[0]})
				echo ${order[@]}
				echo 
				echo "New login details saved!"
				
				current_student_id=${#order[@]}
				logged_in=true

				echo "Student id = $current_student_id"
				echo

			else
				if [[ ${login_details[1]} == "/" ]]; then
					all_logins[login_details[0]]="${all_logins[login_details[1]]%%:*}:True"
					logged_in=false
					current_student_id=""

				else
					echo
					echo "Login successful, Hello ${login_details[0]}!"

					logged_in=true
					local x=0
					for user in ${order[@]}; do
						if [[ "$user" == ${order[x]} ]]; then
							break
						fi
						((x++))
					done
					current_student_id="$x"
					echo "id = $current_student_id"
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
