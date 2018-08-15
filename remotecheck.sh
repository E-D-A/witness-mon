#!/bin/bash

#### CONFIGURATION SECTION ####

# SSH connection string for Witness Node
witness_node=USER@IP-ADDRESS

# Binary used to disable your witness. Needs to be able to run unattended.
# If you are using Conductor or Beempy,
# call this script by setting the UNLOCK environment variable
# For example, run like this: UNLOCK=WALLETPASSPHRASE ./remotecheck.sh
manager_bin="/home/ubuntu/.local/bin/conductor disable --yes"

# Command to send an email. Need to support piping a string,
# like: echo "Test Alert" | ssmtp who@somewhere.is.me
# Uncomment and add correct address to enable email notifications
#smtp_bin="ssmtp who@somewhere.is.me"

# Host to test Internet connectivity
check_host="google.com 443"

# Filename where this script writes its logs
logpath="witness.log"

#### END OF CONFIGURATION ####

# Send an email notification that script started
# Only send email if smtp_bin is set
if [[ -n "$smtp_bin" ]]; then
{
    echo Subject: Witness Remote Monitoring
    echo Remote monitoring node $(hostname) started.
} | $smtp_bin
fi;

# Start script. Write entry to the log.
echo $(date) "- Starting script." >> $logpath

# Function to check the local Internet connection
function check_internet
{
  echo "internet check"
  for i in {1..3}
  do
    if nc -dzw2 $check_host; then
      echo $(date) "Internet is UP" >> $logpath
      return 0
    else
      echo $(date) "Internet ERROR" >> $logpath
      sleep 10
    fi;
  done

  # Local Internet issue.
  if [ $i = 3 ]; then
    echo $(date) "Local Issue. do nothing. Exit!" >> $logpath
    return 1
  fi;
}

### Begin Main Script ###
while true
do
  # Setup a loop with 5 retries in case of failures
  # Keep track of the status. Will be set to 0 in case of failures
  status=1
  for i in {1..5}
  do
    # Connect to the Witness Node to check the status
    # /tmp/status holds with the Witness node's status.
    # OK = All Good,  BAD = Witness Bad
    result=$(ssh -oBatchMode=Yes -oConnectTimeout=3 $witness_node cat /tmp/status)
    # Exit if the status is OK
    if [[ "$result" = "OK" ]]; then
    	echo $(date) "Status OK."
      break
    # The witness node returned a BAD state. Exit the loop to disable the witness
    elif [[ "$result" = "BAD" ]]; then
      echo $(date) "Witness not working..." >> $logpath
      status=0
      break
    else
    	echo $(date) "Retry SSH..." >> $logpath
      # Sleep between retries to make sure it is not a temporary issue
      sleep 15
    fi;
  done

  # If the SSH connection failed. Check if local Internet works to confirm if
  # there is a problem with the witness node or this monitoring node.
  if [[ "$result" != "BAD" ]] && [[ "$result" != "OK" ]]; then
    echo $(date) "check internet" >> $logpath
    # Run function to check Internet
    check_internet
    # Stored the result. Function returns 0 if Internet is working as it
    # would indicate there is an issue with the Witness node.
    status=$?
  fi;

  # Witness node returned an error and local Internet is working. Disable witness.
  if [ $status = 0 ]; then
    echo $(date) "disable witness" >> $logpath
    # Disable the witness.
    $manager_bin

    # Send email notification that witness is disabled
    # Only send email if smtp_bin is set
    if [[ -n "$smtp_bin" ]]; then
    {
        echo Subject: Witness Disabled!!
        echo Witness has been disabled by $(hostname).
    } | $smtp_bin
    fi;

    # Sleep so we have time to recover the witness
    sleep 86000
  fi;
# Wait some time before we check the status again.
sleep 120
done
