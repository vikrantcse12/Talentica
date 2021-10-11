#! bin/bash

# Install Docker on Web WebServer
wget -qO- https://get.docker.com/ | sh
sudo usermod -aG docker ubuntu
cat /etc/group | grep docker
echo "Docker instaaled"

# Install Python and PrivateIpAddress
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.7 -y
curl  https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
python3 get-pip.py
echo "Python and PIP installed"

# Install nginx

sudo apt install nginx
sudo ufw app list
sudo ufw allow 'Nginx HTTP'
sudo ufw status
sudo nginx start
