#!/bin/bash

sudo systemctl stop edb-efm-4.7.service
sleep 5
sudo systemctl disable edb-efm-4.7.service

sudo systemctl stop postgres.service
sleep 5
sudo systemctl disable postgres.service

