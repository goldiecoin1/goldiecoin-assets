# Goldiecoin Integration Guide

Complete guide for integrating Goldiecoin (GOLDI) into wallets, exchanges, and dApps.

## Quick Integration

### Basic Token Information

```json
{
  "name": "Goldiecoin",
  "symbol": "GOLDI",
  "decimals": 18,
  "type": "BEP20 / LayerZero OFT",
  "networks": ["BSC", "Base"]
}
```

### Network-Specific Details

**BNB Smart Chain (Primary)**
```json
{
  "chainId": 56,
  "rpcUrl": "https://bsc-dataseed1.binance.org",
  "contract": "0x0FD9CCC81857F2883F38ed2AD5ce826a91785627",
  "explorer": "https://bscscan.com/token/0x0fd9ccc81857f2883f38ed2ad5ce826a91785627",
  "dex": "PancakeSwap V2"
}
```

**Base Network**
```json
{
  "chainId": 8453,
  "rpcUrl": "https://mainnet.base.org",
  "contract": "0x724100F1B0D5D486016965C14fF9125bD31a8f6E",
  "explorer": "https://basescan.org/token/0x724100F1B0D5D486016965C14fF9125bD31a8f6E",
  "status": "Deployed (Trading TBA)"
}
```

## Wallet Integration

### MetaMask / Web3 Wallets

**Add Token Programmatically:**
```javascript
const tokenAddress = '0x0FD9CCC81857F2883F38ed2AD5ce826a91785627';
const tokenSymbol = 'GOLDI';
const tokenDecimals = 18;
const tokenImage = 'https://cdn.jsdelivr.net/gh/goldiecoin1/goldiecoin-assets@main/logos/bsc/logo-256x256.png';

try {
  const wasAdded = await ethereum.request({
    method: 'wallet_watchAsset',
    params: {
      type: 'ERC20',
      options: {
        address: tokenAddress,
        symbol: tokenSymbol,
        decimals: tokenDecimals,
        image: tokenImage,
      },
    },
  });

  if (wasAdded) {
    console.log('GOLDI added to wallet');
  }
} catch (error) {
  console.error(error);
}
```

### Trust Wallet

**info.json Format:**
```json
{
  "name": "Goldiecoin",
  "type": "BEP20",
  "symbol": "GOLDI",
  "decimals": 18,
  "website": "https://goldiecoin.fun",
  "description": "Omnichain memecoin with auto-growing liquidity powered by LayerZero V2",
  "explorer": "https://bscscan.com/token/0x0FD9CCC81857F2883F38ed2AD5ce826a91785627",
  "status": "active",
  "id": "0x0FD9CCC81857F2883F38ed2AD5ce826a91785627",
  "links": [
    {
      "name": "twitter",
      "url": "https://x.com/GoldiecoinX"
    },
    {
      "name": "telegram",
      "url": "https://t.me/GoldiecoinX"
    },
    {
      "name": "whitepaper",
      "url": "https://github.com/goldiecoin1/goldiecoin-website/blob/main/GoldiecoinV5_Whitepaper.pdf"
    }
  ],
  "tags": [
    "omnichain",
    "layerzero",
    "memecoin",
    "defi",
    "auto-liquidity"
  ]
}
```

## Exchange Integration

### Reading Contract Data

**Using ethers.js:**
```javascript
const { ethers } = require('ethers');

const provider = new ethers.providers.JsonRpcProvider('https://bsc-dataseed1.binance.org');
const contractAddress = '0x0FD9CCC81857F2883F38ed2AD5ce826a91785627';

const abi = [
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function decimals() view returns (uint8)',
  'function totalSupply() view returns (uint256)',
  'function balanceOf(address) view returns (uint256)',
  'function buyFee() view returns (uint256)',
  'function sellFee() view returns (uint256)'
];

const contract = new ethers.Contract(contractAddress, abi, provider);

async function getTokenInfo() {
  const name = await contract.name();
  const symbol = await contract.symbol();
  const decimals = await contract.decimals();
  const totalSupply = await contract.totalSupply();
  const buyFee = await contract.buyFee();
  const sellFee = await contract.sellFee();

  console.log({
    name,
    symbol,
    decimals,
    totalSupply: ethers.utils.formatEther(totalSupply),
    buyFeePercent: buyFee / 100, // 25 basis points = 0.25%
    sellFeePercent: sellFee / 100 // 200 basis points = 2%
  });
}
```

