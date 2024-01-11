-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_KEY := fbf992b0e25ad29c85aae3d69fcb7f09240dd2588ecee449a4934b9e499102cc

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install Cyfrin/foundry-devops@0.0.11 --no-commit --no-commit && forge install foundry-rs/forge-std@v1.5.3 --no-commit && forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url https://eth-sepolia.g.alchemy.com/v2/yXxXG0ltqNKnxq40IQSpMTCsM_Sln2e0 --private-key $(DEFAULT_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(ALCHEMY_RPC_URL) --private-key $(METAMASK_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployEventix.s.sol:DeployEventix $(NETWORK_ARGS)

# cast abi-encode "constructor(uint256)" 1000000000000000000000000 -> 0x00000000000000000000000000000000000000000000d3c21bcecceda1000000
# Update with your contract address, constructor arguments and anything else
verify:
	@forge verify-contract --chain-id 11155111 --num-of-optimizations 200 --watch --constructor-args 00000000000000000000000066aaf3098e1eb1f24348e84f509d8bcfd92d0620 --etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version 0.8.21+commit.d9974bed 0x63Ab7157810Af3386491b4Efbff79bED0aAe41DA src/Eventix.sol:Eventix
#https://sepolia.etherscan.io/address/0x63ab7157810af3386491b4efbff79bed0aae41da