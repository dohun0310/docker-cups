# CUPS print server for Docker

## Usage

### Default

```bash
docker run -d --network host --name cups dohun0310/cups
```

The default username/password for the Cups server is `print`/`print`

mDNS is a multicast protocol and does not pass through Docker's bridge network, so `--network host` is required for AirPrint discovery. Without it the web interface still works, but iOS devices will not find the printer.

### Custom

```bash
docker run -d --network host -v $(pwd):/etc/cups -e TZ=Asia/Seoul -e USERNAME=user -e PASSWORD=password --name cups dohun0310/cups
```

You can specify your own username and password. You can access `/etc/cups`.

### Without host networking

```bash
docker run -d -p 631:631/tcp -p 5353:5353/udp -e ADVERTISE_HOST=192.168.0.10 --name cups dohun0310/cups
```

Set `ADVERTISE_HOST` to an address clients can reach, otherwise the AirPrint record points at the container's internal IP. AirPrint discovery may still be unavailable in this mode.

### Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `TZ` | `Etc/UTC` | Container timezone |
| `USERNAME` | `print` | CUPS admin user |
| `PASSWORD` | `print` | CUPS admin password |
| `ADVERTISE_HOST` | container IP | Host advertised to AirPrint clients |

## How to Add Printers to the CUPS Server

Adding printers to your CUPS (Common UNIX Printing System) server can be a simple and straightforward process when you follow these steps. Here's a detailed, step-by-step guide to help you through the process:

### Connect to the CUPS Server

Launch your preferred web browser on your computer. Type the following URL into the address bar of your web browser and press Enter: [http://127.0.0.1:631](http://127.0.0.1:631) You should now see the CUPS server web interface. This is where you will manage your printers.

### Add a Printer

On the CUPS web interface, locate and click on the "Administration" tab. This is typically found at the top of the page. Under the "Administration" section, look for the "Printers" category and click on it. This will take you to the printer management page.
Add a New Printer: Look for an option or button that says "Add Printer" and click on it. This will initiate the printer setup process.

### Follow the Printer Setup Wizard

If prompted, enter your administrative username and password to proceed. You will be presented with a list of available printers. Select the printer you wish to add from the list. If your printer is not listed, ensure it is properly connected and powered on. Follow the prompts to configure your printer settings. This may include selecting the printer model, entering a name and description for the printer, and configuring other settings such as the location and driver. After configuring the necessary settings, review your selections and click on the "Add Printer" or "Finish" button to complete the setup process.

### Test the Printer

Once the printer is added, it's a good idea to print a test page to ensure that everything is set up correctly. Look for an option to print a test page in the printer's configuration page on the CUPS interface.  Check the printer to see if the test page prints successfully. If there are any issues, you may need to revisit the configuration settings or consult the printer's manual for troubleshooting tips.

By following these detailed steps, you should be able to add a printer to your CUPS server without any issues. If you encounter any difficulties, don't hesitate to seek additional help or refer to the CUPS documentation for further guidance.

## Included package

* cups, cups-client, cups-filters, cups-bsd, foomatic-db-compressed-ppds
* printer-driver-all, printer-driver-cups-pdf, openprinting-ppds, hpijs-ppds, hplip
* avahi-daemon, avahi-utils, libnss-mdns, inotify-tools, libxml2-utils
* ca-certificates, curl, wget