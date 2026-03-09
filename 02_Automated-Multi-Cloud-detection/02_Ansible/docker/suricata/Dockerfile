FROM ubuntu:24.04

# 1. Install Suricata
RUN apt-get update && apt-get install -y \
    software-properties-common curl \
    && add-apt-repository ppa:oisf/suricata-stable \
    && apt-get update && apt-get install -y suricata

# 2. Create a non-root user for Suricata
RUN groupadd -g 10002 suricatagroup && \
    useradd -u 10002 -g suricatagroup -s /bin/false suricatauser

# 3. Create log directory (Root creates it, then gives it to the user)
RUN mkdir -p /var/log/suricata && \
    chown -R suricatauser:suricatagroup /var/log/suricata /etc/suricata

# We don't use USER command here because the binary needs 
# to start as root to bind to eth0, then it drops to suricatauser itself.

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]