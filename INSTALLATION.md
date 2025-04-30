# Syslog Processor Service Installation and Usage

## Prerequisites

- Linux-based operating system
- Python 3.6 or higher
- Git
- Systemd

## Installation Steps

1. Clone the repository to your Linux machine:

```bash
git clone <repository-url>
cd <repository-directory>
```

2. Set up a Python virtual environment and install dependencies:

```bash
python3 -m venv venv
source venv/bin/activate
pip install transformers torch tailer
```

3. Copy the configuration file to the system config directory:

```bash
sudo mkdir -p /etc/syslog_processor
sudo cp config.ini /etc/syslog_processor/config.ini
```

4. Adjust the configuration file `/etc/syslog_processor/config.ini` as needed to specify:

- The syslog file path (default: `/var/log/syslog`)
- The Hugging Face model URL
- The output file for simplified logs (leave empty for console output)

5. Copy the systemd service file and enable the service:

```bash
sudo cp syslog_processor.service /etc/systemd/system/syslog_processor.service
sudo systemctl daemon-reload
sudo systemctl enable syslog_processor.service
sudo systemctl start syslog_processor.service
```

6. Check the status of the service:

```bash
sudo systemctl status syslog_processor.service
```

## Usage

- The service will run continuously, monitoring the specified syslog file and outputting simplified log entries.
- To stop the service:

```bash
sudo systemctl stop syslog_processor.service
```

- To view logs:

```bash
journalctl -u syslog_processor.service -f
```

## Customization

- Modify `/etc/syslog_processor/config.ini` to change settings.
- Restart the service after changes:

```bash
sudo systemctl restart syslog_processor.service
```

## Troubleshooting

- Ensure all paths in the service file and config file are correct.
- Check permissions for the user running the service.
- Review logs for errors.
