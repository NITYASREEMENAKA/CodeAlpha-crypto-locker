# Crypto Time-Lock Wallet

A Solidity smart contract that lets users deposit ETH or ERC20 tokens with a
lock-in time. Withdrawals are blocked until the unlock time passes
(enforced using `block.timestamp`).

## What's inside

```
crypto-locker/
├── contracts/
│   └── TimeLockWallet.sol     <- the smart contract
├── test/
│   └── TimeLockWallet.js      <- automated tests (proves early withdraw fails)
├── scripts/
│   └── deploy.js              <- script to deploy on a local blockchain
├── hardhat.config.js          <- Hardhat project config
├── package.json
└── .gitignore
```

## How to run this in VS Code (step by step)

### 0. Prerequisites
Install these first if you don't have them:
- **Node.js** (v18 or later) — download from https://nodejs.org
- **VS Code** — download from https://code.visualstudio.com

Check they're installed by opening a terminal and running:
```bash
node -v
npm -v
```
Both should print a version number.

### 1. Unzip and open the project
1. Unzip `crypto-locker.zip` anywhere on your computer (e.g. Desktop).
2. Open VS Code.
3. Go to **File → Open Folder** and select the unzipped `crypto-locker` folder.

### 2. Open the built-in terminal
In VS Code: **Terminal → New Terminal** (or press `` Ctrl+` ``).
This opens a terminal already inside your project folder.

### 3. Install dependencies
In that terminal, run:
```bash
npm install
```
This downloads Hardhat, OpenZeppelin contracts, and the test helpers. It
may take a minute or two.

### 4. Compile the contract
```bash
npx hardhat compile
```
You should see:
```
Compiled 1 Solidity file successfully
```

### 5. Run the tests
```bash
npx hardhat test
```
Expected output:
```
TimeLockWallet
  ✔ should accept an ETH deposit with a lock time
  ✔ should BLOCK withdrawal before unlock time (early withdrawal test)
  ✔ should ALLOW withdrawal after unlock time has passed
  ✔ should revert withdraw if user has nothing deposited

4 passing
```
The second test is the important one for your assignment — it proves an
early withdrawal attempt is rejected by the contract.

### 6. (Optional) Deploy to a local test blockchain
Open a **second terminal** (click the `+` icon in the terminal panel) and run:
```bash
npx hardhat node
```
This starts a local fake blockchain with test accounts pre-loaded with fake ETH.
Leave this running.

In your **first terminal**, run:
```bash
npx hardhat run scripts/deploy.js --network localhost
```
You'll see the deployed contract address printed.

### 7. Recommended VS Code extension
Install **"Solidity" by Juan Blanco** from the Extensions tab (icon on the
left sidebar, or `Ctrl+Shift+X`) for syntax highlighting and inline errors
while editing `.sol` files.

## Submitting on Remix (assignment requirement)

Your assignment specifically asks you to deploy and test on **Remix IDE**
(remix.ethereum.org), not just locally in VS Code. Steps:
1. Go to https://remix.ethereum.org
2. Create `TimeLockWallet.sol` in the `contracts` folder and paste the
   contract code.
3. Compile it (Solidity Compiler tab, version 0.8.20+).
4. Deploy it (Deploy & Run tab, environment = "Remix VM").
5. Call `depositETH` with some ETH value and a lock duration (e.g. 120 seconds).
6. Immediately call `withdrawETH()` — it should **revert** (this is your
   proof that early withdrawal is blocked).
7. Wait or increase time, then call `withdrawETH()` again — it should succeed.

Take screenshots of steps 5–7 for your submission.
