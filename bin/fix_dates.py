#!/bin/env python3
import os
import re
from operator import sub
import shutil
from dateutil import parser
import argparse

def reformat_date(fulldate):
    """
    Reformat a date string to 'yy.mm.dd' format.
    """
    try:
        parsed_date = parser.parse(fulldate, fuzzy=True)
        return parsed_date.strftime("%y.%m.%d")
    except ValueError:
        print(f"Unrecognized date format: {fulldate}")
        return None

def move_file(original_file, new_file, test_mode):
    """
    Move a file to a new location, or simulate the move in test mode.
    """
    if test_mode:
        print(f"Would move {original_file} to {new_file}")
    else:
        try:
            shutil.move(original_file, new_file)
        except Exception as e:
            print(f"Failed to move {original_file} to {new_file}: {e}")

def process_file(file):
    """
    Extract a date from the filename, reformat it, and return the new filename.
    """
    try:
        # Extract possible date.  Either 6 or 8 digits, with possible breaks in between
        # break could be any non-digit, or non-letter.
        # Should handle 2015.03.19 15.03.19 or 03.19.2015
        possible_date = re.search(r'(\d{2,4}[-_. ]?\d{2}[-_. ]?\d{2,4})', file)
        if not (possible_date and (-sub(*possible_date.span()) >= 6)):  # If the filename is empty or too short
            # "No date found in {file}"
            return None
        # Extract date from the filename using dateutil.parser
        fulldate = parser.parse(possible_date.group(0), fuzzy=True, yearfirst=True).strftime("%Y-%m-%d")
        date = reformat_date(fulldate)
        if date:
            return f"{date}_{file}"
    except ValueError:
        # No recognizable date found in the filename
        return None

def process_directory(target, test_mode):
    """
    Process all files in a directory that do not start with a number.
    """
    for file in os.listdir(target):
        if not file[0].isdigit():  # Skip files starting with a number
            full_path = os.path.join(target, file)
            newname = process_file(file)
            if newname:
                move_file(full_path, os.path.join(target, newname), test_mode)

def main():
    parser = argparse.ArgumentParser(description="Fix dates in filenames by moving dates to the beginning.")
    parser.add_argument("target", nargs="?", default=".", help="File or directory to process (default: current directory).")
    parser.add_argument("-t", "--test", action="store_true", help="Test mode: simulate file operations.")
    args = parser.parse_args()

    target = args.target
    test_mode = args.test

    if os.path.isfile(target):
        # If target is a file, process the file
        newname = process_file(os.path.basename(target))
        if newname:
            move_file(target, os.path.join(os.path.dirname(target), newname), test_mode)
    elif os.path.isdir(target):
        # If target is a directory, process each file in the directory
        process_directory(target, test_mode)
    else:
        print(f"{target} is not a valid file or directory")

if __name__ == "__main__":
    main()
