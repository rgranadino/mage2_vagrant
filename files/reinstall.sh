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

composer install
export MAGE_MODE='developer'

echo "Uninstalling..."
php -f bin/magento setup:uninstall -n

echo "Installing..."
php -f bin/magento setup:install \
  --db_host="localhost" \
  --db_name="mage2" \
  --db_user="root" \
  --db_password="mage2" \
  --backend_frontname=admin \
  --base_url="http://mage2.dev/" \
  --language=en_US \
  --currency="USD" \
  --timezone=America/Los_Angeles \
  --admin_lastname="mage2" \
  --admin_firstname="mage2" \
  --admin_email="foo@test.com" \
  --admin_user="admin" \
  --admin_password="password123" \
  --use_secure=0 \
  --use_rewrites="yes" \
  --use_secure_admin=0 \
  --base_url_secure="http://mage2.dev/" \
  --session_save=files

cd -

if [[ -n $SAMPLE_DATA ]]
then
  echo "Installing sample data..."
  composer config repositories.magento composer http://packages.magento.com
  composer require magento/sample-data:0.74.0-beta9 --dev
  php -f dev/tools/Magento/Tools/SampleData/install.php -- --admin_user=admin
fi


