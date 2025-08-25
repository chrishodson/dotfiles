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
import sys
import fnmatch
import json
import logging
from concurrent.futures import ProcessPoolExecutor, as_completed

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


def compute_partial_hash(filepath, head_bytes=4096, tail_bytes=4096):
    """Compute a small fingerprint using head+tail bytes to prefilter identical files.
    Returns hex digest of SHA256(head + tail) or None on error.
    """
    try:
        size = os.path.getsize(filepath)
        with open(filepath, 'rb') as f:
            head = f.read(head_bytes)
            if size > head_bytes + tail_bytes:
                f.seek(max(size - tail_bytes, 0))
                tail = f.read(tail_bytes)
            else:
                # file small enough, read all
                f.seek(0)
                tail = f.read()
        h = hashlib.sha256()
        h.update(head)
        h.update(tail)
        return h.hexdigest()
    except Exception as e:
        if 'filepath' in locals():
            print(f"Error reading for partial hash {filepath}: {e}", file=sys.stderr)
        else:
            print(f"Error reading for partial hash: {e}", file=sys.stderr)
        return None

def find_files(root, follow_symlinks=False):
    for dirpath, _, filenames in os.walk(root, followlinks=follow_symlinks):
        for fname in filenames:
            yield os.path.join(dirpath, fname)

