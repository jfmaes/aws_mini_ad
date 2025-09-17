#!/bin/bash
# SOC ELK Stack Reset Script
# This script completely removes the ELK stack and resets to clean state

set -e

echo "=== SOC ELK Stack Reset Script ==="
echo "This will completely remove Elasticsearch, Logstash, and Kibana"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo "Stopping services..."
sudo systemctl stop kibana || true
sudo systemctl stop logstash || true
sudo systemctl stop elasticsearch || true

echo "Disabling services..."
sudo systemctl disable kibana || true
sudo systemctl disable logstash || true
sudo systemctl disable elasticsearch || true

echo "Removing packages..."
sudo apt-get remove --purge -y kibana logstash elasticsearch || true

echo "Removing data directories..."
sudo rm -rf /var/lib/elasticsearch
sudo rm -rf /var/lib/logstash
sudo rm -rf /var/lib/kibana
sudo rm -rf /var/log/elasticsearch
sudo rm -rf /var/log/logstash
sudo rm -rf /var/log/kibana

echo "Removing configuration directories..."
sudo rm -rf /etc/elasticsearch
sudo rm -rf /etc/logstash
sudo rm -rf /etc/kibana

echo "Removing systemd overrides..."
sudo rm -rf /etc/systemd/system/elasticsearch.service.d
sudo rm -rf /etc/systemd/system/logstash.service.d
sudo rm -rf /etc/systemd/system/kibana.service.d

echo "Removing users..."
sudo userdel elasticsearch || true
sudo userdel logstash || true
sudo userdel kibana || true

echo "Removing groups..."
sudo groupdel elasticsearch || true
sudo groupdel logstash || true
sudo groupdel kibana || true

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Cleaning package cache..."
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "=== Reset complete! ==="
echo "The SOC machine is now in a clean state."
echo "You can now run the Ansible playbook to reinstall the ELK stack."
