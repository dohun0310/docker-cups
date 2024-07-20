# CUPS print server for Docker

## Usage

### Default

```bash
docker run -d -p 631:631 -p 5353:5353 --name cups dohun0310/cups
```

The default username/password for the Cups server is `print`/`print`

### Custom

```bash
docker run -d -p 631:631 -p 5353:5353 -v $(pwd):/etc/cups -e TZ=Asia/Seoul -e USERNAME=user -e PASSWORD=password --name cups dohun0310/cups`
```

You can specify your own username and password. You can access `/etc/cups`. 

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

* sudo, curl, wget
* cups, cups-client, cups-filters, cups-bsd, cups-filters
* foomatic-db
* printer-driver-all, printer-driver-cups-pdf, openprinting-ppds, hpijs-ppds, hp-ppd
* avahi-daemon, rsync, inotify-tools, libxml2-utils