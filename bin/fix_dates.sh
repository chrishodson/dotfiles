#!/bin/bash
# Purpose: Fix dates in filenames by moving dates to the beginning of the filenames.
# This script processes a specific file, all files in a given directory, or all top-level files and directories that do not start with a number and contain a recognizable date format.
# It does not recurse into directories unless a directory is specified as an argument.
# Usage: ./fix_dates.sh [-t] [file|directory]


reformat_date() {
  local fulldate="$1"
  local date
  local numeric=$(echo "$fulldate" | sed -r 's/[^0-9]//g')

  # Determine the format based on length after removing non-digits
  case ${#numeric} in
    8)
      if [[ "$fulldate" =~ ^[0-9]{4} ]]; then
        date=$(echo "$numeric" | sed -r 's/(..)(..)(..)(..)/\2.\3.\4/') # yyyyMMdd to yy.mm.dd
      else
        date=$(echo "$numeric" | sed -r 's/(..)(..)(..)(..)/\4.\1.\2/') # mmddyyyy to yy.mm.dd
      fi
      ;;
    6)
      if [ $(echo "$numeric" | sed -r 's/(..)/\1'/ ) -gt 12 ]; then
        date=$(echo "$numeric" | sed -r 's/(..)(..)(..)/\1.\2.\3/') # yymmdd to yy.mm.dd
      else
        date=$(echo "$numeric" | sed -r 's/(..)(..)(..)/\3.\1.\2/') # mmddyy to yy.mm.dd
      fi
      ;;
    *)
      echo "Unrecognized date format: $fulldate" >&2
      return 1
      ;;
  esac

  echo "$date"
}

move_file() {
  local original_file="$1"
  local new_file="$2"

  if [ "$TEST_MODE" -eq 1 ]; then
    echo "Would move $original_file to $new_file" >&2
  else
    if ! mv -n "$original_file" "$new_file" 2>/dev/null; then
      echo "Failed to move $original_file to $new_file" >&2
    fi
  fi  
}

process_file() {
  local newname=""
  local file="$1"
  # date extraction
  local fulldate=$(echo "$file" | grep -oP '\d{2,4}\D{0,1}\d{2}\D{0,1}\d{2,4}')
  if [ -z "$fulldate" ]; then
    # No date found in $file, skipping
    return
  fi

  # Call reformat_date function correctly and capture its output
  local date=$(reformat_date "$fulldate")
  if [ -z "$date" ]; then
    echo "Failed to reformat date for $file, skipping..." >&2
    return
  fi

  # return new filename with date at the beginning
  echo "${date}_${file}"
}

# Parse command-line arguments
TEST_MODE=0

while getopts ":tc:" opt; do
  case ${opt} in
    t )
      TEST_MODE=1
      ;;
    c )
      # Command mode for testing
      COMMAND="$OPTARG"
      eval "$COMMAND"
      exit
      ;;
    \? )
      echo "Invalid option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Support for non-option argument
if [ ! -z "$1" ]; then
  TARGET="$1"
fi

# Check if TARGET is set, otherwise default to current directory
if [ -z "$TARGET" ]; then
  TARGET="."
fi

if [ -f "$TARGET" ] ; then
  # If TARGET is a file, process the file
  newname=$(process_file "$TARGET")
  if [ -n "$newname" ]; then
    move_file "$TARGET" "$newname"
  fi
elif [ -d "$TARGET" ]; then
  # If TARGET is a directory, process each file in the directory
  find $TARGET -maxdepth 1 ! -name '[0-9]*' \
            | while IFS= read -r file; do
    newname=$(process_file $(basename "$file") )
    if [ -n "$newname" ]; then
      move_file "$file" "$TARGET/$newname"
    fi

  done
else
  echo "$TARGET is not a valid file or directory"
fi  
