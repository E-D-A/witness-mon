#!/bin/bash

#### CONFIGURATION SECTION ####

# Command to retrieve witness logs
check_log="docker logs --tail 20 witness"

# Command to STOP your witness
witness_stop="./run.sh stop"

# Command to START your witness
witness_start="./run.sh start"

# Command to send an email. Need to support piping a string,
# like: echo "Test Alert" | ssmtp who@somewhere.is.me
# Uncomment and add correct address to enable email notifications
#smtp_bin="ssmtp who@somewhere.is.me"

#### END OF CONFIGURATION ####

# Send an email notification that the script started
# Only send email if smtp_bin is set
if [[ -n "$smtp_bin" ]]; then
{
    echo Subject: Witness Node Monitoring
    echo Witness node $(hostname) monitoring started.
} | $smtp_bin
fi;

# Setup a loop with 3 retries in case of failures
count=0
while [ $count -lt 3 ];
do
  # Store the witness logs
	last_state=$($check_log)
  # Sleep for at least 3 blocks and check the logs again
	sleep 12
	current_state=$($check_log)
  # Compare the logs. The logs should not be the same and they should include: handle_block...
	if [[ "$last_state" != "$current_state" ]] && [[ "$current_state" = *"handle_block"* ]]; then
		echo "All OK."
    # The /tmp/status file will be checked by the remote monitor
		echo "OK" > /tmp/status
    # Wait 60 seconds until next iteration
		sleep 60
    # Reset the counter, in case we had previous temporary failures
		count=0
	else
    # Increase the counter with 1
		let "count = count + 1"
		echo "No processed blocks. Count value: $count. Stopping..."
    # Stop and start the witness.
    $witness_stop
		echo "Stopped!"
		sleep 10
		echo "Starting..."
    $witness_start
		echo "Started!"
    # Leave some time for the node to catch up after the startup
		sleep 60
	fi;
done

# Restart didn't help. Set witness status to BAD.
# /tmp/status will be read by the remote monitor
echo "Setting node status to BAD"
echo "BAD" > /tmp/status

# Send email notification that witness node is down
# Only send email if smtp_bin is set
if [[ -n "$smtp_bin" ]]; then
{
    echo Subject: Witness Node Alert!!
    echo Witness node $(hostname) not working.
    echo -e "Latest state:\n$current_state"
} | $smtp_bin
fi;

# Sleep so we have time to recover the node
sleep 86000