def main():
    parser = argparse.ArgumentParser(
        description="Recursively find duplicate files and report newer duplicates."
    )
    parser.add_argument("directories", nargs="*", default=["."],
                        help="One or more directories to search (default: current directory)")
    parser.add_argument("-1", action="store_true", dest="oneline",
                        help="Only print the duplicate file path")
    parser.add_argument("-w", "--workers", type=int, default=1,
                        help="Number of worker processes/threads to use (reserved, currently single-threaded)")
    parser.add_argument("--min-size", type=int, default=1,
                        help="Skip files smaller than this many bytes (default: 1)")
    parser.add_argument("-e", "--exclude", action="append", default=[],
                        help="Glob pattern to exclude (can be repeated). Patterns are matched against full path.")
    parser.add_argument("-o", "--output-file", default=None,
                        help="Write output to this file instead of stdout")
    parser.add_argument("--follow-symlinks", action="store_true",
                        help="Follow symbolic links when walking directories")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Verbose messages to stderr")
    parser.add_argument("--format", choices=("text", "json", "jsonl"), default="text",
                        help="Output format: 'text' (default), 'json' (array), or 'jsonl' (one JSON object per line)")
    parser.add_argument("--cache-file", default=None,
                        help="Path to JSON cache file to read/write partial results (stores size, mtime, hash)")
    args = parser.parse_args()

    # configure logging: verbose -> DEBUG, otherwise WARNING; send to stderr
    log_level = logging.DEBUG if args.verbose else logging.WARNING
    logging.basicConfig(level=log_level, format='%(levelname)s: %(message)s')

    # First pass: group files by file size.
    files_by_size = {}
    # counters for final summary
    files_scanned = 0
    files_hashed = 0
    cache_hits = 0
    cache_misses = 0
    groups_inspected = 0
    duplicates_found = 0
    errors_count = 0
    skipped_count = 0
    for directory in args.directories:
        if not os.path.isdir(directory):
            print(f"Warning: {directory} is not a directory, skipping.", file=sys.stderr)
            continue
        for filepath in find_files(directory, follow_symlinks=args.follow_symlinks):
            if not os.path.isfile(filepath):
                continue
            # exclude patterns
            if args.exclude and any(fnmatch.fnmatch(filepath, pat) for pat in args.exclude):
                logging.debug(f"Excluding {filepath} (matched exclude pattern)")
                skipped_count += 1
                continue
            try:
                size = os.path.getsize(filepath)
            except Exception as e:
                logging.error(f"Error getting size for {filepath}: {e}")
                continue
            if size < args.min_size:
                logging.debug(f"Skipping {filepath} (size {size} < min-size {args.min_size})")
                skipped_count += 1
                continue
            files_by_size.setdefault(size, []).append(filepath)
            files_scanned += 1

    # Now process groups with more than one file.
    master_files = {}  # mapping from file hash to (master_filepath, master_mtime)
    # Load cache if requested
    cache = {}
    cache_enabled = bool(args.cache_file)
    if cache_enabled and os.path.isfile(args.cache_file):
        try:
            with open(args.cache_file, 'r', encoding='utf-8') as cf:
                cache = json.load(cf)
        except Exception as e:
            logging.warning(f"failed to read cache file {args.cache_file}: {e}")

    # Prepare output stream
    out = None
    try:
        if args.output_file:
            out = open(args.output_file, 'w', encoding='utf-8')
        else:
            out = sys.stdout

        # container for json array when using --format json
        json_results = []

        for size, files in files_by_size.items():
            if len(files) < 2:
                continue

            # partial-hash prefilter
            partial_map = {}
            failed_partial = []
            for fp in files:
                ph = compute_partial_hash(fp)
                if ph is None:
                    failed_partial.append(fp)
                else:
                    partial_map.setdefault(ph, []).append(fp)

            # groups to inspect further: those with same partial hash (len>1) and those that failed partial
            groups = [g for g in partial_map.values() if len(g) > 1]
            if failed_partial:
                groups.append(failed_partial)

            groups_inspected += len(groups)

            for group in groups:
                # determine which files need real hashing (not in cache or changed)
                to_hash = []
                hashes = {}
                mtimes = {}
                for fp in group:
                    abs_path = os.path.abspath(fp)
                    try:
                        mtime = os.path.getmtime(fp)
                    except Exception as e:
                        logging.error(f"Error getting mtime for {fp}: {e}")
                        mtime = None
                    mtimes[fp] = mtime
                    entry = cache.get(abs_path) if cache_enabled else None
                    try:
                        size_fp = os.path.getsize(fp)
                    except Exception:
                        size_fp = None
                    if cache_enabled and entry and entry.get('size') == size_fp and entry.get('mtime') == mtime and entry.get('hash'):
                        hashes[fp] = entry['hash']
                        logging.debug(f"Using cached hash for {abs_path}")
                        cache_hits += 1
                    else:
                        to_hash.append(fp)
                        cache_misses += 1

                # compute hashes for to_hash, possibly in parallel
                if to_hash:
                    if args.workers and args.workers > 1:
                        with ProcessPoolExecutor(max_workers=args.workers) as ex:
                            future_map = {ex.submit(compute_hash, fp): fp for fp in to_hash}
                            for fut in as_completed(future_map):
                                fp = future_map[fut]
                                try:
                                    h = fut.result()
                                except Exception as e:
                                    logging.error(f"Error computing hash for {fp}: {e}")
                                    continue
                                if h is None:
                                    continue
                                hashes[fp] = h
                                if cache_enabled:
                                    cache[os.path.abspath(fp)] = {'size': os.path.getsize(fp), 'mtime': mtimes.get(fp), 'hash': h}
                                files_hashed += 1
                    else:
                        for fp in to_hash:
                            h = compute_hash(fp)
                            if h is None:
                                continue
                            hashes[fp] = h
                            if cache_enabled:
                                cache[os.path.abspath(fp)] = {'size': os.path.getsize(fp), 'mtime': mtimes.get(fp), 'hash': h}
                            files_hashed += 1

                # now process each file's hash against master_files
                for fp, file_hash in hashes.items():
                    mtime = mtimes.get(fp)
                    if file_hash not in master_files:
                        master_files[file_hash] = (fp, mtime)
                        continue
                    master_path, master_mtime = master_files[file_hash]
                    if mtime is None:
                        continue
                    if mtime < master_mtime:
                        result = {'newer': master_path, 'older': fp}
                        if args.format == 'text':
                            if args.oneline:
                                print(master_path, file=out)
                            else:
                                print(f"{master_path} ; duplicate of {fp}", file=out)
                        elif args.format == 'jsonl':
                            out.write(json.dumps(result, ensure_ascii=False) + "\n")
                        else:
                            json_results.append(result)
                        duplicates_found += 1
                        master_files[file_hash] = (fp, mtime)
                    else:
                        result = {'newer': fp, 'older': master_path}
                        if args.format == 'text':
                            if args.oneline:
                                print(fp, file=out)
                            else:
                                print(f"{fp} ; duplicate of {master_path}", file=out)
                        elif args.format == 'jsonl':
                            out.write(json.dumps(result, ensure_ascii=False) + "\n")
                        else:
                            json_results.append(result)
                        duplicates_found += 1
    finally:
        # flush JSON array if needed
        if args.format == 'json' and out:
            try:
                out.write(json.dumps(json_results, ensure_ascii=False, indent=2))
                if out is not sys.stdout:
                    out.write('\n')
            except Exception as e:
                print(f"Error writing JSON output: {e}", file=sys.stderr)

        if args.output_file and out and out is not sys.stdout:
            out.close()

        # save cache if requested
        if cache_enabled and args.cache_file:
            try:
                # prune cache to existing files only
                pruned = {k: v for k, v in cache.items() if os.path.exists(k)}
                with open(args.cache_file, 'w', encoding='utf-8') as cf:
                    json.dump(pruned, cf, ensure_ascii=False)
            except Exception as e:
                print(f"Warning: failed to write cache file {args.cache_file}: {e}", file=sys.stderr)
            # final summary to stderr
            try:
                logging.info("Summary:")
                logging.info(f" files scanned: {files_scanned}")
                logging.info(f" files hashed (this run): {files_hashed}")
                logging.info(f" cache hits: {cache_hits}")
                logging.info(f" cache misses: {cache_misses}")
                logging.info(f" groups inspected: {groups_inspected}")
                logging.info(f" duplicates found: {duplicates_found}")
                logging.info(f" skipped files: {skipped_count}")
                logging.info(f" errors: {errors_count}")
            except Exception:
                pass

if __name__ == "__main__":
    main()