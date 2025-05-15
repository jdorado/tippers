# Test Project for JDorado

This is a test project to evaluate JDorado's coding skills, focusing on blockchain development across Solana, Ethereum, and BNB Chain.

## Installation

```bash
# Install root dependencies
pnpm install

# Install contract dependencies
pnpm contracts:install

# Install Foundry (if not installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup
```
## Testing

### Smart Contracts
```bash
# Run basic tests
pnpm contracts:test

# Deploy to local network
pnpm contracts:deploy:local

# Deploy to Sepolia testnet
pnpm contracts:deploy:sepolia
```

## Project Structure

```
├── contracts/          # Smart contracts (Foundry)
│   ├── src/           # Contract source files
│   ├── test/          # Contract test files
│   └── script/        # Deployment scripts
├── client/            # Frontend application
└── server/            # Backend server
```

## Features

- Multi-chain support (Solana, Ethereum, BNB Chain)
- Wallet integration (Phantom, MetaMask)
- Smart contract integration
- Game mechanics implementation

## License

Private - All Rights Reserved
