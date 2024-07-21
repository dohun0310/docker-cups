# Set the base image to the latest version of Ubuntu
FROM ubuntu:latest

# Declare build-time arguments for the username, password, and timezone
ARG TZ=Etc/UTC
ARG USERNAME=admin
ARG PASSWORD=admin

# Update the package list, upgrade installed packages, and install necessary packages
RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
  curl \
  wget \
  cups \
  cups-client \
  cups-bsd \
  cups-filters \
  foomatic-db-compressed-ppds \
  printer-driver-all \
  printer-driver-cups-pdf \
  openprinting-ppds \
  hpijs-ppds \
  hp-ppd \
  hplip \
  avahi-daemon \
  rsync \
  python3 \
	python3-dev \
	python3-pip \
	python3-cups \
  inotify-tools \
  libxml2-utils && \
  rm -rf /var/lib/apt/lists/*

# Expose ports for CUPS and Avahi
EXPOSE 631
EXPOSE 5353

# Copy the CUPS configuration files into the temporary directory
RUN cp -rp /etc/cups /etc/cups-temp

# Declare a volume for the CUPS configuration
VOLUME /etc/cups

# Copy the entrypoint script into the container and make it executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to the custom script
CMD ["/usr/local/bin/entrypoint.sh"]

# Clean up temporary files to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*