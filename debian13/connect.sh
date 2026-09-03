#!/bin/bash
# Load database credentials
. /etc/openvpn/login/config.sh

# Detect Server IP
server_ip=$(curl -s https://api.ipify.org)

# Date and Time formatting
datenow=$(date +"%Y-%m-%d %T")
tm=$(date +%s)
dt=$(date +'%Y-%m-%d %H:%M:%S')
timestamp=$(date +%s)

# Use --skip-ssl for all mysql commands on Debian 13
# $common_name is a variable provided by OpenVPN during connection

# Check if user already has an 'online' log
bandwidth_check=$(mysql --skip-ssl -u $USER -p$PASS -D $DB -h $HOST --skip-column-name -e "SELECT COUNT(*) FROM bandwidth_logs WHERE username='$common_name' AND status='online'")

if [ "$bandwidth_check" -gt 0 ]; then
    # Update existing online log
    mysql --skip-ssl -u $USER -p$PASS -D $DB -h $HOST -e "UPDATE bandwidth_logs SET server_ip='$trusted_ip', server_port='$trusted_port', timestamp='$timestamp', ipaddress='$trusted_ip:$trusted_port', username='$common_name', time_in='$tm', since_connected='$time_ascii', bytes_received='$bytes_received', bytes_sent='$bytes_sent' WHERE username='$common_name' AND status='online'"
    
    # Set user as connected in users table
    mysql --skip-ssl -u $USER -p$PASS -D $DB -h $HOST -e "UPDATE users SET is_connected='1', device_connected='1', active_address='$server_ip', active_date='$datenow' WHERE user_name='$common_name'"
else
    # Insert new online log
    mysql --skip-ssl -u $USER -p$PASS -D $DB -h $HOST -e "INSERT INTO bandwidth_logs (server_ip, server_port, timestamp, ipaddress, since_connected, username, bytes_received, bytes_sent, time_in, status, time) VALUES ('$trusted_ip','$trusted_port','$timestamp','$trusted_ip:$trusted_port','$time_ascii','$common_name','$bytes_received','$bytes_sent','$dt','online','$tm')"
    
    # Set user as connected in users table
    mysql --skip-ssl -u $USER -p$PASS -D $DB -h $HOST -e "UPDATE users SET is_connected='1', device_connected='1', active_address='$server_ip', active_date='$datenow' WHERE user_name='$common_name'"
fi

exit 0
