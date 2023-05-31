// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Joepegs is
    ERC721Upgradeable,
    OwnableUpgradeable
{
    // Token counter
    uint256 public tokenCounter;

    // Initialization
    function initialize() public initializer {
        __ERC721_init("Joepegs", "JOEPEGS");
        __Ownable_init();
    }

    /**
     * @dev mints the Joepeg tokens for testing..
     *
     */
    function mint()
        external
        virtual
        returns (uint256)
    {
        tokenCounter += 1;
        _mint(msg.sender, tokenCounter);
        return tokenCounter;
    }


}
