#!/bin/bash
# Example script on how to run a command once an hour

CMD='echo $(date)'

# Run the command at the same minute every hour.  Determine the minute based on the hostname.
# This will help to spread out the load
# Initialize MINUTE with a default value based on the hostname
MINUTE=$(hostname | md5sum | awk '{print $1}' | od -t uL -An -N4 | awk '{print $1 % 60}') # 0-59

# Parse command-line options
while getopts "m:" opt; do
  case $opt in
    # Allow the user to override the minute with -m <minute>
    m) MINUTE=$OPTARG ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Ensure MINUTE is within the expected range
if ! [[ $MINUTE =~ ^[0-5]?[0-9]$ ]] || [ $MINUTE -lt 1 ] || [ $MINUTE -gt 59 ]; then
  echo "Minute must be between 01 and 59.  Got: $MINUTE"
  exit 1
fi
printf -v MINUTE "%02d" $MINUTE # pad with zero if needed
echo "Hostname: $(hostname).  Minute: $MINUTE"

while true; do
  # Calculate current time and target time in seconds since epoch
  current_time=$(date +%s)
  target_time=$(date -d "$(date +'%Y-%m-%d %H:')$MINUTE:00" +%s)

  # If current time is past the target minute, set target to the next hour
  if [ "$current_time" -ge "$target_time" ]; then
    target_time=$(date -d "$(date -d @$target_time) + 1 hour" +%s)
  fi

  # Calculate sleep time and sleep
  sleep_time=$((target_time - current_time))
  echo "Sleeping for $(( ($sleep_time + 30) / 60 )) minutes until $(date -d "@$target_time" +'%H:%M')"
  sleep $sleep_time

  # run the command
  eval $CMD
  return_code=$?
  if [ $return_code -ne 0 ]; then
    echo "Error($return_code) running command at $(date)"
    echo "Command: $CMD"
    exit $return_code
  fi
  #echo "Done at $(date +%H:%M). Sleeping until $(date +%H -d '+1 hour' ):$MINUTE"
  sleep 1 # sleep for 1 second to avoid running the command twice in the same minute
done