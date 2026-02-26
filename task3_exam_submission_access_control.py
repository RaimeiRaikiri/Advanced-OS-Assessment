def menu():
        print("1 Submit an assignment")
        print("2 Check if a file has been submitted")
        print("3 List all submitted assignments")
        print("4 Simulate login attempt")
        print("5 Exit system")
        print()

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
