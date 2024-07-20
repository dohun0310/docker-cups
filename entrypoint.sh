#!/bin/bash

# Check if the CUPS admin user exists, and create it if it does not
if [ $(grep -ci $USERNAME /etc/shadow) -eq 0 ]; then
    useradd -r -G lpadmin -M $USERNAME

    # Add password
    echo $USERNAME:$PASSWORD | chpasswd

    # Add timezone data
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata
fi

# Restore default CUPS config in case the user does not have any
if [ ! -f /etc/cups/cupsd.conf ]; then
    echo "Copying default configuration files to /etc/cups..."
    cp -rpn /usr/share/cups/* /etc/cups/
fi

# Start CUPS daemon
exec /usr/sbin/cupsd -f