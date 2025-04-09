#!/usr/bin/env python3
"""
Script to find duplicate files recursively.
By default, for each duplicate file it outputs:
   newer_file ; duplicate of older_file
If the "-1" flag is set, only the duplicate (newer) file path is printed.
Optimized by first grouping files by file size.
"""
import os
import hashlib
import argparse

def compute_hash(filepath, block_size=65536):
    hasher = hashlib.sha256()
    try:
        with open(filepath, 'rb') as f:
            for block in iter(lambda: f.read(block_size), b''):
                hasher.update(block)
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return None
    return hasher.hexdigest()

def find_files(root):
    for dirpath, _, filenames in os.walk(root):
        for fname in filenames:
            yield os.path.join(dirpath, fname)

def main():
    parser = argparse.ArgumentParser(
        description="Recursively find duplicate files and report newer duplicates."
    )
    parser.add_argument("directory", nargs="?", default=".",
                        help="Directory to search (default: current directory)")
    parser.add_argument("-1", action="store_true", dest="oneline",
                        help="Only print the duplicate file path")
    args = parser.parse_args()

    # First pass: group files by file size.
    files_by_size = {}
    for filepath in find_files(args.directory):
        if os.path.isfile(filepath):
            try:
                size = os.path.getsize(filepath)
            except Exception as e:
                print(f"Error getting size for {filepath}: {e}")
                continue
            files_by_size.setdefault(size, []).append(filepath)

    # Now process groups with more than one file.
    master_files = {}  # mapping from file hash to (master_filepath, master_mtime)
    for size, files in files_by_size.items():
        if len(files) < 2:
            continue  # no potential duplicates
        for filepath in files:
            file_hash = compute_hash(filepath)
            if file_hash is None:
                continue
            try:
                mtime = os.path.getmtime(filepath)
            except Exception as e:
                print(f"Error getting mtime for {filepath}: {e}")
                continue

            # If no file with this hash has been seen, store as master.
            if file_hash not in master_files:
                master_files[file_hash] = (filepath, mtime)
            else:
                master_path, master_mtime = master_files[file_hash]
                if mtime < master_mtime:
                    # New file is older; report previous master as duplicate.
                    if args.oneline:
                        print(master_path)
                    else:
                        print(f"{master_path} ; duplicate of {filepath}")
                    # Update the master.
                    master_files[file_hash] = (filepath, mtime)
                else:
                    if args.oneline:
                        print(filepath)
                    else:
                        print(f"{filepath} ; duplicate of {master_path}")

if __name__ == "__main__":
    main()