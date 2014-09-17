#!/usr/bin/env bash

whoami

sudo apt-get update

# install git
sudo apt-get -y install git

# install nginx
sudo apt-get -y install apache

# install php5
sudo apt-get -y install php5 php5-curl php5-cli php5-gd php5-intl php5-json libapache2-mod-php5 php5-xsl

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt-get -y install mysql-server

#sudo mysqladmin -u root root secretroot

sudo apt-get install -y mysql-client php5-mysql pdo-mysql

# configuring apache
sudo /etc/init.d/apache2 stop
sudo chown -R vagrant:vagrant /var/log/apache2
sudo chown -R vagrant:vagrant /var/lock/apache2


# Configuring les acces au fichier de application pour user cli et web
sudo usermod -g vagrant vagrant

if [ `grep -c "umask 0002" /home/vagrant/.bashrc` -eq 0 ]
then
    echo "umask 0002" >>/home/vagrant/.bashrc
fi

# configure project
cd /vagrant/ezpublish-community
curl -s http://getcomposer.org/installer | php
php composer.phar install
