// SPDX-License-Identifier: GPL-2.0-or-later
// contracts/PropertyToken.sol
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "./Settings.sol";
import "./InitializedProxy.sol";
import "./ERC721PropertyToken.sol";
import "./ERC721PropertyTokenVault.sol";

contract ERC721VaultFactory is Ownable {
  /// @notice the number of PropertyVaults
  uint256 public propertyVaultCount;

  /// @notice the mapping of PropertyVault number to PropertyVault contract
  mapping(uint256 => address) public propertyVaults;

  /// @notice a settings contract controlled by governance
  address public immutable settings;

  /// @notice the TokenVault logic contract
  address public immutable vaultLogic;

  /// @notice the Token logic contract
  address public immutable tokenLogic;

  event Mint(address indexed vault, uint256 id);

  constructor(address _settings, address _tokenLogic) {
    settings = _settings;
    tokenLogic = _tokenLogic;
    vaultLogic = address(new ERC721PropertyTokenVault(_settings));
  }
  
  // @notice the function to mint a new token
  // @param _to the address to mint tokens to
  // @param _id the uint256 ID of the token
  // @return the ID of the token
  function mint(address _to, uint256 _id) external onlyOwner returns(uint256) {    
    require (!Pausable(settings).paused(), "Pausable: paused");

    bytes memory _initializationCalldata =
      abi.encodeWithSignature(
        "initialize(address,address,address,uint256,uint256)",
          _to,
          msg.sender,
          tokenLogic,
          ISettings(settings).initialSupply(),
          _id
    );

    address vault = address(
      new InitializedProxy(
        vaultLogic,
        _initializationCalldata
      )
    );

    ERC721PropertyToken(tokenLogic).safeMint(vault, _id, Strings.toString(_id));

    emit Mint(vault, _id);

    propertyVaults[propertyVaultCount] = vault;
    propertyVaultCount++;

    return propertyVaultCount - 1;
  }
}