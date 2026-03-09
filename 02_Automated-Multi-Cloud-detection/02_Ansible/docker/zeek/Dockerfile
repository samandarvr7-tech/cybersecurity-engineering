FROM blacktop/zeek:latest

# We need a small script to ensure Zeek sniffs the right interface
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Zeek stores logs in /pcap by default in this image
WORKDIR /pcap

ENTRYPOINT ["/entrypoint.sh"]