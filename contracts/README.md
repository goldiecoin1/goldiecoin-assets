# Goldiecoin Smart Contracts

## GoldiecoinV5.sol

The main Goldiecoin smart contract implementing LayerZero V2 OApp for omnichain functionality.

### Key Features

- **LayerZero V2 Integration**: Seamless cross-chain transfers between BSC and Base
- **Auto-Growing Liquidity**: 0.25% buy fee, 2% sell fee automatically added to LP
- **Anti-Whale Protection**: Configurable max transaction limits (auto-disables after 60 days)
- **Anti-Bot Protection**: Same-block transaction prevention
- **Dynamic Fee System**: Adjustable buy/sell fees (max 3%)
- **Trading Controls**: Enable/disable trading functionality
- **Blacklist System**: Prevent malicious actors
- **24h Timelock**: Governance safety for wallet management changes

### Contract Addresses

**BNB Smart Chain (BSC)**
- Address: `0x0FD9CCC81857F2883F38ed2AD5ce826a91785627`
- Chain ID: 56
- Verified: [BSCScan](https://bscscan.com/address/0x0fd9ccc81857f2883f38ed2ad5ce826a91785627#code)

**Base Network**
- Address: `0x724100F1B0D5D486016965C14fF9125bD31a8f6E`
- Chain ID: 8453
- Verified: [BaseScan](https://basescan.org/address/0x724100F1B0D5D486016965C14fF9125bD31a8f6E#code)

### Technical Specifications

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Total Supply
uint256 constant TOTAL_SUPPLY = 32_000_000_000 * 10**18; // 32 Billion

// Fee Configuration
uint256 public buyFee = 25;   // 0.25% (25 basis points)
uint256 public sellFee = 200; // 2% (200 basis points)
uint256 constant MAX_FEE = 300; // 3% maximum

// Decimals
uint8 constant DECIMALS = 18;
```

### Dependencies

- **LayerZero V2**: `@layerzerolabs/oft-evm`
- **OpenZeppelin Contracts v4**: Access control, security, cryptography

### Auto-Liquidity Mechanism

The contract automatically converts accumulated fees into liquidity:

1. **Fee Collection**: 0.25% on buys, 2% on sells collected in GOLDI
2. **Threshold Check**: When contract balance ≥ `swapTokensAtAmount`
3. **Auto-Swap**: 50% of fees swapped to BNB
4. **LP Addition**: Remaining GOLDI + BNB added to PancakeSwap LP
5. **LP Burn**: LP tokens sent to burn address (0x...dEaD)

### Security Features

- ✅ ReentrancyGuard on critical functions
- ✅ Pausable in emergency situations
- ✅ Ownership controls with 24h timelock
- ✅ Maximum fee caps (3%)
- ✅ Anti-whale and anti-bot protections
- ✅ Blacklist functionality

### Deployment

**Constructor Parameters:**
```solidity
constructor(
    address _lzEndpoint,  // LayerZero endpoint address
    address _delegate,    // Initial owner/delegate
    bool _mintSupply      // true = mint initial supply on deploy
)
```

**BSC Deployment:**
- LayerZero Endpoint: `0x1a44076050125825900e736c501f859c50fE728c`
- Initial Supply: Minted (32B GOLDI)

**Base Deployment:**
- LayerZero Endpoint: `0x1a44076050125825900e736c501f859c50fE728c`
- Initial Supply: Not minted (bridged from BSC)

### Audit Status

- **Self-Audited**: Yes
- **Third-Party Audit**: Pending
- **Whitepaper**: [View PDF](https://github.com/goldiecoin1/goldiecoin-website/blob/main/GoldiecoinV5_Whitepaper.pdf)

### License

MIT License - See LICENSE file for details

---

**Disclaimer**: This smart contract has been self-audited but not yet reviewed by a third-party security firm. Use at your own risk. Always DYOR (Do Your Own Research).
