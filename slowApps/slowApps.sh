#!/bin/bash

# Function to apply taskpolicy and renice to all Chrome processes
apply_policies() {
  for pid in $(pgrep -f "Google Chrome"); do
    echo "Applying policies to PID: $pid"
    taskpolicy -b -p $pid
    renice 20 -p $pid
  done
}

# Run the function initially
apply_policies

# Monitor for new Chrome processes every 5 seconds
while true; do
  apply_policies
  sleep 1
done
