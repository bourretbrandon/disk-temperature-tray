# disk-temperature-tray
SMART Disk Temperature Tray/App-Indicator for Linux

A very basic tray app indicator to monitor SMART disk temperature. I have a gaming laptop, and the recommended max temperature for my
NVME & SSD devices is around 70°C. However, the GPU and CPU can run as high as 90°C while playing some games. Even with fans and cooling
pads, it can get fairly hot inside the laptop, and this heat can bleed over into other components. So I decided I'd like to see the
temperatures of my NVME/SSD drives in the tray. "hddtemp" can get the temperature of my SSD drive (after manually adding it to the
device database). But it can't register my NVME drive. "smartctl" can do both. So that's the solution I use here.

Written in Perl using Gtk2 and libappindicator

Prerequisites for Linux System:

 - Gtk2, libappindicator, Perl, and smartctl (and its dependencies)

Prerequisites (modules) for Perl:
 
 - File::Spec
 
 - GD
 
 - Glib
 
 - Gtk2
 
 - Gtk2::AppIndicator
 
 - Path::Tiny

Usage:

- Must be run with sudo/root permission (because smartctl requires sudo/root)

- sudo disk-temp-tray [block device] (or sudo disk-temp-tray.pl [block device])

- sudo disk-temp-tray /dev/sda (or sudo disk-temp-tray.pl /dev/sda)

- sudo disk-temp-tray /dev/nvme0n1 (or sudo disk-temp-tray.pl /dev/nvme0n1)

I develop using ActivePerl (don't laugh, it's rapid development!) and "compile" with ActiveState's Perl Dev Kit (PDK).

Linux 64-bit: https://www.dropbox.com/s/21xd0yrbx3pkr15/disk-temp-tray?dl=0
 
