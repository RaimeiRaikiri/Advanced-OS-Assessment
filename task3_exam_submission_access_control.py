import os, datetime, time


heading = f"{'Timestamp':<30}{'Type':<20}{'Student ID':<20}{'Filename':<30}\n"

def menu(logged_in):
	if logged_in == True:
		print("1 Submit an assignment")
		print("2 Check if a file has been submitted")
		print("3 List all submitted assignments")
		print("4 Simulate login attempt")
		print("5 Sign out")
		print("6 Exit system")
		print()
	else: 
		print("1 Submit an assignment")
		print("2 Check if a file has been submitted")
		print("3 List all submitted assignments")
		print("4 Simulate login attempt")
		print("5 Exit system")
		print()

def submit_file(all_files, current_student_id):
	# Get all fileexs in the current directory, including files in subdirectories. 
	available_submission_files = get_list_of_all_files(".")

	while True:
		itr = print_numbered_list(available_submission_files)
		print()
		choice = input("Select a file to upload from this directory: ")

		try :
			# If the user inputs a valid choice proceed
			if int(choice) > 0 and int(choice) <= itr:
				break
			else:
				print()
				print(f"You have not selected a valid file, try again (numbers 1 - {itr})!")
				print()
				continue
		except:
			print()
			print(f"You have not even entered a number, try again!")
			print()
			continue

	filename = available_submission_files[int(choice) - 1]
	file_size = get_filesize(filename)
	file_extension = get_file_extension(filename)

	# Check to ensure submission is docx or pdf
	if (file_extension == ".docx") or (file_extension == ".pdf"):

		# Check if the file is less than 5 mb in size
		if file_size < 5 * (1024 ** 2):

			# Check for identical filename
			identical_filename = False
			for file in all_files:
				if filename == file:
					identical_filename = True
					break

			if identical_filename == False:
				"""
				Check for identical filesize,
				if they are the same size they could be identical in content
				so it requires further inspection
				"""
				identical_filesizes = []
				for file in all_files:
					
					if file_size != get_filesize(file):
						continue
					else:
						identical_filesizes.append(file)
						continue

				if not identical_filesizes:
					# If the file sizes arent identical, its not the same file so submit
					log_event([current_student_id, filename], "Submission")
					print()
					print("File successfully submitted")
					print()
					return filename
				else:
					# Inspect all identical sized files line by line to compare content
					identical_file = False
					for file in identical_filesizes:
						with open(filename, "rb") as f1, open(file, "rb") as f2:
							while True:
								binary_1 = f1.read(4096)
								binary_2 = f2.read(4096)

								# Compare line by line, if a single file is identical the file cannot be submitted
								if binary_1 != binary_2:
									break
								if not binary_1:
									identical_file = True
									break
						if identical_file:
                                                	break

					if not identical_file:
						log_event([current_student_id, filename], "Submission")
						print()
						print("File successfully submitted")
						print()

						return filename

					else:
						print()
						print("This files contents is identical to another that has been previously submitted, and therefore cannot be accepted!")
						print()
			else:
                        	print()
                        	print("This filename is identical to another that has been submitted previously, and therefore cannot be accepted!")
                        	print()
		else:
                	print()
                	print("This file is larger than 5 mb and therefore cannot be accepted!")
                	print()
	else:
        	print()
       		print("This file is not a pdf or docx and therefore cannot be accepted!")
       		print()

def check_file_submitted(all_files):
	filepath = input("Enter full file path: ")
	if filepath:
		for file in all_files:
			if file == filepath:
				return True, file

		return False, filepath

	else:
		return False, filepath

def list_all_submissions(all_files):
	print("All previous submissions: ")
	print()
		
	for file in all_files:
		print(file)

	print()

def get_file_extension(filename):

        filename_split, extension = os.path.splitext(filename)

        return extension

def get_filesize(filepath):

        size_bytes = os.stat(filepath).st_size

        return size_bytes

