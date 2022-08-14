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
cd ~/charon-distributed-validator-node/ && docker compose down && git pull

#start
docker compose -f docker-compose.yml -f docker-compose.bootnodes.yml up -d

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mdocker compose logs --tail 100 -f \e[0m'
