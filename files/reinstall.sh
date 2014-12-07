#!/bin/bash
usage()
{
cat << EOF
usage $0 options

This script reinstalls magento 2

OPTONS:
    -s Include Sample Data
    -h Show this message
EOF
}
SAMPLE_DATA=
while getopts "hs" o; do
    case "${o}" in
        s)
            SAMPLE_DATA=1
            ;;
        h)
            usage
            exit 1
            ;;
    esac
done

cd /vagrant/data/magento2
rm -rf var/*
rm composer.lock
composer install
cd setup
rm composer.lock
composer install
export MAGE_MODE='developer'
echo "Uninstalling..."
php -f index.php -- uninstall
echo "Installing..."
if [[ -n $SAMPLE_DATA ]]
then
   echo "Installing sample data..."
   mysql -uroot -pmage2 mage2 < /vagrant/data/m2-sample-data/m2sample.sql
   rsync -crt /vagrant/data/m2-sample-data/pub/ /vagrant/data/magento2/pub/
fi
php -f index.php install \
  --cleanup_database \
  --db_host="localhost" \
  --db_name="mage2" \
  --db_user="root" \
  --db_pass="mage2" \
  --backend_frontname=admin \
  --base_url="http://mage2.dev" \
  --language=en_US \
  --currency="USD" \
  --timezone=America/Los_Angeles \
  --admin_lastname="mage2" \
  --admin_firstname="mage2" \
  --admin_email="foo@test.com" \
  --admin_username="admin" \
  --admin_password="p4ssw0rd" \
  --use_secure=0 \
  --use_rewrites="yes" \
  --use_secure_admin=0 \
  --base_url_secure="http://mage2.dev" \
  --session_save=db
cd -
