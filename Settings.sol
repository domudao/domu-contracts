// SPDX-License-Identifier: GPL-2.0-or-later
// contracts/PropertyToken.sol
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Interfaces/ISettings.sol";

contract Settings is ISettings, Pausable, AccessControl {
    bytes32 public constant MANAGEMENT_ROLE = keccak256("MANAGEMENT_ROLE");

    /// @notice the shortest a token lockup period can ever be
    uint256 public constant minLockUpPeriod = 1 days;

    /// @notice the longest a token lockup period can ever be
    uint256 public constant maxLockUpPeriod = 30 days;

    /// @notice the default lockup period after minting
    uint256 public lockUpPeriodAfterMint;

    /// @notice the default lockup period after transfer
    uint256 public lockUpPeriodAfterTransfer;

    /// @notice the address that receives fees
    address payable public feeReceiver;

    /// @notice fee percentage
    uint256 public feePercentage = 2;

    /// @notice 10% is the max percentage
    uint256 public constant maxFeePercentage = 10;

    /// @notice the minimum equity a property can ever represent
    uint256 public constant minMinPropertyEquityPercentage = 10;

    /// @notice the maximum equity a property can ever represent
    uint256 public constant maxPropertyEquityPercentage = 100;
    
    /// @notice the minimum equity percentage
    uint256 public minPropertyEquityPercentage = 10;

    /// @notice the initial supply of equity tokens
    uint256 public constant initialSupply = 100000;

    /// @notice the minimum amount of equity tokens to stay the vault
    uint256 public constant minimumTokensInVault = 10000;

    /// @notice the decimal places for equity tokens
    uint8 public constant equityDecimals = 2;

    /// @notice whether whitelisting is enabled 
    bool public whitelistingEnabled;

    /// @notice the list of whitelisted buyers
    address[] public whitelistedBuyers;

    /// @notice flag as to whether the NFT ownership can be transferred without reclaiming ERC20s
    bool public canTransferWithOutstandingEquity = true;   

    /* Events */

    /** Whitelisting Events */
    
    /**
     * @dev Emitted when a `buyer` is added to the whitelist by `account`.
     */
    event AddBuyerToWhitelist(address account, address buyer);

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event WhitelistingEnabled(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event WhitelistingDisabled(address account);
    
    /**
     * @dev Emitted when the minimum property equity percentage is updated by `account`.
     */
    event UpdateMinPropertyEquityPercentage(address account, uint256 _old, uint256 _new);

    /**
     * @dev Emitted when flag for transferring with outstanding equity is enabled by `account`.
     */
    event TransferWithOutstandingEquityEnabled(address account);
    
    /**
     * @dev Emitted when flag for transferring with outstanding equity is disabled by `account`.
     */
    event TransferWithOutstandingEquityDisabled(address account);
    
    /** Lockup period Events **/

    /**
     * @dev Emitted when the lockup period after minting is updated to `new` from `old` by `account`.
     */
    event UpdateLockupPeriodAfterMint(address account, uint256 _old, uint256 _new);

    /**
     * @dev Emitted when the lockup period after transfer is updated to `new` from `old` by `account`.
     */
    event UpdateLockupPeriodAfterTransfer(address account, uint256 _old, uint256 _new);

    /** Fee Events **/

    /**
     * @dev Emitted when the fee receiver address is updated to `new` from `old` by `account`.
     */
    event UpdateFeeReceiver(address account, address _old, address _new);

    /**
     * @dev Emitted when the fee receiver percentage is updated to `new` from `old` by `account`.
     */
    event UpdateFeePercentage(address account, uint256 _old, uint256 _new);

    constructor() {
        lockUpPeriodAfterMint = 10 days;
        lockUpPeriodAfterTransfer = 10 days;
        feeReceiver = payable(msg.sender);
        whitelistingEnabled = false;
        whitelistedBuyers.push(msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGEMENT_ROLE, msg.sender);
    }

    function getWhitelistedBuyers() external view returns(address[] memory) {
        return whitelistedBuyers;
    }
        
    function getMinimumTokensInVault() external view returns(uint256) {
        return minimumTokensInVault;
    }

    function setLockUpPeriodAfterMint(uint256 _length) external  {
        require(_length >= minLockUpPeriod, "lockup period too low");
        require(_length <= maxLockUpPeriod, "lockup period too long");

        emit UpdateLockupPeriodAfterMint(_msgSender(), lockUpPeriodAfterMint, _length);

        lockUpPeriodAfterMint = _length;
    }

    function setLockUpPeriodAfterTransfer(uint256 _length) external onlyRole(MANAGEMENT_ROLE) {
        require(_length >= minLockUpPeriod, "lockup period too low");
        require(_length <= maxLockUpPeriod, "lockup period too long");

        emit UpdateLockupPeriodAfterTransfer(_msgSender(), lockUpPeriodAfterTransfer, _length);

        lockUpPeriodAfterTransfer = _length;
    }

    /* Fees */
    function setFeePercentage(uint256 _fee) external onlyRole(MANAGEMENT_ROLE) returns (uint256) {
        require(_fee <= maxFeePercentage, "percentage too high");

        emit UpdateFeePercentage(_msgSender(), maxFeePercentage, _fee);

        feePercentage = _fee;
        
        return feePercentage;
    }

    function setFeeReceiver(address payable _receiver) external onlyRole(MANAGEMENT_ROLE) returns (address payable) {
        require(_receiver != address(0), "fees cannot go to 0 address");

        emit UpdateFeeReceiver(_msgSender(), feeReceiver, _receiver);

        feeReceiver = _receiver;

        return feeReceiver;
    }
    
    /* Whitelisting */
    function isWhitelistingEnabled() external view returns (bool) {
        return whitelistingEnabled;
    }
    
    function enableWhitelisting() external onlyRole(MANAGEMENT_ROLE){
        emit WhitelistingEnabled(_msgSender());
        whitelistingEnabled = true;
    }

    function disableWhitelisting() external onlyRole(MANAGEMENT_ROLE) {
        whitelistingEnabled = false;
    }

    function isBuyerWhitelisted(address buyer) external view returns (bool){
        for (uint i; i< whitelistedBuyers.length;i++){
            if (whitelistedBuyers[i] == buyer)
            return true;
        }
        return false;
    }

    function addBuyerToWhitelist(address buyer) external onlyRole(MANAGEMENT_ROLE) {
        if (!this.isBuyerWhitelisted(buyer)) {
            emit AddBuyerToWhitelist(_msgSender(), buyer);
            whitelistedBuyers.push(buyer);
        }
    }

    function enableTransferWithOutstandingEquity() external onlyRole(MANAGEMENT_ROLE)  {
        emit TransferWithOutstandingEquityEnabled(_msgSender());
        canTransferWithOutstandingEquity = true;
    }

    function disableTransferWithOutstandingEquity() external onlyRole(MANAGEMENT_ROLE) {
        emit TransferWithOutstandingEquityDisabled(_msgSender());
        canTransferWithOutstandingEquity = false;
    }

    function pause() external onlyRole(MANAGEMENT_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MANAGEMENT_ROLE) {
        _unpause();
    }

    function hasAdminRole() external view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function hasManagementRole() external view returns(bool) {
        return hasRole(MANAGEMENT_ROLE, _msgSender());
    }
}