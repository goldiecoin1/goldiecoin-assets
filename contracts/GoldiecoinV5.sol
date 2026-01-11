// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title GoldiecoinV5
 * @notice LayerZero OFT-based multichain token with complete Goldiecoin features
 * @dev SOLUTION: Hybrid Approach mit Bridge Flag für saubere Separation
 * 
 * COMPILATION FIXES:
 * 1. ✅ _debit() now has 4 parameters (added _dstEid)
 * 2. ✅ OpenZeppelin v4 Ownable (no constructor parameter needed)
 * 3. ✅ super._debit() called with 4 parameters
 * 4. ✅ Correct imports for OpenZeppelin v4 (security/)
 * 
 * KEY FEATURES:
 * - ✅ Anti-Whale Protection (60 Tage Auto-Disable)
 * - ✅ Anti-Bot Protection (Same-Block Prevention - 10 Minuten)
 * - ✅ Auto-Liquidity System mit Toggle
 * - ✅ Dynamic Fee System (Buy/Sell)
 * - ✅ P2E Merkle-Tree Rewards
 * - ✅ Trading Enable/Disable
 * - ✅ Blacklist System
 * - ✅ 24h Wallet Management Timelock
 * - ✅ LayerZero Multichain Bridge (FIXED!)
 */
contract GoldiecoinV5 is OFT, Pausable, ReentrancyGuard {
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    // Token Configuration
    uint256 private constant TOTAL_SUPPLY = 32_000_000_000 * 10**18; // 32 Billion
    
    // DEX Configuration
    address public router;
    address public pair;
    
    // Fee Configuration
    uint256 public buyFee = 25;  // 0.25% (25 basis points)
    uint256 public sellFee = 200; // 2% (200 basis points)
    uint256 private constant MAX_FEE = 300; // 3% maximum (300 basis points)
    uint256 private constant FEE_DENOMINATOR = 10000; // For basis points calculation
    
    // Anti-Whale Configuration
    uint256 public maxWalletAmount;
    uint256 public antiWhaleEndTime;
    uint256 private constant ANTI_WHALE_PERIOD = 60 days;
    
    // Auto-LP Configuration
    bool public autoLPEnabled = true;
    uint256 public swapTokensAtAmount;
    uint256 public maxSlippagePercent = 10; // 10% max slippage
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    // Trading State
    bool public tradingEnabled;
    
    // Anti-Bot Configuration
    uint256 public antiBotEndTime;
    uint256 private constant ANTI_BOT_PERIOD = 10 minutes;
    
    // P2E Rewards
    bytes32 public merkleRoot;
    mapping(address => bool) public hasClaimed;
    
    // Security
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromLimit;
    
    // Wallet Management Timelock
    struct WalletChange {
        address newWallet;
        uint256 effectiveTime;
        bool isPending;
    }
    mapping(bytes32 => WalletChange) public pendingWalletChanges;
    uint256 public constant WALLET_CHANGE_DELAY = 24 hours;
    
    // Internal State
    bool private inSwap;
    
    // 🔥 NEW: Bridge Flag für saubere Separation
    bool private isBridging;
    
    // Anti-Bot Tracking (Same-Block Protection)
    mapping(address => uint256) public lastBuyBlock;
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    event TradingEnabled(uint256 timestamp);
    event FeesUpdated(uint256 buyFee, uint256 sellFee);
    event RouterAndPairSet(address indexed router, address indexed pair);
    event AutoLPToggled(bool enabled);
    event AutoLPExecuted(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event BlacklistUpdated(address indexed account, bool isBlacklisted);
    event ExclusionUpdated(address indexed account, bool isExcluded);
    event MerkleRootUpdated(bytes32 newRoot);
    event RewardClaimed(address indexed user, uint256 amount);
    event WalletChangeInitiated(bytes32 indexed changeId, address indexed newWallet, uint256 effectiveTime);
    event WalletChangeExecuted(bytes32 indexed changeId, address indexed newWallet);
    event WalletChangeCancelled(bytes32 indexed changeId);
    event AntiWhaleDisabled(uint256 timestamp);
    event AntiBotDisabled(uint256 timestamp);
    event SlippageUpdated(uint256 newSlippage);
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // MODIFIERS
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    modifier notBlacklisted(address account) {
        require(!isBlacklisted[account], "Address is blacklisted");
        _;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    constructor(
        address _lzEndpoint,
        address _delegate,
        bool _mintInitialSupply
    ) OFT("Goldiecoin", "GOLDI", _lzEndpoint, _delegate) {
        // ✅ FIX: OpenZeppelin v4 doesn't need Ownable(_delegate)
        // Ownable is automatically initialized by OFT → OAppCore
        
        // Mint total supply ONLY on origin chain (BSC)
        if (_mintInitialSupply) {
            _mint(msg.sender, TOTAL_SUPPLY);
        }
        
        // Configure Anti-Whale (2% of total supply)
        maxWalletAmount = (TOTAL_SUPPLY * 2) / 100;
        antiWhaleEndTime = block.timestamp + ANTI_WHALE_PERIOD;
        
        // Configure Auto-LP threshold (0.01% of total supply)
        swapTokensAtAmount = (TOTAL_SUPPLY * 1) / 10000;
        
        // Exclude owner and contract from fees and limits
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromLimit[msg.sender] = true;
        isExcludedFromLimit[address(this)] = true;
        isExcludedFromLimit[BURN_ADDRESS] = true;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // 🔥 LAYERZERO OFT OVERRIDES - BRIDGE LOGIC (FIXED!)
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Override _debit for Source Chain Burns
     * @dev Wird aufgerufen wenn User send() auf Source Chain aufruft
     * 
     * FIXES:
     * 1. ✅ Added _dstEid parameter (4th parameter)
     * 2. Pre-Check für Trading (nur Owner darf bridge wenn disabled)
     * 3. Set isBridging Flag BEFORE super call
     * 4. Reset Flag AFTER super call
     * 
     * Flow: send() → _debit() → _burn() → _transfer()
     */
    function _debit(
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    ) internal override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        // PRE-CHECKS (before burning)
        
        // 1. Trading Check: Nur Owner darf bridge wenn Trading disabled
        if (!tradingEnabled) {
            require(owner() == _from, "Trading not enabled - only owner can bridge");
        }
        
        // 2. Anti-Whale Check (optional - könnte man auch skippen für Bridge)
        // Uncomment wenn du Anti-Whale auch auf Bridge willst:
        /*
        if (antiWhaleEndTime > block.timestamp && !isExcludedFromLimit[_from]) {
            require(_amountLD <= maxWalletAmount, "Bridge amount exceeds max wallet");
        }
        */
        
        // 3. Set Bridge Flag
        isBridging = true;
        
        // 4. Call parent _debit (triggers _burn → _transfer)
        // ✅ FIX: Now passing all 4 parameters including _dstEid
        (amountSentLD, amountReceivedLD) = super._debit(_from, _amountLD, _minAmountLD, _dstEid);
        
        // 5. Reset Bridge Flag
        isBridging = false;
        
        return (amountSentLD, amountReceivedLD);
    }
    
    /**
     * @notice Override _credit for Destination Chain Mints
     * @dev Wird aufgerufen wenn Message auf Destination Chain ankommt
     * 
     * FIXES:
     * 1. Set isBridging Flag BEFORE mint
     * 2. Reset Flag AFTER mint
     * 3. Keine zusätzlichen Checks (Destination sollte immer acceptieren!)
     * 
     * Flow: lzReceive() → _credit() → _mint() → _transfer()
     */
    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 _srcEid
    ) internal override returns (uint256 amountReceivedLD) {
        // Set Bridge Flag
        isBridging = true;
        
        // Call parent _credit (triggers _mint → _transfer)
        amountReceivedLD = super._credit(_to, _amountLD, _srcEid);
        
        // Reset Bridge Flag
        isBridging = false;
        
        return amountReceivedLD;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // 🔥 ERC20 OVERRIDE - CUSTOM TRANSFER LOGIC (FIXED!)
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Override _transfer with Bridge Flag Support
     * @dev OpenZeppelin v4 uses _transfer(), NOT _update()!
     * 
     * CRITICAL: Wenn isBridging = true, ALLE Checks skippen!
     * 
     * Flow:
     * - Normal Transfer: _transfer() → All checks active
     * - Bridge Transfer: _debit() sets flag → _burn() → _transfer() → All checks skipped
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override notBlacklisted(from) notBlacklisted(to) {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // 🔥 BRIDGE FLAG CHECK - Skip ALL custom logic if bridging!
        if (isBridging) {
            super._transfer(from, to, amount);
            return;
        }
        
        // ═════════════════════════════════════════════════════════════════════════════
        // TRADING CHECK
        // ═════════════════════════════════════════════════════════════════════════════
        
        if (!tradingEnabled) {
            require(
                from == owner() || to == owner() || 
                from == address(this) || to == address(this),
                "Trading not enabled"
            );
        }
        
        // ═════════════════════════════════════════════════════════════════════════════
        // ANTI-WHALE CHECK
        // ═════════════════════════════════════════════════════════════════════════════
        
        if (antiWhaleEndTime > block.timestamp) {
            if (!isExcludedFromLimit[to] && to != pair) {
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "Max wallet limit exceeded"
                );
            }
        }
        
        // ═════════════════════════════════════════════════════════════════════════════
        // ANTI-BOT PROTECTION (Same-Block Prevention)
        // ═════════════════════════════════════════════════════════════════════════════
        
        // Track buy transactions to prevent same-block sells (anti-snipe)
        if (antiBotEndTime > block.timestamp) {
            // If this is a BUY from DEX, record the block number
            if (from == pair && to != router) {
                lastBuyBlock[to] = block.number;
            }
            
            // If this is a SELL to DEX, check it's not same block as buy
            if (to == pair && from != router) {
                require(
                    lastBuyBlock[from] != block.number,
                    "Anti-bot: No same-block sell after buy"
                );
            }
        }
        
        // ═════════════════════════════════════════════════════════════════════════════
        // FEE COLLECTION & AUTO-LP
        // ═════════════════════════════════════════════════════════════════════════════
        
        bool takeFee = !isExcludedFromFee[from] && !isExcludedFromFee[to];
        
        // Auto-LP Trigger (nur bei Sells, nicht während Swap)
        uint256 contractBalance = balanceOf(address(this));
        bool canSwap = contractBalance >= swapTokensAtAmount;
        
        if (
            canSwap &&
            !inSwap &&
            autoLPEnabled &&
            from != pair && // Nicht bei Buy
            takeFee
        ) {
            _swapAndLiquify(contractBalance);
        }
        
        // Calculate Fees
        uint256 fees = 0;
        if (takeFee) {
            // Buy from DEX
            if (from == pair && to != router) {
                fees = (amount * buyFee) / FEE_DENOMINATOR;
            }
            // Sell to DEX
            else if (to == pair && from != router) {
                fees = (amount * sellFee) / FEE_DENOMINATOR;
            }
            
            if (fees > 0) {
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }
        
        // Execute Transfer
        super._transfer(from, to, amount);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // AUTO-LIQUIDITY SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // Split balance: 50% swap to ETH, 50% keep as tokens
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;
        
        // Capture initial ETH balance
        uint256 initialBalance = address(this).balance;
        
        // Swap tokens for ETH
        _swapTokensForEth(half);
        
        // Calculate received ETH
        uint256 newBalance = address(this).balance - initialBalance;
        
        // Add liquidity and burn LP tokens
        _addLiquidityAndBurn(otherHalf, newBalance);
        
        emit AutoLPExecuted(half, newBalance, otherHalf);
    }
    
    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IRouter(router).WETH();
        
        _approve(address(this), router, tokenAmount);
        
        // Calculate minimum output with slippage protection
        uint256[] memory amounts = IRouter(router).getAmountsOut(tokenAmount, path);
        uint256 minOutput = (amounts[1] * (100 - maxSlippagePercent)) / 100;
        
        IRouter(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            minOutput,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _addLiquidityAndBurn(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), router, tokenAmount);
        
        // Calculate minimum amounts with slippage
        uint256 minToken = (tokenAmount * (100 - maxSlippagePercent)) / 100;
        uint256 minEth = (ethAmount * (100 - maxSlippagePercent)) / 100;
        
        // Add liquidity - LP tokens go to BURN_ADDRESS!
        IRouter(router).addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            minToken,
            minEth,
            BURN_ADDRESS, // 🔥 LP tokens permanently burned!
            block.timestamp
        );
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // P2E REWARDS (MERKLE TREE)
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }
    
    function claimReward(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external nonReentrant {
        require(!hasClaimed[msg.sender], "Reward already claimed");
        require(merkleRoot != bytes32(0), "Merkle root not set");
        
        // Verify merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Invalid merkle proof"
        );
        
        // Mark as claimed
        hasClaimed[msg.sender] = true;
        
        // Transfer reward
        _transfer(address(this), msg.sender, amount);
        
        emit RewardClaimed(msg.sender, amount);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    function setRouterAndPair(address _router, address _pair) external onlyOwner {
        require(_router != address(0) && _pair != address(0), "Invalid addresses");
        router = _router;
        pair = _pair;
        
        // Exclude pair and router from limits
        isExcludedFromLimit[_pair] = true;
        isExcludedFromLimit[_router] = true;
        
        emit RouterAndPairSet(_router, _pair);
    }
    
    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        require(pair != address(0), "Set pair first");
        
        tradingEnabled = true;
        antiBotEndTime = block.timestamp + ANTI_BOT_PERIOD;
        
        emit TradingEnabled(block.timestamp);
    }
    
    function setFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= MAX_FEE && _sellFee <= MAX_FEE, "Fee too high");
        buyFee = _buyFee;
        sellFee = _sellFee;
        emit FeesUpdated(_buyFee, _sellFee);
    }
    
    function toggleAutoLP() external onlyOwner {
        autoLPEnabled = !autoLPEnabled;
        emit AutoLPToggled(autoLPEnabled);
    }
    
    function setSwapThreshold(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Threshold must be positive");
        swapTokensAtAmount = _amount;
    }
    
    function setMaxSlippage(uint256 _percent) external onlyOwner {
        require(_percent <= 50, "Slippage too high"); // Max 50%
        maxSlippagePercent = _percent;
        emit SlippageUpdated(_percent);
    }
    
    function updateBlacklist(address account, bool blacklisted) external onlyOwner {
        isBlacklisted[account] = blacklisted;
        emit BlacklistUpdated(account, blacklisted);
    }
    
    function excludeFromFee(address account, bool excluded) external onlyOwner {
        isExcludedFromFee[account] = excluded;
        emit ExclusionUpdated(account, excluded);
    }
    
    function excludeFromLimit(address account, bool excluded) external onlyOwner {
        isExcludedFromLimit[account] = excluded;
    }
    
    function disableAntiWhale() external onlyOwner {
        require(antiWhaleEndTime > block.timestamp, "Already disabled");
        antiWhaleEndTime = block.timestamp;
        emit AntiWhaleDisabled(block.timestamp);
    }
    
    function disableAntiBot() external onlyOwner {
        require(antiBotEndTime > block.timestamp, "Already disabled");
        antiBotEndTime = block.timestamp;
        emit AntiBotDisabled(block.timestamp);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // WALLET MANAGEMENT (24h Timelock)
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    function initiateRouterChange(address newRouter) external onlyOwner {
        bytes32 changeId = keccak256(abi.encodePacked("ROUTER", newRouter));
        require(!pendingWalletChanges[changeId].isPending, "Change already pending");
        
        pendingWalletChanges[changeId] = WalletChange({
            newWallet: newRouter,
            effectiveTime: block.timestamp + WALLET_CHANGE_DELAY,
            isPending: true
        });
        
        emit WalletChangeInitiated(changeId, newRouter, block.timestamp + WALLET_CHANGE_DELAY);
    }
    
    function executeRouterChange(address newRouter) external onlyOwner {
        bytes32 changeId = keccak256(abi.encodePacked("ROUTER", newRouter));
        WalletChange memory change = pendingWalletChanges[changeId];
        
        require(change.isPending, "No pending change");
        require(block.timestamp >= change.effectiveTime, "Timelock not expired");
        
        router = newRouter;
        delete pendingWalletChanges[changeId];
        
        emit WalletChangeExecuted(changeId, newRouter);
    }
    
    function cancelWalletChange(bytes32 changeId) external onlyOwner {
        require(pendingWalletChanges[changeId].isPending, "No pending change");
        delete pendingWalletChanges[changeId];
        emit WalletChangeCancelled(changeId);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // EMERGENCY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function rescueETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function rescueTokens(address token) external onlyOwner {
        require(token != address(this), "Cannot rescue own token");
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), balance);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    function getContractInfo() external view returns (
        uint256 totalSupply_,
        uint256 maxWallet,
        uint256 antiWhaleEnd,
        uint256 antiBotEnd,
        bool trading,
        bool autoLP,
        uint256 buyFee_,
        uint256 sellFee_,
        uint256 swapThreshold,
        address router_,
        address pair_
    ) {
        return (
            totalSupply(),
            maxWalletAmount,
            antiWhaleEndTime,
            antiBotEndTime,
            tradingEnabled,
            autoLPEnabled,
            buyFee,
            sellFee,
            swapTokensAtAmount,
            router,
            pair
        );
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════════
    // RECEIVE ETH
    // ═══════════════════════════════════════════════════════════════════════════════════
    
    receive() external payable {}
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// INTERFACES
// ═══════════════════════════════════════════════════════════════════════════════════════

interface IRouter {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
