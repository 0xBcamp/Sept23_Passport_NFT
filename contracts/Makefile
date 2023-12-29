-include .env

deploy-sepolia:
	forge script script/PassportResolver.s.sol:PassportResolverScript --rpc-url $(SEPOLIA_RPC_URL) --broadcast --private-key $(PRIVATE_KEY) --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

deploy:
	forge script script/PassportResolver.s.sol:PassportResolverScript --rpc-url http://127.0.0.1:8545 --broadcast --private-key $(PRIVATE_KEY_ANVIL)
