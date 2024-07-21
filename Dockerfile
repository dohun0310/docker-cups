# Set the base image to the latest version of Ubuntu
FROM ubuntu:latest

# Declare build-time arguments for the username, password, and timezone
ARG TZ=Etc/UTC
ARG USERNAME=print
ARG PASSWORD=print
ENV TZ=${TZ}
ENV USERNAME=${USERNAME}
ENV PASSWORD=${PASSWORD}

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
  inotify-tools \
  libxml2-utils && \
  rm -rf /var/lib/apt/lists/*

# Expose ports for CUPS
EXPOSE 53
EXPOSE 631
EXPOSE 5353

# Copy the CUPS configuration files into the temporary directory
RUN cp -rp /etc/cups /tmp/cups

# Declare a volume for the CUPS configuration
VOLUME /etc/cups

# Copy the entrypoint script into the container and make it executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to the custom script
CMD ["/usr/local/bin/entrypoint.sh"]

# Clean up the image to reduce the size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*