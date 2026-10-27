# Ethernaut Solutions

> Work in progress — this repository contains incomplete Ethernaut and Solidity security practice solutions.

A Foundry-based workspace for experimenting with Solidity contracts, attack scripts, and tests while learning EVM security concepts. Not all exercises or scripts are necessarily complete or passing.

## Repository layout

- `src/` — Solidity contracts and exercise implementations
- `test/` — Foundry tests
- `script/` — Foundry scripts
- `lib/` — Git submodules, including `forge-std` and OpenZeppelin Contracts
- `foundry.toml` — Foundry project configuration

## Getting started

Requires [Foundry](https://book.getfoundry.sh/).

```bash
git clone --recurse-submodules https://github.com/fromtaoyuanhsinchuuuu/ethernaut-solutions.git
cd ethernaut-solutions
forge build
forge test
```

Some scripts use an Ethereum RPC endpoint. If needed, set `ETH_RPC_URL` in your local environment; never commit RPC credentials, private keys, or seed phrases.

## Status and security notes

- This is a personal learning workspace, **not** a production audit framework.
- Inspect scripts carefully before running any transaction or broadcast command.
- Build and test commands are documented for convenience; their success has **not** been verified as part of this README update.

## Documentation change

This README improvement was prepared through a ChatGPT GitHub Connector write-access test in a separate branch and submitted for review without merging into `main`.
