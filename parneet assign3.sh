#!/bin/bash



# first of all to configure the first server, i will make this part.
# this is only focused on changing configurations for the first server.
# this variable creates the given ip address
server1_mgmt_ip="172.16.1.10"
# i will be using ssh remoteadmin command to access this server.
# this command will be changing the hostname to loghost.
ssh remoteadmin@$server1_mgmt_ip "hostnamectl set-hostname loghost"
# now ip address will be changed to the 3rd on the lan.
ssh remoteadmin@$server1_mgmt_ip "ip addr add 192.168.1.3/24 dev eth0"

# now i have to Add entry to /etc/hosts file.
ssh remoteadmin@$server1_mgmt_ip "echo '192.168.1.4 webhost' | tee -a /etc/hosts"

# after this, i will Install and configure UFW package
ssh remoteadmin@$server1_mgmt_ip "dpkg -l | grep -E '^ii' | grep -q ufw || apt-get install -y ufw"
ssh remoteadmin@$server1_mgmt_ip "ufw allow from 172.16.1.0/24 to any port 514/udp"
# now first server is done.
# therefore i am going to restart the rsyslog service.
ssh remoteadmin@$server1_mgmt_ip "sed -i '/imudp/s/^#//g' /etc/rsyslog.conf"
ssh remoteadmin@$server1_mgmt_ip "sed -i '/UDPServerRun/s/^#//g' /etc/rsyslog.conf"
ssh remoteadmin@$server1_mgmt_ip "systemctl restart rsyslog"

##############################

# Now it is time for Configuration of server2
server2_mgmt_ip="172.16.1.11"

# I will Set hostname to webhost
ssh remoteadmin@$server2_mgmt_ip "hostnamectl set-hostname webhost"

# and Configure IP address to be the 4 on lan.
ssh remoteadmin@$server2_mgmt_ip "ip addr add 192.168.1.4/24 dev eth0"

# Adding entry to /etc/hosts file
ssh remoteadmin@$server2_mgmt_ip "echo '192.168.1.3 loghost' | tee -a /etc/hosts"

# final steps involving Installation and configuration of UFW
ssh remoteadmin@$server2_mgmt_ip "dpkg -l | grep -E '^ii' | grep -q ufw || apt-get install -y ufw"
ssh remoteadmin@$server2_mgmt_ip "ufw allow 80/tcp"

# Installing Apache2 service
ssh remoteadmin@$server2_mgmt_ip "apt-get install -y apache2"

# again configuring the rsyslog but this time i will add the *.* @loghost as described in the assignment.
ssh remoteadmin@$server2_mgmt_ip "echo '*.* @loghost' | tee -a /etc/rsyslog.conf"
ssh remoteadmin@$server2_mgmt_ip "systemctl restart rsyslog"

##############################

# Now both servers are done. I will Update NMS Configuration to add the new ip addresses and names.
echo "192.168.1.3 loghost" | sudo tee -a /etc/hosts
echo "192.168.1.4 webhost" | sudo tee -a /etc/hosts

##############################

# Verification for apache 2 and syslog will be performed and in the end, the result will be showm in a user friendly way.
echo "Verification for Apache2 service on webhost."
curl -s http://webhost
if [[ "$?" == "0" ]]; then
    echo "configurations for apache2 on webhost are successful."
else
    echo "configurations are not correct."
fi
echo "Verification for syslog on loghost."
ssh remoteadmin@loghost grep webhost /var/log/syslog
if [[ -n "$?" ]]; then
    echo "configurations for syslog on loghost are successful."
else
    echo "configurations are not correct."
fi