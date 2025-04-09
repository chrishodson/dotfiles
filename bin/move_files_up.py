#!/bin/env python3
from pathlib import Path
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
            shutil.move(str(original_file), str(new_file))
        except Exception as e:
            print(f"Failed to move {original_file} to {new_file}: {e}")

def process_directory(directory, test_mode):
    """
    Scan the given directory for subdirectories. If a subdirectory contains only one file,
    move that file up one level and rename it as 'directory.ext'.
    """
    directory = Path(directory)

    for dir_path in directory.iterdir():
        if dir_path.is_dir() and not dir_path.name.startswith('.'):
            try:
                dir_contents = list(dir_path.iterdir())
            except PermissionError:
                print(f"Error: Cannot access {dir_path}. Skipping...")
                continue

            # Check if the directory contains exactly one file
            if len(dir_contents) == 1 and dir_contents[0].is_file():
                file_path = dir_contents[0]
                file_ext = file_path.suffix  # Get the file extension
                new_name = f"{dir_path.name}{file_ext}"
                new_path = directory / new_name

                if new_path.exists():
                    print(f"Error: {new_path} already exists. Skipping {file_path}.")
                else:
                    move_file(file_path, new_path, test_mode)

                # Remove the directory if it is empty
                if not any(dir_path.iterdir()):
                    if test_mode:
                        print(f"Would remove empty directory: {dir_path}")
                    else:
                        dir_path.rmdir()

def main():
    parser = argparse.ArgumentParser(description="Move single files from subdirectories up one level, renaming them as 'directory.ext'.")
    parser.add_argument("directory", nargs="?", default=".", help="Directory to process (default: current directory).")
    parser.add_argument("-t", "--test", action="store_true", help="Test mode: simulate file operations.")

    args = parser.parse_args()
    test_mode = args.test

    process_directory(args.directory, test_mode)

if __name__ == "__main__":
    main()
