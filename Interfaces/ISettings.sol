//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISettings {

    // Fixed values
    function initialSupply() external view returns(uint256);
    
    function equityDecimals() external view returns(uint8);

    // Whitelisting
    function getWhitelistedBuyers() external view returns(address[] memory);

    function addBuyerToWhitelist(address buyer) external;

    function isBuyerWhitelisted(address buyer) external view returns(bool);

    function isWhitelistingEnabled() external view returns (bool);
    
    function enableWhitelisting() external;

    function disableWhitelisting() external;

    // Transfer rules
    function canTransferWithOutstandingEquity() external view returns(bool);
    
    function enableCanTransferWithOutstandingEquity() external;

    function disableCanTransferWithOutstandingEquity() external;

    function lockUpPeriodAfterMint() external view returns(uint256);

    function maxFeePercentage() external view returns(uint256);

    function getMinimumTokensInVault() external view returns(uint256);
 
    // Fee rules
    function feePercentage() external view returns(uint256);

    function setFeePercentage(uint256 feePercentage) external returns(uint256);

    function feeReceiver() external view returns(address payable);
    
    function setFeeReceiver(address payable feeReceiver) external returns(address payable);
}