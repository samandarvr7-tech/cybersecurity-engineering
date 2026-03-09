#!/bin/bash
# Update rules
suricata-update

# Start Filebeat (Background)
service filebeat start

# Start Suricata (Foreground)
# -i eth0 = Listen on the main internet interface
exec /usr/bin/suricata -c /etc/suricata/suricata.yaml -i eth0