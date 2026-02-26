heading = f"{'Timestamp':<30}{'Type':<20}{'Student ID':<20}{'Filename':<30}\n"

def menu():
        print("1 Submit an assignment")
        print("2 Check if a file has been submitted")
        print("3 List all submitted assignments")
        print("4 Simulate login attempt")
        print("5 Exit system")
        print()

def submit_file(all_files):
	# Get all files in the current directory, including files in subdirectories. 
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
        file_size = get_file_size(filename)
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
				""" Check for identical filesize,
				if they are the same size they could be identical in content
				so it requires further inspection
				"""
                                identical_filesizes = []
                                for file in all_files:
                                        if file_size != get_file_size(file):
                                                continue
                                        else:
                                                identical_filesizes.append(file)
                                                continue

                                if not identical_filesizes:
					# If the file sizes arent identical, its not the same file so submit
                                        log_event(["", filename], "Submission")
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
                                                log_event(["", filename], "Submission")
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


def get_file_extension(filename):

        filename_split, extension = os.path.splitext(filename)

        return extension

def get_filesize(filepath):

        size_bytes = os.stat(filepath).st_size

        return size_bytes


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
				if values[3]:  # Always 4th item of values due to submission log structure
					all_files.append(values[3])
			except:
				# Do nothing
				# Exception should only occur when there is no filename, and therefore no need to add a file
				pass

	while True:
		menu()
		choice = input("Select your choice from the menu: ")
		print()

		match int(choice):
			case 1:
				pass
			case 2:
				pass
			case 3:
				pass
			case 4:
				pass
			case 5:
				exit_system()
