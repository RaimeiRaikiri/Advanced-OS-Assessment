## Requirements

To run bash scripts on Windows you may need a translator, Mac and Linux have inbuilt support for bash.
Python requires an interpreter like python3 to run scripts.

## Installation 

Task 1 and Task 3 completed in bash may need to be made executable before running.
To make them executable write to the terminal:

chmod +x file_name.sh

Once executable to run the bash scripts write to the terminal:

./file_name.sh

Task 2 and Task 3 completed in Python can be executed by running:

python file_name.py
	or
python3 file_name.py

## Dependencies

The log files and files that hold data used in the programs are in the ZIP already 
but if for any reason they aren't, they get lost or get deleted the programs all 
create new files if there aren't any present

## Troubleshooting

Specifically for the task 3 login feature: getting the password wrong for an account 3 times
in a row causes it to become locked, the only way to unlock it is to edit the final field
of the line containing account data, it will be set to True when locked and False when unlocked.

Found in the login_detail.txt file, all fields were kept in plain text intentionally so this can
be edited and tested, as it is only a simulation.
