def menu():
	print("1 Submit an assignment")
	print("2 Check if a file has been submitted")
	print("3 List all submitted assignments")
	print("4 Simulate login attempt")
	print("5 Exit system")
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
	pass
