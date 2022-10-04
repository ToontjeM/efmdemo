#!/bin/bash

sudo systemctl stop edb-efm-4.4.service
sleep 5
sudo systemctl disable edb-efm-4.4.service

sudo systemctl stop postgres.service
sleep 5
sudo systemctl disable postgres.service

