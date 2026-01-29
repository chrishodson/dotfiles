#!/bin/bash
# Polls 'pmset -g batt' and prints:
# Current time, percent, time remaining, and ETA.
# If charging, print in green.
# If discharging, print in cyan.
# If percent < 20, print in red.
# Sleep based on estimated seconds per 1% change (bounded 60–1800s);
# if unknown, wait 60s.

# Parse -d flag for debug output
DEBUG=0

handle_signal() {
    local sig="$1"
    echo "SIG${sig} received."
    if [ "$sig" = "TERM" ] || [ "$sig" = "INT" ]; then
        echo "Exiting."
        exit 0
    fi
}

trap 'handle_signal TERM' TERM
trap 'handle_signal INT' INT
trap 'handle_signal HUP' HUP

if [ "$1" = "-d" ]; then
    DEBUG=1
    shift
fi

while true; do
    # Get battery status
    output=$(pmset -g batt)
    
    # Extract percentage and time remaining
    percent=$(echo "$output" | grep -o '[0-9]\+%' | head -n 1 | tr -d '%')
    time_remaining=$(echo "$output" | grep -o '[0-9]\+:[0-9]\+' | head -n 1)
    
    # If time_remaining is blank, set to TBD
    if [ -z "$time_remaining" ]; then
        time_remaining="TBD"
    fi
    
    # Determine charging status
    if echo "$output" | grep -q "AC Power"; then
        color="\033[0;32m"  # Green for charging
    else
        color="\033[1;36m"  # Light blue (cyan) for discharging
    fi
    if [ "$percent" -lt 20 ]; then
        color="\033[0;31m"  # Red for low battery
    fi
    
    # Calculate wait time based on time remaining and percent to estimate when 1% will change
    if [[ "$time_remaining" =~ ^[0-9]+:[0-9]+$ ]] && [ "$percent" -gt 0 ]; then
        IFS=: read hours minutes <<< "$time_remaining"
        hours=$((10#$hours))
        minutes=$((10#$minutes))
        total_seconds=$(( (hours * 60 + minutes) * 60 ))
        # Estimate seconds per 1% change
        seconds_per_percent=$(( total_seconds / percent ))
        # Bound the sleep time to a minimum of 60 seconds and a maximum of 1800 seconds (30 min)
        if [ "$seconds_per_percent" -lt 60 ]; then
            wait_time=60
        elif [ "$seconds_per_percent" -gt 1800 ]; then
            wait_time=1800
        else
            wait_time=$seconds_per_percent
        fi
    else
        wait_time=60  # Default if unknown
    fi

    # Print the output with current wall clock time (HH:MM)
    current_time=$(date +"%H:%M")

    # Calculate ETA
    if [[ "$time_remaining" =~ ^[0-9]+:[0-9]+$ ]]; then
        IFS=: read eta_hours eta_minutes <<< "$time_remaining"
        eta_seconds=$(( (10#$eta_hours * 60 + 10#$eta_minutes) * 60 ))
        eta_time=$(date -v+${eta_hours}H -v+${eta_minutes}M +"%H:%M")
    else
        eta_time="TBD"
    fi

    if [ "$DEBUG" -eq 1 ]; then
        echo -e "${current_time} ${color}Battery: ${percent}% | Time Remaining: ${time_remaining} | ETA: ${eta_time}\033[0m (wait: ${wait_time}s)"
    else
        echo -e "${current_time} ${color}Battery: ${percent}% | Time Remaining: ${time_remaining} | ETA: ${eta_time}\033[0m"
    fi
    
    sleep "$wait_time"
done
