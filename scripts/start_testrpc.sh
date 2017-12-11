testrpc_port=8545
ganache-cli --network-id "${DEV_NETWORK_ID}" --gasLimit 0xfffffffffff  -m "${WALLET_MNEMONIC}" --port "$testrpc_port"
