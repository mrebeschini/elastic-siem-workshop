#!/bin/bash
# Setup beats on Linux

CLOUD_ID=""
CLOUD_AUTH=""
echo "Enter your Elastic Cloud CLOUD_ID then press [ENTER]"
read CLOUD_ID
echo "Your CLOUD_ID is set to $CLOUD_ID"
printf "\n\n\n"
echo "Enter you Elastic Cloud 'elastic' user password and then press [ENTER]"
read CLOUD_AUTH
echo "Your elastic password is set to $CLOUD_AUTH"
sleep 5
printf "\n\n\n"
# Download Elastic yum repo configuration.
echo "Downloading Elastic yum repo configuration from github."
sudo curl -O https://gist.githubusercontent.com/elastickent/2dc5fb494044d5fb8724359c145219b5/raw/bb3fd68ecc9b7235ea61cb74911373e3fadcd2f4/elastic-7.x.repo > /home/centos/elastic-7.x.repo
sudo mv -v elastic-7.x.repo /etc/yum.repos.d/
printf "\n\n\n"
echo "Installing filebeat, packetbeat, metricbeat, and auditbeat rpms"
sudo yum install filebeat packetbeat metricbeat auditbeat -y
printf "\n\n\n"
echo "Downloading beats configuration files"
sleep 2
printf "\n\n\n"
sudo curl -O https://gist.githubusercontent.com/elastickent/839e5f49f8846d67b254d9318095c101/raw/9a9d35454ecfcaf549b413ed104f1cee22121429/auditd-attack.rules.conf > ./attack.rules.conf
sudo mv -v ./auditd-attack.rules.conf  /etc/auditbeat/audit.rules.d/auditd-attack.rules.conf
sudo curl -O https://gist.githubusercontent.com/elastickent/e3a4af6ed24fdcb62b6318e6da796c51/raw/a339bb0036d840c77a208dd910259c37fa2d29df/auditbeat.yml > ./auditbeat.yml
sudo mv -v ./auditbeat.yml /etc/auditbeat/auditbeat.yml
sudo chown root /etc/auditbeat/auditbeat.yml
sudo chmod go-w /etc/auditbeat/auditbeat.yml
sudo curl -O https://gist.githubusercontent.com/elastickent/fb65ee445a0e6d85985f41ee0fe1d25c/raw/260bcdb441a93c9d90d4032932b62a6cbe33f8a0/filebeat.yml > ./filebeat.yml
sudo mv -v ./filebeat.yml /etc/filebeat/filebeat.yml
sudo chown root /etc/filebeat/filebeat.yml
sudo chmod go-w /etc/filebeat/filebeat.yml
sudo curl -O https://gist.githubusercontent.com/elastickent/d4a150309a932e9c843ff3fb6939d9ec/raw/f424ee21b89e5d147b5bb87bacb0d67862287149/metricbeat.yml > ./metricbeat.yml
sudo mv -v ./metricbeat.yml /etc/metricbeat/metricbeat.yml
sudo chown root /etc/metricbeat/metricbeat.yml
sudo chmod go-w /etc/metricbeat/metricbeat.yml
sudo curl -O https://gist.githubusercontent.com/elastickent/8e195dcfd9be5ea8ee85c7466247a942/raw/d09158d609f75c34d7796eb323e3fd183d74d34a/packetbeat.yml > ./packetbeat.yml
sudo mv -v ./packetbeat.yml  /etc/packetbeat/packetbeat.yml
sudo chown root  /etc/packetbeat/packetbeat.yml
sudo chmod go-w /etc/packetbeat/packetbeat.yml
printf "\n\n\n"
echo "Setting up keystore with Elastic Cloud credentials"
sleep 5
sudo auditbeat keystore create --force
sudo filebeat keystore create --force
sudo packetbeat keystore create --force
sudo metricbeat keystore create --force
echo $CLOUD_ID|sudo auditbeat keystore add CLOUD_ID --stdin --force
echo $CLOUD_AUTH|sudo auditbeat keystore add --stdin CLOUD_AUTH --force
echo $CLOUD_ID|sudo filebeat keystore add CLOUD_ID --stdin --force
echo $CLOUD_AUTH|sudo filebeat keystore add --stdin CLOUD_AUTH --force
echo $CLOUD_ID|sudo packetbeat keystore add CLOUD_ID --stdin --force
echo $CLOUD_AUTH|sudo packetbeat keystore add --stdin CLOUD_AUTH --force
echo $CLOUD_ID|sudo metricbeat keystore add CLOUD_ID --stdin --force
echo $CLOUD_AUTH|sudo metricbeat keystore add --stdin CLOUD_AUTH --force
printf "\n\n\n"
echo "Stopping auditd deamon"
sudo service auditd stop
printf "\n\n\n"
echo "Setting up auditbeat"
sudo auditbeat setup
sudo systemctl start auditbeat
printf "\n\n\n"
echo "Setting up filebeat"
sudo filebeat modules enable system
sudo filebeat setup
sudo systemctl start filebeat
printf "\n\n\n"
echo "Setting up packetbeat"
sudo packetbeat setup
sudo systemctl start packetbeat
printf "\n\n\n"
echo "Setting up metricbeat"
sudo metricbeat setup
sudo systemctl start metricbeat
printf "\n\n\n"
echo "Testing beats output"
sudo auditbeat test output
sudo metricbeat test output
sudo filebeat test output
sudo packetbeat test output
printf "\n\n\n"
sleep 5
echo "Setup complete"