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
	for element in ${arr[@]}; do
		if [ "$element" == "$path" ]; then
			echo "$path"
		else
			echo ""
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
local declare -n all_logins=$1

if [ ${#all_logins[@]} == 0 ]; then
	while true ; do
		create_new_login
		if [ ${#Gusername} -gt 0 ]; then
			echo "$Gusername $Gpassword $Gnew"
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

	local locked=$(check_account_locked "$username" ${all_logins[@]})
	echo "locked: $locked" >&2
	
	if [[ "$locked" == "true" ]]; then
		echo >&2
		echo "Account -$username- LOCKED! Administrator required to edit files to unlock!" >&2
		echo >&2

		echo ""
		return
	elif [[ "$locked" == "" ]]; then
		echo ""
		return
	elif [[ "$locked" == "false" ]]; then
		echo "Throough false locked"
		read -ra arr <<< "${all_logins[username]}"
		local fail_times=()
		local start=$(date +%s)

		local new_times=()
		fail_times+=("$start")

		for ((i=1; i<4; i++)); do
			read -r -p "Enter password: " password

			if [ "$password" == ${arr[0]} ]; then
				for t in ${fail_times[@]}; do
					if (( start - t -le 60 )); then
						new_times+=("$t")
					fi
				done

				fail_times=("${new_times[@]}")

				if [ ${#fail_times[@]} -ge 3 ]; then
					echo >&2
					echo "Suspicious activity detected! Repeated login attempts within 60s" >&2

					echo "$username $password false"
					return
				fi
			else
				echo >&2
				echo "Incorrect password you have $((3 - $i)) attempts remaining to try again!" >&2
				echo >&2

				fail_times+=$(date +%s)
			fi
		done

		for t in ${fail_times[@]}; do
			if (( start - t <= 60 )); then
				new_times+=("$t")
			fi
		done
		# Dectect suspicous activity if failed login quickly
		if [ ${#fail_times[@]} -ge 3 ]; then
			echo >&2
			echo "Suspicious activity detected! Repeated login attempts within 60s" >&2
		fi

		echo >&2
		echo "Account with the username -$username- has been locked due to 3 incorrect password entries" >&2
		echo >&2
		
		# Find the index of the username, finding location of line to edit
		local i=0

		for key in ${!all_logins[@]}; do
			if [[ "$key" == "$username" ]]; then
				break
			fi
			((i++))
		done
		# Overwrite old file with new line inserted
		local lines=()
		while IFS= read -r line; do
			lines+=("$line")
		done < "login_details.txt"

		line[i]="$username:$password:True"
		printf "%s\n" "${lines[@]}" > "login_details.txt"

		echo "$username $password False"
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
	local username=$1
	local declare -n all_logins=$2
	read -ra arr <<< "${all_logins[username]}"
	echo ${arr[@]}
	if [ ${#all_logins[@]} -gt 0 ]; then
		locked=${arr[0]#*:}
		echo "prior" >&2
		echo "$locked" >&2
		if [ "${locked,,}" == "true" ]; then
			echo true
			return
		else
			echo false
			return 
		fi
	else
		echo >&2
		echo "Username does not exist!" >&2
		echo >&2

		echo ""
		return
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
echo "order:"
echo ${order[@]}

local current_student_id=3
local logged_in=true

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
	if [ ${#arr[@]} == 4 ]; then
		all_files+=(${arr[3]})
	fi
fi

((itr++))
done < "submission_log.txt"


while true; do 

if [ "$logged_in" == true ]; then
	local user=${order[(($current_student_id-1))]}

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
			echo
			echo "File $file_submitted was submitted previously!"
		else
			echo
			echo "This file has not been submitted previously!"
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
		echo "All logins:"
		echo ${all_logins[0]}
		if [ ${#login_details[@]} -gt 0 ]; then
			echo "details exist"
			if [[ ${login_details[3]} == "true" ]]; then
				
				printf "%s\n" "${login_details[1]}:${login_details[2]}:False" >> "login_details.txt"

				all_logins[login_details[1]]="${login_details[2]}:False}"
				order+=(${login_details[1]})
				echo ${order[@]}
				echo 
				echo "New login details saved!"
				
				current_student_id=${#order[@]}
				logged_in=true

				echo "Student id = $current_student_id"
				echo

			else
				if [[ ${login_details[2]} == "" ]]; then
					all_logins[login_details[1]]="${all_logins[login_details[2]]%%:*}:True"
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
