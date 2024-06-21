#!/bin/bash
# This script is called by Transmission when a download is complete

log_file="/var/log/transmission_done.log"
destination_directory="/path/to/destination"

# Logging function
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

# Check if required environment variables are set
if [[ -z "$TR_TORRENT_DIR" || -z "$TR_TORRENT_NAME" ]]; then
  log "Error: Torrent directory or name is not set."
  exit 1
fi

completed_download="$TR_TORRENT_DIR/$TR_TORRENT_NAME"

# Validate destination directory
if [[ ! -d "$destination_directory" || ! -w "$destination_directory" ]]; then
  log "Error: Destination directory does not exist or is not writable."
  exit 1
fi

# Move the completed download to a different directory
if mv "$completed_download" "$destination_directory"; then
  log "Download completed. Moved to $destination_directory"
else
  log "Error moving $completed_download to $destination_directory"
  exit 1
fi

# Call the fix_dates.sh script to fix the date in the filename
log "Fixing dates in filenames..."
if ~/bin/fix_dates.sh "$destination_directory/$TR_TORRENT_NAME"; then
  log "Successfully fixed dates in filenames."
else
  log "Failed to fix dates in filenames."
  exit 1
fi