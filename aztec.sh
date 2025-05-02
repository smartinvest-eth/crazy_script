
#!/bin/bash
# Aztec Node Setup Script - Cài đặt validator & prover (Aztec Alpha Testnet)

echo "==== AZTEC NODE INSTALLATION ===="
echo "Vui lòng nhập các thông tin cần thiết:"

read -p "RPC_URL (Execution Sepolia RPC endpoint): " RPC_URL
read -p "BEACON_URL (Consensus Sepolia Beacon endpoint): " BEACON_URL
read -p "ETH_PRIVATE_KEY (0x...): " ETH_PRIVATE_KEY
read -p "ETH_ADDRESS (0x...): " ETH_ADDRESS
PUBLIC_IP="$(curl -s ipv4.icanhazip.com)"

set -e

AZTEC_DIR="/root/aztec"
ENV_FILE="${AZTEC_DIR}/aztec.env"
PROVER_SCRIPT="${AZTEC_DIR}/aztec-prover-run.sh"

# 1. Cài đặt phụ thuộc hệ thống
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git build-essential automake autoconf make gcc g++ \
  libssl-dev libgbm1 libleveldb-dev liblz4-tool pkg-config clang jq unzip

# Cài Node.js LTS (18.x) và Yarn
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
npm install -g yarn

# 2. Tải mã nguồn Aztec
if [ ! -d "$AZTEC_DIR" ]; then
  git clone https://github.com/AztecProtocol/aztec-packages.git "$AZTEC_DIR"
fi
cd "$AZTEC_DIR"
chown -R root:root "$AZTEC_DIR"

# 3. Build mã nguồn Aztec
cd l1-contracts && ./bootstrap.sh && cd ../yarn-project
yarn install && yarn build

# 4. Tạo file môi trường
cat > "${ENV_FILE}" <<EOF
ETHEREUM_HOSTS="${RPC_URL}"
L1_CONSENSUS_HOST_URLS="${BEACON_URL}"
L1_CHAIN_ID="11155111"
VALIDATOR_PRIVATE_KEY="${ETH_PRIVATE_KEY}"
COINBASE="${ETH_ADDRESS}"
PROVER_PUBLISHER_PRIVATE_KEY="${ETH_PRIVATE_KEY}"
PROVER_COORDINATION_NODE_URL="http://localhost:8080"
PROVER_BROKER_HOST="http://localhost:8081"
LOG_LEVEL="info"
EOF

# 5. Tạo script prover runner
cat > "${PROVER_SCRIPT}" <<'EOF'
#!/bin/bash
/usr/bin/node /root/aztec/yarn-project/aztec/dest/bin/index.js \
  start --prover-broker --network alpha-testnet --port 8081 &
sleep 2
/usr/bin/node /root/aztec/yarn-project/aztec/dest/bin/index.js \
  start --prover-agent --network alpha-testnet --port 8083 &
sleep 2
exec /usr/bin/node /root/aztec/yarn-project/aztec/dest/bin/index.js \
  start --prover-node --archiver --network alpha-testnet --port 8082
EOF
chmod +x "${PROVER_SCRIPT}"

# 6. Dịch vụ validator
cat > /etc/systemd/system/aztec-validator.service <<EOF
[Unit]
Description=Aztec Validator (Sequencer) Node
After=network.target

[Service]
User=root
WorkingDirectory=${AZTEC_DIR}
EnvironmentFile=${ENV_FILE}
ExecStart=/usr/bin/node ${AZTEC_DIR}/yarn-project/aztec/dest/bin/index.js \
  start --node --archiver --sequencer --network alpha-testnet \
  --l1-rpc-urls \${ETHEREUM_HOSTS} --l1-consensus-host-urls \${L1_CONSENSUS_HOST_URLS} \
  --sequencer.validatorPrivateKey \${VALIDATOR_PRIVATE_KEY} --sequencer.coinbase \${COINBASE} \
  --p2p.p2pIp ${PUBLIC_IP}
Restart=always
RestartSec=5s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 7. Dịch vụ prover
cat > /etc/systemd/system/aztec-prover.service <<EOF
[Unit]
Description=Aztec Prover (Node, Broker, Agent)
After=network.target aztec-validator.service

[Service]
User=root
WorkingDirectory=${AZTEC_DIR}
EnvironmentFile=${ENV_FILE}
Environment="P2P_ENABLED=false"
ExecStart=${PROVER_SCRIPT}
Restart=always
RestartSec=5s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 8. Khởi động dịch vụ
systemctl daemon-reload
systemctl enable aztec-validator.service aztec-prover.service
systemctl start aztec-validator.service aztec-prover.service

echo "✅ Đã cài đặt và khởi chạy validator & prover Aztec."
echo "Xem log bằng: journalctl -fu aztec-validator hoặc journalctl -fu aztec-prover"
