Magento2 Vagrant Box
================================
A simple way to get magento2 up and running. It consists of a Debian Wheezy box provised via Puppet. It will install apache2 +fastcgi, php, php-fpm, mysql and any other necessary dependancies. 

The Magento 2 repository is a git submodule and can be edited/explored from the host machine. It it accessed by the guest via shared directories.

Usage
-------------------------
* Clone this repo and `cd` into it
* Initialize magento2 submodule: `git submodule update --init`
* start up virtual machine: `vagrant up`
* Point a host name to 192.168.56.10 in /etc/hosts e.g. 192.168.56.10 mage2.dev
* If all goes well you should see the install screen
* SSH user info: vagrant/vagrant
* To update: `git pull && git submodule update --init`

Database Info
-------------------------
* Username: root
* Password: mage2
* DB Name: mage2

File Structure
-------------------------
### Host Machine / Project directory
* manifests/mage.pp - Puppet manifest file
* files/ - contains various service configuration files
  * fastcgi.conf - fastcgi configuration
  * site.conf - apache virtual host configuration
  * www.conf - php-fpm pool configuration
* data/magento2 - git submodule to magento2 github repository. 
  
 
### Guest Machine
* /vagrant/data/magento2 - Apache Document Root
