#!/bin/env python3
import os
import shutil
import argparse

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


def move_files_up(directory, test_mode):
    """
    Move files from subdirectories up one level, renaming them as 'dir_file.ext'.
    """
    for root, dirs, files in os.walk(directory):
        for dir_name in dirs:
            dir_path = os.path.join(root, dir_name)
            for file_name in os.listdir(dir_path):
                file_path = os.path.join(dir_path, file_name)
                if os.path.isfile(file_path):
                    # Construct the new file name
                    new_name = f"{dir_name}_{file_name}"
                    new_path = os.path.join(root, new_name)

                    if os.path.exists(new_path):
                        print(f"Error: {new_path} already exists. Skipping {file_path}.")
                    else:
                        move_file(file_path, new_path, test_mode)

def main():
    parser = argparse.ArgumentParser(description="Move files up one level, renaming them as 'dir_file.ext'.")
    parser.add_argument("directory", nargs="?", default=".", help="Directory to process (default: current directory).")
    parser.add_argument("-t", "--test", action="store_true", help="Test mode: simulate file operations.")

    args = parser.parse_args()
    test_mode = args.test

    move_files_up(args.directory, test_mode)

if __name__ == "__main__":
    main()
