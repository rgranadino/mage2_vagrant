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
export MAGE_MODE='developer'
echo "Uninstalling..."
php -f dev/shell/install.php -- --uninstall --cleanup_database 1
echo "Installing..."
if [[ -n $SAMPLE_DATA ]]
then
   echo "Installing sample data..."
   mysql -uroot -pmage2 mage2 < /vagrant/data/m2-sample-data/m2sample.sql
   rsync -crt /vagrant/data/m2-sample-data/pub/ /vagrant/data/magento2/pub/
fi
php -f dev/shell/install.php -- \
  --license_agreement_accepted "yes" \
  --locale "en_US" \
  --timezone "America/Los_Angeles" \
  --default_currency "USD" \
  --db_host "localhost" \
  --db_name "mage2" \
  --db_user "root" \
  --db_pass "mage2" \
  --url "http://mage2.dev" \
  --use_rewrites "yes" \
  --use_secure_admin "no" \
  --use_secure "no" \
  --secure_base_url "http://mage2.dev" \
  --admin_lastname "mage2" \
  --admin_firstname "mage2" \
  --admin_email "foo@test.com" \
  --admin_username "admin" \
  --admin_password "p4ssw0rd" \
  --skip_url_validation "yes" \
  --session_save db
cd -
