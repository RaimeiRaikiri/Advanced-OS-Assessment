#!/usr/bin/env bash

menu(){
echo "1 Submit an assignment"
echo "2 Check if a file has been submitted"
echo "3 List all submitted assignments"
echo "4 Simulate login attempt"
echo "5 Exit system"
echo
}

get_file_extension(){
local name="$1"
echo "${name##*.}"

}

submit_file() {

local all_files="$@"
local files=()

# Put all possible submission files in an array excluding git files
# Including files in subdirectories
mapfile -t files < <(find . -type f ! -path "./.git/*")

while true; do
	# Print the submission options and ask for the user choice
	local itr=$(print_numbered_list "${files[@]}")
	echo
	read -r -p "Select a file to upload from this directory (from the numbered list): " choice
	
	if [[ "$choice" -gt 0 ]] && [[ "$choice" -le "$itr" ]]; then
		break
	else
		# If the user doesn't input a valid choice
		echo
		echo "You have not selected a valid file from the list, try again (numbers 1 - $itr)"
		echo
		continue
	fi

done

local file_path="${files[(($choice -1))]}"
local file_size=$(wc -c < "$file_path")
local file_extension=$(get_file_extension "$file_path")

echo "path: $file_path"
echo "size: $file_size"
echo "extension: $file_extension"

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
			for file in "$all_files"; do

				if [[ "$file_size" != $(wc -c < "$file") ]]; then
					continue
				else
					identical_filesize+=("$file")
					continue
				fi
			done
			
			if [ ${#identical_filesize[@]} -eq 0]; then
				log_event "" "$file_path" "Submission"
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
					echo "$file_path"
				else
					echo <&2
					echo "This files content is identical to another that has been previously submitted, and therefore cannot be accpeted!" <&2
					echo <&2
				fi
			fi
		else
			echo <&2
			echo "This filepath is identical to another previously submitted and thereore cannot be accepted!" <&2
			echo <&2
		fi
	else
		echo <&2
		echo "This file is larger than 5 mb and therefore cannot be accepted!" <&2
		echo <&2
	fi
else
	echo <&2
	echo "This file is not a pdf or docx and therefore cannot be accepted!" <&2
	echo <&2
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
		printf "%-30s %-20s" "$(date '+%Y-%m-%d %H:%M:%S')" "$3" >> "submission_log.txt"
		local arr=("$@")

		for i in ${0..2}; do
			if [ -z "${arr[i]}" ]; then
				printf "%-20s" "" >> "submission_log.txt"
			else
				printf "%-20s" "${arr[i]}" >> "submission_log.txt"
			fi
		done
		
		printf "\n" >> "submission_log.txt" 
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

arr[0]="./test.pdf"

submit_file ${arr[@]}
