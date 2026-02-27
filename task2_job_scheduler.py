heading =f"{'Job Name':<20}{'Student ID':<20}{'Estimated execution time':<30}{'Priority':<20}\n"


def menu():
	print("1 Submit an assignment")
	print("2 Check if a file has been submitted")
	print("3 List all submitted assignments")
	print("4 Simulate login attempt")
	print("5 Exit system")
	print()

def create_job_request():
	name = input("Enter job name: ")
	student_id = input("Enter student ID: ")
	estimated_execution_time = input("Enter estimated execution time (in seconds): ")
	priority = input("Enter job priority (1-10): ")
	print()

def exit_system():
	while True:
		confirm = input("Are you sure you want to exit? (Enter Y to continue, N to deny): ")
		
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
	while True:

		"""
		 Open all log and job files, check if they exist
		 and have a header. If not add the header and/or create file
		 """

		with open("job_queue.txt", "a+") as pending_file:
			pending_file.seek(0)
			if not pending_file.readline():
				pending_file.write(heading)

		with open("scheduler_log.txt", "a+") as log_file:
			log_file.seek(0)
			if not log_file.readline():
				log_file.write(f"{'Timestamp':<30}{'Type':<20}" + heading)

		with open("completed_jobs.txt", "a+") as completed_file:
			completed_file.seek(0)
			if not completed_file.readline():
				completed_file.write(heading)

		menu()
		print()
		choice = input("Select a file to upload from this directory: ")

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
		