def get_list_of_all_files(starting_point):
	files = []
	# Traverse the current directory recursively, returning paths for all files
	# including those in subdirectories,
	for directory_path, directory_names, file_names in os.walk(starting_point):
		for file in file_names:
				path = os.path.join(directory_path, file)
				# Remove git files from the options to submit
				if path[:6] != "./.git":
					files.append(path)

	return files

def print_numbered_list(values):
	itr = 0

	for item in values:
		itr += 1
		print(str(itr) + " - " + item)

	return itr

def get_logins():
	logins = {}

	with open("login_details.txt", "a+") as login_file:
		login_file.seek(0)
		for line in login_file.readlines():
			split_line = line.strip().split(":")

			logins[split_line[0]] = [split_line[1], split_line[2]]

	return logins

def login(all_logins):
	# You have to creeate a new login if there is none already
	if all_logins == {}:
		new_login = None

		while new_login == None:
			new_login = create_new_login()

		return new_login[0], new_login[1], new_login[2]
	# Option to create new login
	choice = input("Enter Y to create new login: ")

	if choice.capitalize() == "Y":
		print()
		print("You have chosen to create a new login")
		new_login = None

		while new_login == None:
			new_login = create_new_login()

		return new_login[0], new_login[1], new_login[2]
	else:
		print()
		print("You have chosen to login to an existing account")
		username = input("Enter username: ")
		locked = check_account_locked(all_logins, username)

		if locked == True:
			print()
			# Editing the login_detail.txt file, find the username and edit the True to False to unlock
			print(f"Account -{username}- LOCKED! Administrator required to edit files to unlock!")
			print()

			return None

		elif locked == None:
			return None

		# 3 Attempts to get password correct
		fail_times = []
		start = time.time()
		fail_times.append(start)

		for x in range(1,4):
			password = input("Enter password: ")
			
			if password == all_logins[username][0]:
				# Only keep times that were within 60 seconds and flags suspicous if too many within 60s
				fail_times= [t for t in fail_times if start - t <=60]
				if len(fail_times) >= 3:
					print()
					print("Suspicious activity detected! Repeated login attempts within 60s")
					log_event(["", ""], "Suspicous Activity")

				# Return false as it is not a new login
				return username, password, False
			else:
				print()
				print(f"Incorrect password you have {3-x} attempts remaining to try again!")
				print()

				fail_times.append(time.time())
				log_event(["", ""], "Login:Fail")
		
		fail_times = [t for t in fail_times if start - t <=60]
		if len(fail_times) >= 3:
			print()
			print("Suspicious activity detected! Repeated login attempts within 60s")
			log_event(["",""], "Suspicous Activity")

		print()
		print(f"Account with the username -{username}- has been locked due to 3 incorrect password entries")
		print()

		log_event(["", ""], "Account Locked")

		with open("login_details.txt", "r") as login_file:
			lines = login_file.readlines()

		index = list(all_logins.keys()).index(username)
		lines[index] = f"{username}:{all_logins[username][0]}:True \n" # Just change the ending of this entry to lock account

		with open("login_details.txt", "w") as login_file:
			login_file.writelines(lines)

		return username, "", False

def create_new_login():
	print()
	new_username = input("Enter new username (minimum length 6 chars): ")
	new_password = input("Enter new password (minimum length 8 chars): ")

	# Username of at least 6 chars and password of at least 8
	if len(new_username) > 5:
		if len(new_password) > 7:
			# Return true if its a new login
			return new_username, new_password, True
		else:
			print()
			print("Password is too short, try again!")
			print()

			return None
	print()
	print("Username is too short, try again!")
	print()

	return None

def check_account_locked(all_logins, username):
	if all_logins:
		try:
			locked = all_logins[username][1]

		except:
			print()
			print("Username does not exist!")
			print()

			return None

		if locked.lower()  ==  "true":
			return True
		else:
			return False