### Fee Calculation

Goldiecoin implements dynamic fees on DEX trades:

```javascript
function calculateFees(amount, isBuy) {
  const FEE_DENOMINATOR = 10000;
  const buyFee = 25;  // 0.25%
  const sellFee = 200; // 2%

  const feeRate = isBuy ? buyFee : sellFee;
  const fee = amount * feeRate / FEE_DENOMINATOR;
  const amountAfterFee = amount - fee;

  return {
    gross: amount,
    fee: fee,
    net: amountAfterFee,
    feePercent: (feeRate / 100).toFixed(2) + '%'
  };
}

// Example: Buy 1000 GOLDI
console.log(calculateFees(1000, true));
// { gross: 1000, fee: 2.5, net: 997.5, feePercent: '0.25%' }

// Example: Sell 1000 GOLDI
console.log(calculateFees(1000, false));
// { gross: 1000, fee: 20, net: 980, feePercent: '2.00%' }
```

## Price Feed Integration

### PancakeSwap V2 LP

```javascript
const lpAddress = '0xc0C0a3D44a026bEbD1edaB5cD181fFffafa2fC45'; // GOLDI/WBNB LP
const lpAbi = [
  'function getReserves() view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)',
  'function token0() view returns (address)',
  'function token1() view returns (address)'
];

const lpContract = new ethers.Contract(lpAddress, lpAbi, provider);

async function getPrice() {
  const reserves = await lpContract.getReserves();
  const token0 = await lpContract.token0();
  const token1 = await lpContract.token1();

  // Determine which reserve is GOLDI
  const goldiIsToken0 = token0.toLowerCase() === contractAddress.toLowerCase();
  const goldiReserve = goldiIsToken0 ? reserves[0] : reserves[1];
  const wbnbReserve = goldiIsToken0 ? reserves[1] : reserves[0];

  // Price = WBNB Reserve / GOLDI Reserve
  const price = wbnbReserve / goldiReserve;

  console.log('GOLDI Price:', price, 'BNB');
  return price;
}
```

## Logo Assets

### Available Formats

All logos available via CDN:

```
32x32 SVG (Recommended for small icons):
https://cdn.jsdelivr.net/gh/goldiecoin1/goldiecoin-assets@main/logos/bsc/logo-32x32.svg

64x64 PNG:
https://cdn.jsdelivr.net/gh/goldiecoin1/goldiecoin-assets@main/logos/bsc/logo-64x64.png

128x128 PNG:
https://cdn.jsdelivr.net/gh/goldiecoin1/goldiecoin-assets@main/logos/bsc/logo-128x128.png

256x256 PNG (Recommended for wallets):
https://cdn.jsdelivr.net/gh/goldiecoin1/goldiecoin-assets@main/logos/bsc/logo-256x256.png
```

## Testing

### Testnet Contracts

Currently only deployed on mainnet. For testing, use small amounts on:
- BSC Mainnet: `0x0FD9CCC81857F2883F38ed2AD5ce826a91785627`

### Verify Integration

```javascript
// Check if contract is valid
async function verifyContract() {
  try {
    const code = await provider.getCode(contractAddress);
    if (code === '0x') {
      console.error('No contract at this address');
      return false;
    }

    const symbol = await contract.symbol();
    if (symbol !== 'GOLDI') {
      console.error('Wrong token');
      return false;
    }

    console.log('✅ Contract verified');
    return true;
  } catch (error) {
    console.error('Verification failed:', error);
    return false;
  }
}
```

## Support

For integration assistance:
- **Email**: contact@goldiecoin.fun
- **Telegram**: https://t.me/GoldiecoinX
- **Documentation**: https://goldiecoin.fun

## Security Considerations

1. **Always verify contract address** before integration
2. **Fees apply on DEX trades** (0.25% buy, 2% sell)
3. **Use checksummed addresses** for BSC compatibility
4. **Test with small amounts** first
5. **LP tokens are burned** - rugproof by design

---

**Last Updated**: January 11, 2026
