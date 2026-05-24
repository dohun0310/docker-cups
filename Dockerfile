# Set the base image to the latest version of Ubuntu
FROM ubuntu:latest

# Declare build-time arguments for the username, password, and timezone
ARG TZ=Etc/UTC
ARG USERNAME=print
ARG PASSWORD=print
ENV TZ=${TZ} \
    USERNAME=${USERNAME} \
    PASSWORD=${PASSWORD} \
    DEBIAN_FRONTEND=noninteractive

# Update the package list, upgrade installed packages, and install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      avahi-daemon \
      avahi-utils \
      ca-certificates \
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
      hplip \
      inotify-tools \
      libxml2-utils && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Expose ports for CUPS
EXPOSE 631 5353

# Copy the CUPS configuration files into the temporary directory
RUN cp -rp /etc/cups /tmp/cups

# Declare a volume for the CUPS configuration
VOLUME /etc/cups

# Copy the entrypoint script into the container and make it executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to the custom script
CMD ["/usr/local/bin/entrypoint.sh"]
