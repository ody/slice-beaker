#!/usr/bin/env bash

set -e

MODULE=$1
PLATFORM=$2

HTTP_PROXY=http://proxy.ops.puppetlabs.net:3128;export HTTP_PROXY

# install deps needed when using cloud images
if [ $PLATFORM == 'centos-7-x86_64' ]; then
    sudo yum -y install libxml2-devel libxslt-devel ruby-devel
    sudo yum -y groupinstall "Development Tools"
elif [ $PLATFORM == 'debian-8.2.0-x86_64' ]; then
    sudo apt-get update
    sudo apt-get install -y libxml2-dev libxslt-dev zlib1g-dev git ruby ruby-dev build-essential
fi

# prepare ssh
echo "" | sudo tee -a /etc/ssh/sshd_config
echo "Match address 127.0.0.1" | sudo tee -a /etc/ssh/sshd_config
echo "    PermitRootLogin without-password" | sudo tee -a /etc/ssh/sshd_config
echo "" | sudo tee -a /etc/ssh/sshd_config
echo "Match address ::1" | sudo tee -a /etc/ssh/sshd_config
echo "    PermitRootLogin without-password" | sudo tee -a /etc/ssh/sshd_config
mkdir -p .ssh
ssh-keygen -f ~/.ssh/id_rsa -b 2048 -C "beaker key" -P ""
sudo mkdir -p /root/.ssh
sudo rm /root/.ssh/authorized_keys
cat ~/.ssh/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
sudo systemctl restart sshd

# prepare gems
cd /vagrant/$MODULE
sudo gem install bundler --no-rdoc --no-ri --verbose
mkdir .bundled_gems
export GEM_HOME=`pwd`/.bundled_gems
bundle install

# run tests
export BEAKER_setfile=/vagrant/$PLATFORM.yml
export BEAKER_debug=yes
bundle exec rake beaker
