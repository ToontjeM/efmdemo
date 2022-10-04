#!/bin/bash

# Environment variables
DEMO_DIR=`pwd`				; export DEMO_DIR
#DEMO_DIR="/root/projects/efmdemo"	; export DEMO_DIR
BIN_DIR=${DEMO_DIR}/scripts		; export BIN_DIR

i=pg1
scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/data.sql admin@${i}:/home/admin
scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/pg1.sh admin@${i}:/home/admin
ssh -F ${DEMO_DIR}/ssh_config admin@${i} -t "chmod 755 /home/admin/data.sql"
ssh -F ${DEMO_DIR}/ssh_config admin@${i} -t "chmod 755 /home/admin/pg1.sh"
ssh -F ${DEMO_DIR}/ssh_config admin@${i} -t "/home/admin/pg1.sh"

i=pg3
scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/pg3.sh admin@${i}:/home/admin
ssh -F ${DEMO_DIR}/ssh_config admin@${i} -t "chmod 755 /home/admin/pg3.sh"
ssh -F ${DEMO_DIR}/ssh_config admin@${i} -t "/home/admin/pg3.sh"

for i in `echo "pg1 pg2"`
do
  echo ${i}
  scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/remote_ctl.sh admin@${i}:/home/admin
  scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/efm_rewind.sh admin@${i}:/home/admin
  scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/efm_reconfigure_node.sh admin@${i}:/home/admin
  ssh -F ${DEMO_DIR}/ssh_config admin@${i} -t "chmod 755 /home/admin/remote_ctl.sh"
  ssh -F ${DEMO_DIR}/ssh_config admin@${i} -t "/home/admin/remote_ctl.sh"
done
