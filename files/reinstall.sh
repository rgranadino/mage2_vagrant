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

echo "[+] Composer..."
composer install

if [[ -n $SAMPLE_DATA ]]; then
    composer config repositories.magento composer http://packages.magento.com
    composer require magento/sample-data:0.74.0-beta16 --dev
fi

export MAGE_MODE='developer'
chmod +x bin/magento

echo "[+] Uninstalling..."
php -f bin/magento setup:uninstall -n

echo "[+] Installing..."
install_cmd="./bin/magento setup:install \
  --db-host='localhost' \
  --db-name='mage2' \
  --db-user='root' \
  --db-password='mage2' \
  --backend-frontname=admin \
  --base-url='http://mage2.dev/' \
  --language=en_US \
  --currency='USD' \
  --timezone=America/Los_Angeles \
  --admin-lastname='mage2' \
  --admin-firstname='mage2' \
  --admin-email='foo@test.com' \
  --admin-user='admin' \
  --admin-password='password123' \
  --use-secure=0 \
  --use-rewrites=1 \
  --use-secure-admin=0 \
  --session-save=files"

if [[ -n $SAMPLE_DATA ]]; then
    install_cmd="${install_cmd} --use-sample-data"
fi

eval ${install_cmd}

#change directory back to where user ran script
cd -
