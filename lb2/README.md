Dieses File beinhaltet die Dokumentation zu meinem Vagrantfile.

# Apache2, PHP und MySQL Infrastruktur als Service (Vagrant)

### Inhaltsverzeichnis
1. [Was macht meine Vagrantdatei?](#Was-macht-meine-Vagrantdatei?)
2. [Was macht die PHP Datei?](#Was-macht-die-PHP-Datei?)
3. [Was macht die HTML Datei?](#Was-macht-die-HTML-Datei?)

### Verzeichnisstruktur
Mein Repository ist wie folgt aufgebaut:
```
M300-Services/
  ├─ lb2/
     ├─ README.md
     ├─ db.sh
     ├─ Vagrant
     ├─ home.html
```

### Die Vagrantdatei
Durch das Ausführen der Datei wird ein Ubuntu System auf Virtualbox installiert und gestartet. Ausserdem werden die benötigten Programme installiert und konfiguriert.
```
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define "datenbank-vm" do |db|
    db.vm.box = "ubuntu/xenial64"
	db.vm.provider "virtualbox" do |vb|
	  vb.memory = "2048"  
	end
    db.vm.hostname = "datenbank-server"
    db.vm.network "private_network", ip: "192.168.2.99"
  	db.vm.provision "shell", path: "db.sh"
  end

  config.vm.define "apache-webserver" do |web|
    web.vm.box = "ubuntu/xenial64"
    web.vm.hostname = "webserver"
    web.vm.network "private_network", ip:"192.168.2.98" 
	web.vm.network "forwarded_port", guest:80, host:8080, auto_correct: true
	web.vm.provider "virtualbox" do |vb|
	  vb.memory = "2048"  
	end     

  	web.vm.synced_folder ".", "/var/www/html"  
	web.vm.provision "shell", inline: <<-SHELL
		sudo apt-get update
		sudo apt-get -y install debconf-utils apache2 nmap
		sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password admin'
		sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password admin'
		sudo apt-get -y install php libapache2-mod-php php-curl php-cli php-mysql php-gd mysql-client  
		# Admininer SQL UI 
		sudo mkdir /usr/share/adminer
		sudo wget "http://www.adminer.org/latest.php" -O /usr/share/adminer/latest.php
		sudo ln -s /usr/share/adminer/latest.php /usr/share/adminer/adminer.php
		echo "Alias /adminer.php /usr/share/adminer/adminer.php" | sudo tee /etc/apache2/conf-available/adminer.conf
		sudo a2enconf adminer.conf 
		sudo service apache2 restart 
	  echo '127.0.0.1 localhost webserver\192.168.2.99 datenbank-server' > /etc/hosts
SHELL
	end  
end
```
### Die PHPdatei
Das Database Shell Script wird verwendet, um eine Tabelle zu erstellen, die dann auf unserem Apache Webserver als HTML-Datei angezeigt wird. Dies macht sie mit Hilfe von unserer MySQL Datenbank, in der die Daten gespeichert sind.

```
#!/bin/bash

# ROOT SETZUNG - DER ADMIN BENUTZER WIRD ERSTELLT ALS ROOT
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password admin'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password admin'
#-----------------------

#-----INSTALL MYSQL-----
sudo apt-get install -y mysql-server
#-----------------------

#-----CONFIG STAGE------
# PORT ÖFFNEN
sudo sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
#-----------------------

# TABELLEN ERSTELLUNG UND REMOTE ACCESS
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
#-----------------------

#-----RESTART-----
# MYSQL NEUSTARTEN - AKTUALISIERUNG
sudo service mysql restart
#-----------------------
```

### Die Vagrantdatei erklärt
**Vagrant definieren**
```
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
```
Diese Zeile findet man in jeder Vagrantdatei. Sie initiert die Erstellung der VM.
##
**So wird die VM erstellt**
```
config.vm.define "datenbank-vm" do |db|
    db.vm.box = "ubuntu/xenial64"
	db.vm.provider "virtualbox" do |vb|
	  vb.memory = "2048"  
	end
    db.vm.hostname = "datenbank-server"
    db.vm.network "private_network", ip: "192.168.2.99"
  	db.vm.provision "shell", path: "db.sh"
  end
```
- *define:* Definiert die ID/Name der VM
- *box:* Definiert das Betriebssystem
- *provider:* Definiert, dass VirtualBox verwendet wird.
- *memory:* Erlaubte RAM Nutzung
- *hostname:* Name der VM (ssh)
- *network:* Netzwerk Adapter wird definiert
- *provision:* Skript welches in der VM ausgeführt werden soll (Shell Skripte etc.)
##
**Die Kommandos die in der VM ausgeführt werden**
```
web.vm.provision "shell", inline: <<-SHELL
		sudo apt-get update
		sudo apt-get -y install debconf-utils apache2 nmap
		sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password admin'
		sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password admin'
		sudo apt-get -y install php libapache2-mod-php php-curl php-cli php-mysql php-gd mysql-client  
		# Admininer SQL UI 
		sudo mkdir /usr/share/adminer
		sudo wget "http://www.adminer.org/latest.php" -O /usr/share/adminer/latest.php
		sudo ln -s /usr/share/adminer/latest.php /usr/share/adminer/adminer.php
		echo "Alias /adminer.php /usr/share/adminer/adminer.php" | sudo tee /etc/apache2/conf-available/adminer.conf
		sudo a2enconf adminer.conf 
		sudo service apache2 restart 
	  echo '127.0.0.1 localhost webserver\192.168.2.99 datenbank-server' > /etc/hosts
SHELL
```
## Was macht der Code der db.sh Datei?
**Erstellung des MySQL Accounts**
```
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password admin'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password admin'
```
Hier wird der vorgefertigte Admin Account für die MySQL Database definiert.

**MySQL Installation**
```
sudo apt-get install -y mysql-server
```
MySQL wird installiert.

**Tabelle und Root Account**
```
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
```
Hier werden die MySQL Root Rechte an den vorgefertigten Admin Account übertragen und durch diesen eine Testtabelle erstellt.

## Probleme die aufgetaucht sind
Da das PHP und HTML Dokument nicht richtig von Apache ausgeführt wurde, wurde der Tabellenwert nicht richtig auf der HTML-Seite angezeigt. Leider konnte ich dies mit meinem Partner nicht lösen.

Wie die Webseite dargestellt werden hätte müssen:
|             Testtabelle              |
|--------------------------------------|
| Dieser Wert sollte angezeigt werden. |