def log_event(values, type):
	"""
	Log events in the desired format, to the submission log 
	including: timestamp, type of log, student id if its present
	and filename if its a submission
	"""
	current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
	with open("submission_log.txt", "a") as submission_file:
		submission_file.write(f"{current_time:<30}{type:<20}")
		for x in range(0,2):
			try:
				if values[x]:
					submission_file.write(f"{values[x]:<20}")
				else:
					submission_file.write(f"{'':<20}")
			except:
		 		submission_file.write(f"{'':<20}")
		submission_file.write("\n")

def exit_system():
        while True:
                confirm = input("Are you sure you want to exit? (Enter Y to confirm, N to deny): ")
                if confirm.capitalize() == "Y":
                        print("Exit confirmed")
                        exit()
                elif confirm.capitalize() == "N":
                        print("You have cancelled system exit")
                        print()
                        break
                else:
                        print("Invalid input, try again")
                        print()
                        continue


def main():
	print("Welcome to the secure examination and access control system!")
	print()

	all_files = []
	# Get all logins at the start
	all_logins = get_logins()

	current_student_id = ""
	logged_in = False

	# Create the log file if it doesn't exist
	with open("submission_log.txt", "a+") as submission_file:

		submission_file.seek(0)

		# Check if there is a heading in the log file, if not add one
		if not submission_file.readline():
			submission_file.write(heading)

		# Ensure the previous check does not misalign the pointer
		submission_file.seek(0)  # Pointer reset to file start
		submission_file.readline() # pointer to 2nd line

		# Take filename from each submission, add to list in memory 
		for line in submission_file.readlines():
			values = line.split()
			try:
				if values[2] == "Submission":
					# Always last item of values due to submission log structure
					all_files.append(values[-1])
			except:
				# Do nothing
				# Exception should only occur when there is no filename, and therefore no need to add a file
				pass

	while True:
		if logged_in:
			user = list(all_logins.keys())[current_student_id - 1]
			print("-" * 20)
			print()
			print(f"Logged in as -{user}- with Student ID NO. {current_student_id}")
			print()
		print("-" * 20)
		print()
		menu(logged_in)
		choice = input("Select your choice from the menu: ")
		print()
		try:
			choice = int(choice)
		except:
			print("Invalid choice")
			continue

		match choice:
			case 1:
				filename = submit_file(all_files, current_student_id)
				if filename:
					all_files.append(filename)
			case 2:
				file_submitted, file = check_file_submitted(all_files)

				if file_submitted:
					print()
					print(f"File {file} was submitted previously!")
					print()
				else:
					print()
					print("This file has not been submitted previously!")
					print()
			case 3:
				list_all_submissions(all_files)
			case 4:
				login_details = login(all_logins)


				if login_details:

					if login_details[2]:
						with open("login_details.txt", "a") as login_file:
							# Store new login in file
							login_file.write(f"{login_details[0]}:{login_details[1]}:False")
							login_file.write("\n")

						all_logins[login_details[0]] = [login_details[1], "False"]
						print()
						print("New login details saved!")

						# Log in
						current_student_id = len(all_logins.keys())
						logged_in = True

						print(f"Student id = {current_student_id}")
						print()

						log_event([current_student_id, ""], "Sign Up")

					else:
						if login_details[1] == "":
							all_logins[login_details[0]][1] = True
							# Sign out
							logged_in = False
							current_student_id = ""

						else:
							print()
							print(f"Login successful, Hello {login_details[0]}!")

							logged_in = True
							current_student_id = list(all_logins.keys()).index(login_details[0]) + 1

							print(f"Student id = {current_student_id}")
							print()

							log_event([current_student_id, ""], "Login:Success")
			case 5:
				if logged_in:
					# Sign out functionality
					logged_in = False
					current_student_id = ""
				else:
					exit_system()
			case 6:
				if logged_in:
					exit_system()
				else:
					print("Invalid choice")
			case _:
				print("Invalid choice")
			


main()

