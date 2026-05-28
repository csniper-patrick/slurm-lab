#!/bin/bash
# This tutorial script represents an "error handler" task that runs
# if a preceding job in the dependency chain fails.

echo "Error Handler: Something went wrong with the main process."

# Sleep indefinitely to allow for debugging
sleep infinity
