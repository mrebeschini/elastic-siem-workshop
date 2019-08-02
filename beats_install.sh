#!/bin/bash                                                                                                                                                                                                                              
# Setup beats on Linux                                                                                                                                                                                                                   
CONFIG_REPOSITORY_URL="https://raw.githubusercontent.com/mrebeschini/2019BSidesLV/master/"                                                                                                                                               

# Uninstall Beats if already installed
sudo yum -y -q remove filebeat metricbeat packetbeat auditbeat 2>1 /dev/null

CLOUD_ID=""
CLOUD_AUTH=""
echo "Enter your Elastic Cloud CLOUD_ID then press [ENTER]"
read CLOUD_ID
echo -e "Your CLOUD_ID is set to $CLOUD_ID\n\n"
echo "Enter you Elastic Cloud 'elastic' user password and then press [ENTER]"
read CLOUD_AUTH
echo -e "Your elastic password is set to $CLOUD_AUTH\n\n"
echo "Ready to Install? [y|n]"
read CONTINUE
case "$CONTINUE" in
 [Yy]) echo "Elastic Beats Installation Initiated";;
    *) echo "Installation aborted";exit;;
esac

# Download Elastic yum repo configuration.
echo "Downloading Elastic yum repo configuration from github."
sudo curl -O $CONFIG_REPOSITORY_URL/elastic-7.x.repo > /home/centos/elastic-7.x.repo
sudo mv -v elastic-7.x.repo /etc/yum.repos.d/
printf "\n\n\n"
echo "Installing filebeat, packetbeat, metricbeat, and auditbeat rpms"
sudo yum install filebeat packetbeat metricbeat auditbeat -y
printf "\n\n\n"
echo "Downloading beats configuration files \n\n"
sudo curl -O $CONFIG_REPOSITORY_URL/auditd-attack.rules.conf > ./attack.rules.conf
sudo mv -v ./auditd-attack.rules.conf  /etc/auditbeat/audit.rules.d/auditd-attack.rules.conf
sudo curl -O $CONFIG_REPOSITORY_URL/auditbeat.yml > ./auditbeat.yml
sudo mv -v ./auditbeat.yml /etc/auditbeat/auditbeat.yml
sudo chown root /etc/auditbeat/auditbeat.yml
sudo chmod go-w /etc/auditbeat/auditbeat.yml
sudo curl -O $CONFIG_REPOSITORY_URL/filebeat.yml > ./filebeat.yml
sudo mv -v ./filebeat.yml /etc/filebeat/filebeat.yml
sudo chown root /etc/filebeat/filebeat.yml
sudo chmod go-w /etc/filebeat/filebeat.yml
sudo curl -O $CONFIG_REPOSITORY_URL/metricbeat.yml > ./metricbeat.yml
sudo mv -v ./metricbeat.yml /etc/metricbeat/metricbeat.yml
sudo chown root /etc/metricbeat/metricbeat.yml
sudo chmod go-w /etc/metricbeat/metricbeat.yml
sudo curl -O $CONFIG_REPOSITORY_URL/packetbeat.yml > ./packetbeat.yml
sudo mv -v ./packetbeat.yml  /etc/packetbeat/packetbeat.yml
sudo chown root  /etc/packetbeat/packetbeat.yml
sudo chmod go-w /etc/packetbeat/packetbeat.yml
echo -e "\n\n\n"
echo "Setting up keystore with Elastic Cloud credentials"
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
echo -e "\n\nStopping auditd deamon"
sudo service auditd stop
echo -e "\n\nSetting up auditbeat"
sudo auditbeat setup
sudo systemctl start auditbeat
echo -e "\n\nSetting up filebeat"
sudo filebeat modules enable system
sudo filebeat setup
sudo systemctl start filebeat
printf "\n\n\n"
echo "Setting up packetbeat"
sudo packetbeat setup
sudo systemctl start packetbeat
echo -e "\n\nSetting up metricbeat"
sudo metricbeat setup
sudo systemctl start metricbeat
echo -e "\n\nTesting beats output"
sudo auditbeat test output
sudo metricbeat test output
sudo filebeat test output
sudo packetbeat test output
echo -e "\n\nSetup complete"
