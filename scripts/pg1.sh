#!/bin/bash

sudo -i cp /home/admin/data.sql /var/lib/edb-as
sudo -i chown enterprisedb:enterprisedb /var/lib/edb-as/data.sql
sudo -i chmod 775 /var/lib/edb-as/data.sql
sudo -i -u enterprisedb psql -d edb -f /var/lib/edb-as/data.sql
