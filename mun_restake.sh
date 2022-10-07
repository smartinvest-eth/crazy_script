#!/bin/bash
for (( ;; )); do
	echo -e "\033[0;32mCollecting rewards!\033[0m"
	mund tx distribution withdraw-rewards $(mund keys show wallet --bech val -a) --commission --from wallet --chain-id testmun -y 
	echo -e "\033[0;32mWaiting 30 seconds before requesting balance\033[0m"
	sleep 30
	AMOUNT=$(mund q bank balances $(mund keys show wallet -a) | grep amount | awk '{split($0,a,"\""); print a[2]}')
	AMOUNT=$(($AMOUNT - 500))
	AMOUNT_STRING=$AMOUNT"utmun"
	echo -e "Your total balance: \033[0;32m$AMOUNT_STRING\033[0m"
	 mund tx staking delegate $(mund keys show wallet --bech val -a) $AMOUNT_STRING --from wallet --chain-id testmun -y
	echo -e "\033[0;32m$AMOUNT_STRING staked! Restarting in 3600 sec!\033[0m"
	sleep 3600
done
