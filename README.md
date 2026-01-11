# Goldiecoin Assets

Official asset repository for Goldiecoin (GOLDI) - An Omnichain Memecoin powered by LayerZero V2.

## 🌐 Overview

Goldiecoin is a fair-launched, rugproof omnichain memecoin with auto-growing liquidity mechanisms. This repository contains official logos, smart contract source code, and documentation for integration with wallets, exchanges, and dApps.

## 📊 Token Information

### BNB Smart Chain (BSC)
- **Contract Address**: `0x0FD9CCC81857F2883F38ed2AD5ce826a91785627`
- **Chain ID**: 56
- **Decimals**: 18
- **BSCScan**: [View Contract](https://bscscan.com/token/0x0fd9ccc81857f2883f38ed2ad5ce826a91785627)
- **Trading**: [PancakeSwap](https://pancakeswap.finance/swap?outputCurrency=0x0FD9CCC81857F2883F38ed2AD5ce826a91785627)

### Base Network
- **Contract Address**: `0x724100F1B0D5D486016965C14fF9125bD31a8f6E`
- **Chain ID**: 8453
- **Decimals**: 18
- **BaseScan**: [View Contract](https://basescan.org/token/0x724100F1B0D5D486016965C14fF9125bD31a8f6E)
- **Status**: Deployed (Trading not yet enabled)

## 🎨 Logo Assets

Official Goldiecoin logo (32x32 SVG):

```
https://cdn.jsdelivr.net/gh/goldiecoin1/goldiecoin-assets@main/logos/goldiecoin-logo-32x32.svg
```

## 📄 Smart Contracts

### Goldiecoin V5 (Current)
- **Technology**: LayerZero V2 OApp
- **Features**:
  - Omnichain transfers between BSC and Base
  - Auto-growing liquidity (0.25% buy / 2% sell)
  - Permanently burned LP tokens
  - Fair launch (no presale, no team allocation at launch)
- **Source Code**: See `/contracts` directory
- **Audit**: Self-audited ([View Security Audit](https://github.com/goldiecoin1/goldiecoin-website/blob/main/Goldiecoin_Security_Self_Audit_2025.pdf))

## 🔗 Official Links

- **Website**: https://goldiecoin.fun
- **Twitter**: https://x.com/GoldiecoinX
- **Telegram**: https://t.me/GoldiecoinX
- **LinkedIn**: https://www.linkedin.com/in/justi-goldie-7b8bb139b
- **Whitepaper**: [PDF](https://github.com/goldiecoin1/goldiecoin-website/blob/main/GoldiecoinV5_Whitepaper.pdf)

## 💎 Tokenomics

- **Total Supply**: 32,000,000,000 GOLDI
- **Circulating Supply**: ~8,000,000,000 GOLDI (in LP)
- **Buy Tax**: 0.25% (goes to auto-LP)
- **Sell Tax**: 2% (goes to auto-LP)
- **LP Status**: Burned to 0x...dEaD (Rugproof)
- **Launch Date**: January 3, 2026, 21:00 UTC

## 🛠️ Integration Guide

### Trust Wallet / MetaMask
1. Open your wallet
2. Click "Add Token" or "Import Token"
3. Select "Custom Token"
4. Enter contract address: `0x0FD9CCC81857F2883F38ed2AD5ce826a91785627`
5. Token symbol and decimals will auto-fill
6. Confirm addition

### PancakeSwap
Direct trading link:
```
https://pancakeswap.finance/swap?outputCurrency=0x0FD9CCC81857F2883F38ed2AD5ce826a91785627
```

Or manually:
1. Go to https://pancakeswap.finance/swap
2. Click on "Select a currency"
3. Paste contract address: `0x0FD9CCC81857F2883F38ed2AD5ce826a91785627`
4. Import token and trade

## 📋 Token List Format

### Trust Wallet Format
```json
{
  "asset": "c60_t0x0FD9CCC81857F2883F38ed2AD5ce826a91785627",
  "type": "BEP20",
  "address": "0x0FD9CCC81857F2883F38ed2AD5ce826a91785627",
  "name": "Goldiecoin",
  "symbol": "GOLDI",
  "decimals": 18,
  "logoURI": "https://assets.trustwallet.com/blockchains/smartchain/assets/0x0FD9CCC81857F2883F38ed2AD5ce826a91785627/logo.png",
  "pairs": []
}
```

### PancakeSwap Token List Format
```json
{
  "name": "Goldiecoin",
  "symbol": "GOLDI",
  "address": "0x0FD9CCC81857F2883F38ed2AD5ce826a91785627",
  "chainId": 56,
  "decimals": 18,
  "logoURI": "https://tokens.pancakeswap.finance/images/0x0FD9CCC81857F2883F38ed2AD5ce826a91785627.png"
}
```

## 🔐 Security

- ✅ **Contract Verified** on BSCScan and BaseScan
- ✅ **LP Tokens Burned** to 0x000000000000000000000000000000000000dEaD
- ✅ **Ownership Renounced** (Fair launch principles)
- ✅ **Auto-LP Mechanism** (Non-custodial, automated liquidity growth)
- ✅ **Self-Audited** ([Security Audit Report](https://github.com/goldiecoin1/goldiecoin-website/blob/main/Goldiecoin_Security_Self_Audit_2025.pdf))

### Burn Transaction
- **TX Hash**: `0x290d0e95cfa8d76c4432cdb215d5aff4ff67c8a62e722e93552656f7ae32c99f`
- **BSCScan**: [View Transaction](https://bscscan.com/tx/0x290d0e95cfa8d76c4432cdb215d5aff4ff67c8a62e722e93552656f7ae32c99f)

## 📞 Contact

- **Email**: contact@goldiecoin.fun
- **Support**: Via [Telegram](https://t.me/GoldiecoinX)

## ⚠️ Disclaimer

Goldiecoin (GOLDI) is a memecoin created for entertainment purposes. Cryptocurrency investments carry high risk. Please do your own research (DYOR) and never invest more than you can afford to lose. This token has no intrinsic value or expectation of financial return.

## 📜 License

All assets and code in this repository are released under the MIT License unless otherwise specified.

---

**Last Updated**: January 11, 2026
**Version**: 1.0.0
