#!/bin/bash

# ROOT SETZUNG - DER BENUTZER WIRD ERSTELLT ALS ROOT
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password admin'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password admin'

# INSTALL MYSQL
sudo apt-get install -y mysql-server


#-----CONFIG STAGE------
# PORT ÖFFNEN
sudo sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# ACTIVATE REMOTE ACCESS
mysql -uroot -padmin <<%EOF%
	CREATE USER 'root'@'192.168.2.98' IDENTIFIED BY 'admin';
	GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.2.98' IDENTIFIED BY 'admin' WITH GRANT OPTION;
	FLUSH PRIVILEGES;
	CREATE DATABASE DB-LB02;
	USE DB-LB02;
	CREATE TABLE DB-LB02(Titel VARCHAR(50), Beschreibung VARCHAR(50));
	INSERT INTO DB-LB02 VALUE ("TESTWERT","Dieser Wert sollte angezeigt werden.");
	quit
%EOF%


#-----RESTART-----
# MYSQL NEUSTARTEN - AKTUALISIERUNG
sudo service mysql restart
