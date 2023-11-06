#!/bin/bash
sytemctl stop subspace-farmerd
systemctl stop subspace-noded 
rm /usr/local/bin/subspace-*
cd $HOME/subspace
wget -O subspace-node https://github.com/subspace/subspace/releases/download/gemini-3g-2023-nov-03/subspace-node-ubuntu-x86_64-skylake-gemini-3g-2023-nov-03
wget -O subspace-farmer https://github.com/subspace/subspace/releases/download/gemini-3g-2023-nov-03/subspace-farmer-ubuntu-x86_64-skylake-gemini-3g-2023-nov-03
chmod a+x subspace-*
cp subspace-* /usr/local/bin/

#restart node and farmer 
systemctl restart subspace-noded 
sleep 2
systemctl restart subspace-farmerd
sleep 2

#check node and farm working correctly 
if systemctl is-active --quiet subspace-noded.service; then
  # If the service is active, print success message in green color
  echo -e "\e[32mSubspace node started successfully\e[0m"
else
  # If the service is not active, print failure message in red color
  echo -e "\e[31mSubspace node failed to start\e[0m"
fi

if systemctl is-active --quiet subspace-farmerd.service; then
  # If the service is active, print success message in green color
  echo -e "\e[32mSubspace farmer started successfully\e[0m"
else
  # If the service is not active, print failure message in red color
  echo -e "\e[31mSubspace farmer failed to start wait for node synced and restart\e[0m"
fi

sleep 3
echo "#######################################################"
echo "journalctl -u subspace-noded -f --no-hostname | ccze -A"
echo "to check node log"
echo "journalctl -u subspace-farmerd -f --no-hostname | ccze -A"
echo "to check farmer log"
echo "#######################################################"
