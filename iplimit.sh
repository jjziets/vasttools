#!/bin/bash

# Read the port range from file
port_range=$(cat /var/lib/vastai_kaalia/host_port_range)

# Replace dash with colon
port_range=${port_range//-/:}

# Extract the network id of vast_default Docker network
network_id=$(docker network inspect vast_default -f "{{.Id}}")

# Define the Docker bridge network interface associated with vast_default
bridge_interface="br-${network_id:0:12}"

# Apply iptables rule for outbound TCP connections
iptables -A OUTPUT -o $bridge_interface -p tcp --syn --dport $port_range -m connlimit --connlimit-above 100 -j DROP

# Apply iptables rule for inbound TCP connections
iptables -A INPUT -i $bridge_interface -p tcp --syn --dport $port_range -m connlimit --connlimit-above 100 -j DROP

# Apply iptables rule for outbound UDP connections
iptables -A OUTPUT -o $bridge_interface -p udp --dport $port_range -m connlimit --connlimit-above 100 -j DROP

# Apply iptables rule for inbound UDP connections
iptables -A INPUT -i $bridge_interface -p udp --dport $port_range -m connlimit --connlimit-above 100 -j DROP

# Apply iptables rule for outbound TCP connections on docker0
iptables -A OUTPUT -o docker0 -p tcp --syn --dport $port_range -m connlimit --connlimit-above 100 -j DROP

# Apply iptables rule for inbound TCP connections on docker0
iptables -A INPUT -i docker0 -p tcp --syn --dport $port_range -m connlimit --connlimit-above 100 -j DROP

# Apply iptables rule for outbound UDP connections on docker0
iptables -A OUTPUT -o docker0 -p udp --dport $port_range -m connlimit --connlimit-above 100 -j DROP

# Apply iptables rule for inbound UDP connections on docker0
iptables -A INPUT -i docker0 -p udp --dport $port_range -m connlimit --connlimit-above 100 -j DROP
