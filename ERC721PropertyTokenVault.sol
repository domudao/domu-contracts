// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "./Interfaces/ISettings.sol";

contract ERC721PropertyTokenVault is Initializable, ERC20Upgradeable, AccessControlUpgradeable, ERC721HolderUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// -----------------------------------
    /// -------- TOKEN INFORMATION --------
    /// -----------------------------------

    /// @notice the ERC721 token address of the vault's token
    address public token;

    /// @notice the ERC721 token ID of the vault's token
    uint256 public id;

    /// @notice the wallet address of the property/ERC721 owner
    address public propertyOwner;

    /// @notice the governance contract which gets paid in ETH
    address public immutable settings;

    /// @notice An event emitted when someone redeems all tokens for the NFT
    event Redeem();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _settings) initializer {
        settings = _settings;
    }

    function initialize(address _to, address _admin, address _token, uint256 _supply, uint256 _id) initializer public {
        __ERC20_init("PropertyTokenVault", "PTV");
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MINTER_ROLE, _to); // Grant the Property Owner the MINTER role

        token = _token;
        id = _id;
        propertyOwner = _to;

        _mint(address(this), _supply);
    }

    function updatePropertyOwner(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // Ensure that the tokens are all owned by the Property Owner or the Vault to transfer ownership
        uint256 totalOwnerBalance = balanceOf(propertyOwner) + balanceOf(address(this));
        if (totalOwnerBalance < (totalSupply())) {
            require(ISettings(settings).canTransferWithOutstandingEquity(), "Ownership can only be transferred if current property owner owns all equity tokens");
        }
        _revokeRole(MINTER_ROLE, propertyOwner);
        _grantRole(MINTER_ROLE, newOwner);
        propertyOwner = newOwner;
    }

    function withdraw(uint256 amount) public onlyRole(MINTER_ROLE) {
        _transfer(address(this), msg.sender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        require (!Pausable(settings).paused(), "Pausable: paused");
        
        // If whitelisting is enabled, require that the `to` address is whitelisted
        if (ISettings(settings).isWhitelistingEnabled()) {
            require(ISettings(settings).isBuyerWhitelisted(to), "Token receipient must be whitelisted");
        }

        // TODO - check if fees are enabled and if so, deduct the fee

        // If withdrawing from the vault, require that the minimum tokens remain in the vault.
        if (from == address(this)) {
            require((balanceOf(from) - amount) >= ISettings(settings).getMinimumTokensInVault(), "Cannot withdraw more than the maximum");
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return ISettings(settings).equityDecimals();
    }

    /// @notice an external function to burn all ERC20 tokens to receive the ERC721 token
    function redeem(address tokenOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require (!Pausable(settings).paused(), "Pausable: paused");

        _burn(tokenOwner, totalSupply());

        // transfer erc721 to redeemer
        IERC721(token).transferFrom(address(this), tokenOwner, id);
        
        emit Redeem();
    }

    // Admin function for transferring the ERC20s from one account to another - required for repossession and fraud purposes
    function adminTransferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        _transfer(from, to, amount);
        return true;
    }
}