## Magento2 Vagrant Box
A simple way to get magento2 up and running. It consists of a Debian Wheezy box provised via Puppet. The provider is Virtual Box. It will install apache2 +fastcgi, php, php-fpm, mysql and any other necessary dependancies. 

The Magento 2 repository is a git submodule and can be edited/explored from the host machine. It is accessed by the guest via shared directories.

### Usage
#### Installation
1. Clone this repo and `cd` into it
2. Initialize magento2 submodule: `git submodule update --init`
3. start up virtual machine: `vagrant up`
4. Point a host name to 192.168.56.10 in /etc/hosts `echo '192.168.56.10 mage2.dev' >> /etc/hosts'`
5. Once the machine completes provisioning then it can be installed by going to 'http://mage2.dev' or via ssh by running: `reinstall`

#### Updating
1. From the host machine run `git pull && git submodule update --init && vagrant provision`. 
  * If there is an update to the *manifests/mage.pp* or *files/** files it is recommended to provision the guest machine. This can be done by running: `vagrant provision`. There is also a cron that runs every 15 minutes to 
provision within the guest machine in the event it's not done after updating. 
2. If you want to start from a clean slate run: `reinstall` from within the guest machine. This will uninstall the application and reinstall it from scracth.


#### Shell Aliases / Scripts
* `m` - cd into the base magento directory: /vagrant/data/magento2
* `reinstall` - run magento shell uninstall script with the `cleanup_database` flag and run installation again, uses `http://mage2.dev` as base URL
 * `reinstall -s` - install magento with sample data
* `mt` - run bulk magento test suites

#### Status and Debug utilities
A status vhost on port 88 has been setup to view apache's server status, php-fpm status as well as some other utilities.

* http://mage2.dev:88/server-status
* http://mage2.dev:88/fpm-status
* http://mage2.dev:88/info.php
* http://mage2.dev:88/opcache.php
* http://mage2.dev::88/webgrind

### Database Info
* Username: root
* Password: mage2
* DB Name: mage2

### SSH Info
* username: vagrant
* password: vagrant 

It's also possible to use `vagrant ssh` from within the project directory

## File Structure

### Host Machine / Project directory
* manifests/mage.pp - Puppet manifest file
* files/ - contains various service configuration files
  * bash_aliases - vagrant user bash aliases script
  * fastcgi.conf - fastcgi configuration
  * reinstall.sh - magento reinstall wrapper script
  * site.conf - apache virtual host configuration
  * www.conf - php-fpm pool configuration
  * xdebug.ini - php xdebug configuration file
* data/magento2 - git submodule to magento2 github repository. 
  
 
### Guest Machine
* /vagrant/data/magento2 - Apache Document Root

