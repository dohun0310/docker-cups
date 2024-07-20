#!/bin/bash

# Set default values for USERNAME, PASSWORD, TZ, DIRECTORY, and PREFIX if they are not provided
USERNAME=${USERNAME:-print}
PASSWORD=${PASSWORD:-print}
TZ=${TZ:-Etc/UTC}
DIRECTORY=${DIRECTORY:-/services}
PREFIX=${PREFIX:-AirPrint-}
VERBOSE=${VERBOSE:-false}

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

# Modify the CUPS configuration files
sed -i "s/Listen localhost:631/Listen *:631/" /etc/cups/cupsd.conf
sed -i "s/Browsing No/Browsing On/" /etc/cups/cupsd.conf

# Start the CUPS daemon
exec /usr/sbin/cupsd -f

# Ensure required tools are available
command -v lpstat >/dev/null 2>&1 || { echo >&2 "lpstat command not found. Ensure CUPS is installed."; exit 1; }
command -v lpoptions >/dev/null 2>&1 || { echo >&2 "lpoptions command not found. Ensure CUPS is installed."; exit 1; }
command -v xmllint >/dev/null 2>&1 || { echo >&2 "xmllint command not found. Please install it and try again."; exit 1; }
command -v inotifywait >/dev/null 2>&1 || { echo >&2 "inotifywait command not found. Please install it and try again."; exit 1; }

# Function to generate service file
generate_service_file() {
    PRINTER_NAME=$1
    SERVICE_FILE="${DIRECTORY}/${PREFIX}${PRINTER_NAME}.service"
    PRINTER_INFO=$(lpoptions -p "$PRINTER_NAME" -l | grep -m 1 'printer-info' | cut -d '=' -f 2)
    PRINTER_URI=$(lpstat -v "$PRINTER_NAME" | awk '{print $4}')

    # Create XML template
    cat <<EOF > "$SERVICE_FILE"
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
    <name replace-wildcards="yes">AirPrint ${PRINTER_NAME} @ %h</name>
    <service>
        <type>_ipp._tcp</type>
        <subtype>_universal._sub._ipp._tcp</subtype>
        <port>${CUPS_PORT}</port>
        <txt-record>txtvers=1</txt-record>
        <txt-record>qtotal=1</txt-record>
        <txt-record>Transparent=T</txt-record>
        <txt-record>URF=none</txt-record>
        <txt-record>rp=${PRINTER_URI}</txt-record>
        <txt-record>note=${PRINTER_INFO}</txt-record>
        <txt-record>product=(GPL Ghostscript)</txt-record>
    </service>
</service-group>
EOF

    # Fetch printer attributes
    PRINTER_ATTRIBUTES=$(lpoptions -p "$PRINTER_NAME" -l)
    PRINTER_STATE=$(echo "$PRINTER_ATTRIBUTES" | grep -m 1 'printer-state' | cut -d '=' -f 2)
    PRINTER_TYPE=$(echo "$PRINTER_ATTRIBUTES" | grep -m 1 'printer-type' | cut -d '=' -f 2)
    COLOR_SUPPORTED=$(echo "$PRINTER_ATTRIBUTES" | grep -m 1 'ColorSupported' | cut -d '=' -f 2)
    MEDIA_DEFAULT=$(echo "$PRINTER_ATTRIBUTES" | grep -m 1 'media-default' | cut -d '=' -f 2)
    DOCUMENT_FORMATS=$(echo "$PRINTER_ATTRIBUTES" | grep -m 1 'document-format-supported' | cut -d '=' -f 2)

    # Add additional XML entries
    if [ "$COLOR_SUPPORTED" = "True" ]; then
        echo '        <txt-record>Color=T</txt-record>' >> "$SERVICE_FILE"
    fi

    if [ "$MEDIA_DEFAULT" = "iso_a4_210x297mm" ]; then
        echo '        <txt-record>PaperMax=legal-A4</txt-record>' >> "$SERVICE_FILE"
    fi

    if [ -n "$PRINTER_STATE" ]; then
        echo "        <txt-record>printer-state=${PRINTER_STATE}</txt-record>" >> "$SERVICE_FILE"
    fi

    if [ -n "$PRINTER_TYPE" ]; then
        echo "        <txt-record>printer-type=${PRINTER_TYPE}</txt-record>" >> "$SERVICE_FILE"
    fi

    if [ -n "$DOCUMENT_FORMATS" ]; then
        echo "        <txt-record>pdl=${DOCUMENT_FORMATS}</txt-record>" >> "$SERVICE_FILE"
    fi

    # Complete the XML file
    echo '</service>' >> "$SERVICE_FILE"
    echo '</service-group>' >> "$SERVICE_FILE"

    # Print output
    if [ "$VERBOSE" = true ]; then
        echo "Created: $SERVICE_FILE"
    fi
}

# Check and create service file directory if needed
if [ ! -d "$DIRECTORY" ]; then
    mkdir -p "$DIRECTORY"
fi

# Initial service file generation for existing printers
PRINTERS=$(lpstat -v | awk '{print $3}' | tr -d ':')
for PRINTER in $PRINTERS; do
    generate_service_file "$PRINTER"
done

# Monitor /etc/cups directory for changes
/usr/bin/inotifywait -m -e close_write,moved_to,create /etc/cups |
while read -r directory events filename; do
    if [ "$filename" = "printers.conf" ]; then
        rm -rf /services/AirPrint-*.service
        PRINTERS=$(lpstat -v | awk '{print $3}' | tr -d ':')
        for PRINTER in $PRINTERS; do
            generate_service_file "$PRINTER"
        done
        rsync -avh /services/ /etc/avahi/services/
        chmod 755 /var/cache/cups
        rm -rf /var/cache/cups/*
    fi
    if [ "$filename" = "cupsd.conf" ]; then
        echo "cupsd.conf changed but no action needed in this script."
    fi
done