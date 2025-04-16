"""
demo-python-cells.py

This code doesn't do anything useful, it's just a test file to help workshop
participants get used to VS Code.
"""

#%% Imports

# These are packages we'll use somewhere in this file.  They don't have
# to be together at the top of a Python file, though it's common to do this.
import os
from datetime import date


#%% Print the current date

today = date.today()
print("Today's date is:", today)


#%% Generate a bunch of random numbers and add them together

# It's OK to import new packages in places other than the top of
# a file.
import random

# Generate a list of random numbers between 0 and 1
n_numbers = 10
random_numbers = []
for i_number in range(0,n_numbers):
    random_numbers.append(random.random())

# Print the numbers
for i_number in range(0,n_numbers):
    print('Number {}: {}'.format(i_number,random_numbers[i_number]))

# Calculate and print the sum
total = sum(random_numbers)
print("\nSum of our random numbers:", total)

