#!/bin/bash

# Setup script for cron job

SCRIPT_PATH="/Users/raquelwork/Documents/reading-list-curator/run_and_push.sh"

echo "Setting up cron job for reading list curator..."
echo ""
echo "This will run the script once daily at 10 AM"
echo ""
echo "To install, run:"
echo "  crontab -e"
echo ""
echo "Then add this line:"
echo ""
echo "# Reading List Curator - runs daily at 10 AM"
echo "0 10 * * * $SCRIPT_PATH >> /tmp/reading-list-curator.log 2>&1"
echo ""
echo "To check if it's installed:"
echo "  crontab -l"
echo ""
echo "To view logs:"
echo "  tail -f /tmp/reading-list-curator.log"
echo ""
echo "To remove the cron job:"
echo "  crontab -e (then delete the line)"