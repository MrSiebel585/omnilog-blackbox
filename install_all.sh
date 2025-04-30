#!/bin/bash

# Unified installation and configuration script for Omnilog components

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

echo "Starting Omnilog unified installation and configuration..."

# --- init.dupactionlog functionality ---
echo "Running duplicate file cleanup setup..."
DUPLICATE_LIST="duplicates.txt"
if [ ! -f "$DUPLICATE_LIST" ]; then
    echo "Duplicate list file '$DUPLICATE_LIST' not found. Skipping duplicate cleanup."
else
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            echo "Deleting duplicate file: $file"
            rm "$file"
        else
            echo "File not found: $file"
        fi
    done < "$DUPLICATE_LIST"
fi

# --- init.filewatch functionality ---
echo "Setting up file watcher service..."
DIRECTORY_TO_WATCH="/path/to/monitor"
SERVICE_NAME="file_watcher"
LOG_FILE="/var/log/file_watcher.log"

# Install fswatch if not installed
if ! command -v fswatch &> /dev/null; then
    echo "Installing fswatch..."
    apt-get update
    apt-get install -y fswatch
fi

mkdir -p "$DIRECTORY_TO_WATCH"

SERVICE_SCRIPT="/usr/local/bin/$SERVICE_NAME.sh"
cat > "$SERVICE_SCRIPT" <<EOF
#!/bin/bash
fswatch -r "$DIRECTORY_TO_WATCH" | while read file_event; do
    logger -t $SERVICE_NAME "\$file_event"
done
EOF
chmod +x "$SERVICE_SCRIPT"

RSYSLOG_CONFIG="/etc/rsyslog.d/$SERVICE_NAME.conf"
cat > "$RSYSLOG_CONFIG" <<EOF
if \$programname == '$SERVICE_NAME' then "$LOG_FILE"
& stop
EOF

systemctl restart rsyslog

SYSTEMD_UNIT="/etc/systemd/system/$SERVICE_NAME.service"
cat > "$SYSTEMD_UNIT" <<EOF
[Unit]
Description=$SERVICE_NAME Service

[Service]
ExecStart=$SERVICE_SCRIPT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"
echo "File watcher service installed and started."

# --- init.logwatch functionality ---
echo "Installing and configuring Logwatch, Logcheck, and Logrotate..."

apt-get update
apt-get install -y figlet logwatch logcheck logrotate perl awk unzip curl

figlet "Omnilog"

read -p "Enter the email address for Logwatch and Logcheck reports: " email
if [ -z "$email" ]; then
  echo "Email address is required for report delivery. Exiting."
  exit 1
fi

cat > /etc/logwatch/conf/logwatch.conf <<EOF
MailTo = $email
MailFrom = logwatch@omniscient.lan
Print = Yes
Range = yesterday
Detail = High
Service = All
EOF

cat > /etc/cron.daily/00logwatch <<EOF
#!/bin/bash
/usr/sbin/logwatch --output mail
EOF
chmod +x /etc/cron.daily/00logwatch

cat > /etc/logcheck/logcheck.conf <<EOF
REPORTLEVEL="server"
SENDMAILTO="$email"
EOF

read -p "Enter space-separated log files for Logrotate: " log_files
if [ -z "$log_files" ]; then
  echo "No log files specified for Logrotate. Skipping."
else
  cat > /etc/logrotate.d/custom_logs <<EOF
$log_files {
    rotate 7
    daily
    compress
    missingok
    notifempty
    create 640 root adm
}
EOF
fi

# FWLogWatch installation
echo "Installing FWLogWatch..."
fwlogwatch_dir="/opt/fwlogwatch"
mkdir -p "$fwlogwatch_dir"
cd "$fwlogwatch_dir"

fwlogwatch_url="https://github.com/firehol/fwlogwatch/archive/master.zip"
fwlogwatch_zip="fwlogwatch.zip"

curl -L -o "$fwlogwatch_zip" "$fwlogwatch_url"
unzip "$fwlogwatch_zip"
rm -f "$fwlogwatch_zip"

mv "fwlogwatch-master" "fwlogwatch"
ln -sf "$fwlogwatch_dir/fwlogwatch/fwlogwatch.pl" "/usr/local/bin/fwlogwatch"

read -p "Enter the path to your firewall log file (e.g., /var/log/firewall.log): " firewall_log_path
if [ -z "$firewall_log_path" ]; then
  echo "Firewall log path is required. Exiting."
  exit 1
fi

cat > "$fwlogwatch_dir/fwlogwatch/fwlogwatch.conf" <<EOF
logfile = $firewall_log_path
EOF

echo "FWLogWatch installed and configured."

# --- Rsyslog filtering rules ---
echo "Configuring basic rsyslog filtering rules..."

custom_rsyslog_conf="/etc/rsyslog.d/10-custom-filter.conf"
cat > "$custom_rsyslog_conf" <<EOF
# Filter and separate log messages based on facility

auth.* /var/log/auth.log
cron.* /var/log/cron.log
kern.* /var/log/kern.log
EOF

systemctl restart rsyslog

echo "Basic rsyslog filtering rules configured."

echo "Omnilog unified installation and configuration completed."
