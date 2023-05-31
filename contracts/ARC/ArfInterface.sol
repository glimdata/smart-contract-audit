// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface ARFInterface  is IERC721Upgradeable{
    // Epoch details structure
    struct EpochPool {
        uint256 totalQuantityARF;
        uint256 quantityCounterARF;
        uint256 totalQuantityARC;
        uint256 quantityCounterARC;
    }

    // get epoch details from ARF contract
    function epochDetails(uint256 _epoch_id) external returns(EpochPool memory);

    // checks the epoch status.
    function checkEpochStatus(uint256 _epoch_id) external returns(bool);

    // updates the epoch details in ARF contract
    function updateCounter(uint256 epoch_id, uint256 pool_id, uint256 quantity) external;
    
    // factory pools details structure
    struct Pools {
        uint256 poolId;
        uint256 totalQuantityARC;
        uint256 quantityCounterARC;
        uint256 NiozPriceARC;
        uint256 avaxPriceARC;
        uint256 totalQuantityARF;
        uint256 quantityCounterARF;
        uint256 NiozPriceARF;
        uint256 avaxPriceARF;
    }

    // get factory pools details
    function FactoryPools(uint256 _epoch_id, uint256 _pool_id) external returns(Pools memory);

    // checks the signatures
    function isVerified(bytes memory _signature) external view returns(bool);
} 