#!/bin/bash

# Environment variables
DEMO_DIR=`pwd`				; export DEMO_DIR
BIN_DIR=${DEMO_DIR}/scripts		; export BIN_DIR

i=pg1
scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/data.sql root@${i}:/
scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/pg1.sh root@${i}:/
ssh -F ${DEMO_DIR}/ssh_config root@${i} -t "chmod 755 /data.sql"
ssh -F ${DEMO_DIR}/ssh_config root@${i} -t "chmod 755 /pg1.sh"
ssh -F ${DEMO_DIR}/ssh_config root@${i} -t "/pg1.sh"

i=pg3
scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/pg3.sh root@${i}:/
ssh -F ${DEMO_DIR}/ssh_config root@${i} -t "chmod 755 /pg3.sh"
ssh -F ${DEMO_DIR}/ssh_config root@${i} -t "/pg3.sh"

for i in `echo "pg1 pg2"`
do
  echo ${i}
  scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/remote_ctl.sh root@${i}:/
  scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/efm_rewind.sh root@${i}:/
  scp -F ${DEMO_DIR}/ssh_config ${BIN_DIR}/efm_reconfigure_node.sh root@${i}:/
  ssh -F ${DEMO_DIR}/ssh_config root@${i} -t "chmod 755 /remote_ctl.sh"
  ssh -F ${DEMO_DIR}/ssh_config root@${i} -t "/remote_ctl.sh"
done
