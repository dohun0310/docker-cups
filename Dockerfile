FROM ubuntu:latest

ENV USERNAME=admin PASSWORD=admin

RUN apt-get update && apt-get upgrade -y \
sudo \
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
samba \
&& rm -rf /var/lib/apt/lists/*

RUN sed -i "s/Listen localhost:631/Listen *:631/" /etc/cups/cupsd.conf && \
sed -i "s/Browsing No/Browsing On/" /etc/cups/cupsd.conf && \
sed -i "s/workgroup = WORKGROUP/workgroup = WORKGROUP\n  security = user/" /etc/samba/smb.conf

RUN useradd -r -G lpadmin -M $USERNAME && echo "$USERNAME:$PASSWORD" | chpasswd

CMD /usr/sbin/cupsd -f

EXPOSE 631

VOLUME ["/etc/cups"]