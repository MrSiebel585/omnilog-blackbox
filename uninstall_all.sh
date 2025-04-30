#!/bin/bash

# Unified uninstall script for Omnilog components

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

echo "Starting Omnilog unified uninstall..."

# --- Stop and disable file watcher service ---
SERVICE_NAME="file_watcher"
echo "Stopping and disabling $SERVICE_NAME service..."
systemctl stop "$SERVICE_NAME"
systemctl disable "$SERVICE_NAME"

# Remove file watcher service files
echo "Removing file watcher service files..."
rm -f "/usr/local/bin/$SERVICE_NAME.sh"
rm -f "/etc/rsyslog.d/$SERVICE_NAME.conf"
rm -f "/etc/systemd/system/$SERVICE_NAME.service"

# Restart rsyslog to apply changes
systemctl restart rsyslog

# --- Remove Logwatch, Logcheck, Logrotate, FWLogWatch ---
echo "Removing Logwatch, Logcheck, Logrotate, FWLogWatch packages..."
if command -v apt-get &> /dev/null; then
  apt-get remove --purge -y figlet logwatch logcheck logrotate perl awk unzip curl
elif command -v yum &> /dev/null; then
  yum remove -y figlet logwatch logcheck logrotate perl awk unzip curl
else
  echo "Unsupported package manager. Please remove packages manually."
fi

# Remove Logwatch and Logcheck configuration files
echo "Removing Logwatch and Logcheck configuration files..."
rm -f /etc/logwatch/conf/logwatch.conf
rm -f /etc/cron.daily/00logwatch
rm -f /etc/logcheck/logcheck.conf
rm -f /etc/logrotate.d/custom_logs

# Remove FWLogWatch files
echo "Removing FWLogWatch files..."
rm -rf /opt/fwlogwatch
rm -f /usr/local/bin/fwlogwatch

# --- Remove custom rsyslog filtering rules ---
echo "Removing custom rsyslog filtering rules..."
rm -f /etc/rsyslog.d/10-custom-filter.conf
systemctl restart rsyslog

# --- Remove duplicate file cleanup list if exists ---
DUPLICATE_LIST="duplicates.txt"
if [ -f "$DUPLICATE_LIST" ]; then
  echo "Removing duplicate list file $DUPLICATE_LIST..."
  rm -f "$DUPLICATE_LIST"
fi

echo "Omnilog unified uninstall completed."
