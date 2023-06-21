#!/bin/bash

echo "======================= Clearing Systemd Journal =========================="
sudo journalctl --vacuum-time=7days
# automatically clear log when it reached the certain size
sudo journalctl --vacuum-size=100M

echo "=========================== Clearing APT cache ============================"
sudo du -sh /var/cache/apt
sudo du -sh /var/lib/apt/lists
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove

echo "=============== Removing older versions of Snap applications =============="
du -h /var/lib/snapd/snaps # Show the size of the snap packages

bash remove-old-snap.sh
