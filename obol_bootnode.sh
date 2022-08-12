#!/bin/bash

echo -e "\e[0m"
echo -e "\033[0;35m"
echo " ╭――――――――――――――――――╮ ";
echo " │  SMART INVEST    │ ";
echo " │  From Mi Goi     │ ";
echo " ╰――――――――――――――――――╯ ";
echo -e "\e[0m"

sleep 2

#stop docker compose and reload
cd ~/charon-distributed-validator-node/ && docker compose down && git reset --hard && git pull

#create docker-compose.bootnodes.yml
sudo tee /root/charon-distributed-validator-node/docker-compose.bootnodes.yml > /dev/null <<EOF
version: '3.8'

services:
  charon:
    # Pegged charon version (update this for each release).
    # image: obolnetwork/charon:${CHARON_VERSION}
    image: ghcr.io/obolnetwork/charon:latest
    environment:
      CHARON_P2P_BOOTNODES: http://163.172.51.186:3640/enr
EOF

#start
docker compose -f docker-compose.yml -f docker-compose.bootnodes.yml up -d

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mdocker compose logs --tail 100 -f \e[0m'
