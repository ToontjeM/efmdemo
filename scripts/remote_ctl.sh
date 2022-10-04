#!/bin/bash

sudo -i cp /home/admin/efm_rewind.sh /usr/edb/efm-4.4/bin
sudo -i chmod 755 /usr/edb/efm-4.4/bin/efm_rewind.sh

sudo -i cp /home/admin/efm_reconfigure_node.sh /usr/edb/efm-4.4/bin
sudo -i chmod 755 /usr/edb/efm-4.4/bin/efm_reconfigure_node.sh

sudo sed -e 's/local.timeout=60/local.timeout=10/' \
	 -e 's/local.period=10/local.period=5/'    \
	 /etc/edb/efm-4.4/efmdemo.properties > /home/admin/efmdemo.properties_tmp

sudo systemctl stop edb-efm-4.4.service
sleep 5

sudo cp /home/admin/efmdemo.properties_tmp /etc/edb/efm-4.4/efmdemo.properties

sudo systemctl start edb-efm-4.4.service
sleep 5

sudo -i -u enterprisedb psql -d edb -c "SELECT pg_create_physical_replication_slot('pg1');"
sudo -i -u enterprisedb psql -d edb -c "SELECT pg_create_physical_replication_slot('pg2');"
