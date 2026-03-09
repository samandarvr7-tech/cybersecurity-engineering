#!/bin/bash
# -i eth0: Sniff the Azure interface
# local: Only load essential scripts to save RAM
exec zeek -i eth0 local