## Magento2 Vagrant Box
A simple way to get magento2 up and running. It consists of a Debian Wheezy box provised via Puppet. The provider is Virtual Box. It will install apache2 +fastcgi, php, php-fpm, mysql and any other necessary dependancies.

The Magento 2 repository is a git submodule and can be edited/explored from the host machine. It is accessed by the guest via shared directories.

### Usage
#### Installation
1. Clone this repository: `git clone --recursive https://github.com/rgranadino/mage2_vagrant.git`
2. Navigate into the repository via `cd`
2. **IMPORTANT**: If you cloned the repository without the *--recursive* param, you need to initialize the required submodules: `git submodule update --init --recursive`
3. Start up virtual machine: `vagrant up`
4. Point a host name to 192.168.56.10 in /etc/hosts `echo '192.168.56.10 mage2.dev' >> /etc/hosts`
>NOTE: Some composer dependancies require git. Agent Forwarding over SSH is enabled in the Vagrant file but you must have `ssh-agent` running and your key added. Running `ssh-add` should add the default key to the identities list, which presumably is the same key used to access github/bitbucket. You'll may also need to create a API access token in github, instructions can be found [here](http://devdocs.magento.com/guides/v2.0/install-gde/trouble/git/tshoot_rate-limit.html): 
5. Once the machine completes provisioning, SSH to the server (`vagrant ssh`).
6. Add your Magento Connect login credentials to the global composer auth.json:

  * Open or create the file `~/.composer/auth.json`
  * Add the Magento Connect login credentials:

  ```json
  {
      "http-basic": {
          "repo.magento.com": {
              "username": "MAGENTO_USER",
              "password": "MAGENTO_PASS"
          }
      }
  }
  ```

7. Install Magento 2 by running:

 * Via CLI (recommended)

   * `reinstall` (Magento **without** sample data) or `reinstall -s` (Magento **with** sample data).

 * Via Web Installer

   * Please go to the Magento directory within the vagrant box (`cd /vagrant/data/magento2/`) and run `composer install`. Then open 'http://mage2.dev/setup' in your browser and go through the installation process.

#### Updating
1. From the host machine run `git pull && git submodule update --init && vagrant provision`.
  * If there is an update to the *manifests/mage.pp* or *files/** files it is recommended to provision the guest machine. This can be done by running: `vagrant provision`. There is also a cron that runs every 15 minutes to
provision within the guest machine in the event it's not done after updating.
2. If you want to start from a clean slate run: `reinstall` from within the guest machine. This will uninstall the application and reinstall it from scratch.


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
* http://mage2.dev:88/webgrind

### Magento Admin User
* Username: admin
* Password: password123

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
* data/magento2 - Git submodule to Magento2 Github repository: https://github.com/magento/magento2
* data/magento2-sample-data - Git submodule to Magento2 Sample Data Github repository: https://github.com/magento/magento2-sample-data

### Guest Machine
* /vagrant/data/magento2 - Apache Document Root
