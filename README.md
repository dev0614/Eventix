## EVENTIX
A smart contract on the Ethereum blockchain to facilitate the creation,
resale, and validation of NFT-based event tickets (digital twins of traditional tickets sold on platforms like Eventbrite).

1. **NFT Ticket Creation:**
    - Implemented smart contracts to mint NFT tickets, each representing a digital twin of a physical event ticket, with unique identifiers and attributes.
2. **Ownership Transfer and Resale:**
    - Developed functions within the smart contract to facilitate the transfer of NFT tickets, reflecting the resale process and updating ownership details on the blockchain.
3. **Server Integration for Real-Time Verification:**
    - Emit relevant events for the server to index and store the updated owner details.
4. **Signature-Based NFT Transfers (EIP712):**
    - Implemented a feature to enable NFT ticket transfers using EIP712 signatures. This allows ticket owners to authorize the transfer of their NFT tickets through off-chain signatures, reducing the need for direct smart contract interactions.
5. **Ticket Pool Fuctionality:**
    - Developed a mechanism for ticket holders to put their tickets inside a pool so that their tickets can be resold automatically in a FIFO manner with dynamic pricing of tickets based on demand and time to event.







## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
