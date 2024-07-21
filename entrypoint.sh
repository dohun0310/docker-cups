#!/bin/bash

# Set default values for TZ, USERNAME, PASSWORD if they are not provided
TZ=${TZ:-Etc/UTC}
USERNAME=${USERNAME:-print}
PASSWORD=${PASSWORD:-print}

# Create CUPS admin user if it does not exist
if [ $(grep -ci $USERNAME /etc/shadow) -eq 0 ]; then
    useradd -r -G lpadmin -M $USERNAME
    echo $USERNAME:$PASSWORD | chpasswd
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata
fi

# Restore default CUPS config if not present
if [ ! -f /etc/cups/cupsd.conf ]; then
    echo "Copying default configuration files to /etc/cups..."
    cp -rpn /tmp/cups/* /etc/cups/
fi
rm -rf /tmp/* /var/tmp/*

# Configure CUPS and Avahi
rm -rf /etc/avahi/services/*
sed -i "s/Listen localhost:631/Listen *:631/" /etc/cups/cupsd.conf
sed -i "s/Browsing No/BrowseWebIF Yes\nBrowsing Yes/" /etc/cups/cupsd.conf
sed -i "s/<Location \/>/<Location \/>\n  Allow All/" /etc/cups/cupsd.conf
sed -i "s/<Location \/admin>/<Location \/admin>\n  Allow All/" /etc/cups/cupsd.conf
sed -i "s/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/" /etc/cups/cupsd.conf
sed -i "s/<Location \/admin\/log>/<Location \/admin\/log>\n  Allow All/" /etc/cups/cupsd.conf
sed -i "s/.*enable\-dbus=.*/enable\-dbus\=no/" /etc/avahi/avahi-daemon.conf

# Start CUPS and Avahi daemons
/usr/sbin/cupsd -f &
/usr/sbin/avahi-daemon --daemonize

# Function to generate AirPrint service files based on printer info
generate_airprint_service() {
    echo "Generating AirPrint service file for $1"
    local PRINTER_NAME="$1"
    local PRINTER_INFO="$2"
    local PRINTER_STATE="$3"
    local PRINTER_TYPE="$4"
    local OUTPUT_FILE="/etc/avahi/services/AirPrint-${PRINTER_NAME}.service"

    cat <<EOF > "$OUTPUT_FILE"
<?xml version="1.0" standalone="no"?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
<name replace-wildcards="yes">${PRINTER_NAME}</name>
<service>
    <type>_ipp._tcp</type>
    <subtype>_universal._sub._ipp._tcp</subtype>
    <port>631</port>
    <txt-record>txtvers=1</txt-record>
    <txt-record>qtotal=1</txt-record>
    <txt-record>Transparent=T</txt-record>
    <txt-record>URF=none</txt-record>
    <txt-record>rp=printers/${PRINTER_NAME}</txt-record>
    <txt-record>note=${PRINTER_INFO}</txt-record>
    <txt-record>product=(GPL Ghostscript)</txt-record>
    <txt-record>printer-state=${PRINTER_STATE}</txt-record>
    <txt-record>printer-type=${PRINTER_TYPE}</txt-record>
    <txt-record>Color=T</txt-record>
    <txt-record>pdl=application/octet-stream,application/pdf,application/postscript,application/vnd.cups-raster,image/gif,image/jpeg,image/png,image/tiff,image/urf,text/html,text/plain,application/vnd.adobe-reader-postscript,application/vnd.cups-pdf</txt-record>
</service>
</service-group>
EOF
}

# Function to retrieve printer attributes from CUPS
get_printer_attributes() {
    echo "New printer detected: $1"
    local PRINTER_NAME="$1"
    local PRINTER_INFO=$(lpstat -l -p "$PRINTER_NAME" | grep "Description" | cut -d: -f2 | xargs)
    local PRINTER_STATE=$(lpstat -p "$PRINTER_NAME" | grep "enabled" >/dev/null && echo "3" || echo "5")
    local PRINTER_TYPE=$(lpoptions -p "$PRINTER_NAME" | grep -oP 'printer-type=\K[0-9a-fA-F]+')

    generate_airprint_service "$PRINTER_NAME" "$PRINTER_RP" "$PRINTER_INFO" "$PRINTER_STATE" "$PRINTER_TYPE"
}

# Handle changes in CUPS configuration
/usr/bin/inotifywait -m -e close_write,moved_to,create /etc/cups |
while read -r directory events filename; do
    if [ "$filename" = "printers.conf" ]; then
        echo "Changes detected in printers.conf"
        rm -rf /etc/avahi/services/AirPrint-*.service
        for printer in $(lpstat -p | awk '{print $2}'); do
            get_printer_attributes "$printer"
        done
        chmod 755 /var/cache/cups
        rm -rf /var/cache/cups/*
    fi
done