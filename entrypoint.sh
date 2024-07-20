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

# Check if /etc/cup contains files and /etc/cups does not
if [ "$(ls -A /etc/cup)" ] && [ ! "$(ls -A /etc/cups)" ]; then
    echo "Copying configuration files from /etc/cup to /etc/cups..."
    cp -rpn /etc/cup/* /etc/cups/
fi

# Check if both /etc/cup and /etc/cups are empty
if [ ! "$(ls -A /etc/cup)" ] && [ ! "$(ls -A /etc/cups)" ]; then
    echo "Both /etc/cup and /etc/cups are empty. Copying default configuration files to /etc/cups..."
    cp -rpn /usr/share/cups/* /etc/cups/
fi

# Start CUPS daemon
exec /usr/sbin/cupsd -f