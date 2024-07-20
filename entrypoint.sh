#!/bin/bash

# Check if /etc/cups is empty and copy default configuration if necessary
if [ -z "$(ls -A /etc/cups)" ]; then
  echo "/etc/cups is empty, copying default configuration files..."
  cp -r /usr/share/cups/* /etc/cups/
fi

# Add user and set password
USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}
useradd -r -G lpadmin -M $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Start CUPS daemon
exec /usr/sbin/cupsd -f