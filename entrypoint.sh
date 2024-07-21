#!/bin/bash

# Set default values for USERNAME, PASSWORD, TZ, and PREFIX if they are not provided
USERNAME=${USERNAME:-print}
PASSWORD=${PASSWORD:-print}
TZ=${TZ:-Etc/UTC}

# Check if the CUPS admin user exists, and create it if it does not
if [ $(grep -ci $USERNAME /etc/shadow) -eq 0 ]; then
    useradd -r -G lpadmin -M $USERNAME

    # Add password
    echo $USERNAME:$PASSWORD | chpasswd

    # Add timezone data
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata
fi

# Restore CUPS config in case the user does not have any
if [ ! -f /etc/cups/cupsd.conf ]; then
    echo "Copying default configuration files to /etc/cups..."
    cp -rpn /etc/cups-temp/* /etc/cups/
fi

# Remove temporary directory
rm -rf /etc/cups-temp

# Modify CUPS configuration files
sed -i "s/Listen localhost:631/Listen *:631/" /etc/cups/cupsd.conf
sed -i "s/Browsing No/Browsing On/" /etc/cups/cupsd.conf
sed -i "/<\/Location>/s/.*/  Allow All\n&/" /etc/cups/cupsd.conf

# Start CUPS daemon
/usr/sbin/cupsd -f