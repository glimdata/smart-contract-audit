// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ArfInterface.sol";

contract AlloyERC721V2 is
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    // Token counter
    uint256 public tokenCounter;

    // royalties accepter address
    address public MerchantWallet;

    // NFT types
    mapping(uint256 => string) public NFTtypes;

    // bytes verification
    mapping(bytes => bool) public isVerified;

    // part order tuple
    struct PartOrder {
        uint256 partId;
        bytes32 messageHash;
    }

    // upgrade order tuple
    struct UpgradeOrder {
        uint256 upgradeId;
        string upgradeType;
        bytes32 messageHash;
    }

    // tokenURI's
    string baseUri;
    string baseExtension;

    // allowed printers number in one transaction
    uint256 public allowedPrinters;

    // NIOZ ERC20 contract address
    IERC20Upgradeable public NiozERC20Address;

    // order tuple
    struct Order {
        uint256 amount;
        uint256 partTokenId;
        uint256 partId;
        bool isSendToWallet;
        uint256 printerId;
        uint256 printerTokenId;
        bytes32 messageHash;
    }

    // constructor order tuple
    struct ConstructOrder {
        uint256 constructId;
        bytes32 messageHash;
    }

    // process token order tuple
    struct ProcessOrder {
        uint256 partId;
        bool isThread;
        uint256 threadUpgradeTokenId;
        uint256 threadUpgradeId;
        bytes32 messageHash;
    }

    // assembling token order tuple
    struct AssembleStruct {
        uint256[] partTokenIds;
        uint256[] partIds;
        uint256 assembleUpgradeId;
        uint256 assembleUpgradeTokenId;
        string constructType;
        bytes32 messageHash;
    }

    // marketplace order tuple
    struct SellOrder {
        uint256 Id;
        uint256 amount;
        bytes32 messageHash;
    }

    // upgrade order tuple
    struct OrderUpgrade {
        uint256 pId;
        uint256 pTokenId;
        uint256 uId;
        uint256 uTokenId;
        bytes32 messageHash;
    }

    // roylaties fees
    uint256 public commissionFee;

    // ARF ERC721 contract address
    ARFInterface public ARFtokenAddress;

    // construct sold to econine status
    mapping(uint256 => bool) public isConstructSold;

    // consumable sold to econine status
    mapping(uint256 => bool) public isConsumableSold;

    // minting printer order tuple
    struct Order_Printer {
        uint256 epoch_id;
        uint256 pool_id;
        uint256 quantity;
        bytes32 message_hash;
    }

    // construct sold to econine status
    mapping(uint256 => bool) public isConstructMintable;

    // consumable sold to econine status
    mapping(uint256 => bool) public isConsumableMintable;

    // part mintable status
    mapping(uint256 => bool) public isPartMintable;

    // upgrade mintable status
    mapping(uint256 => bool) public isUpgradeMintable;

    // processed part mintable status
    mapping(uint256 => bool) public isProcessedPartMintable;

    // // construct part mapping
    // mapping(uint256 => address) public isConstructMintableWhitelist;

    // marketplace order tuple
    struct SellOrderOffChain {
        uint256 Id;
        address previousOwner;
        uint256 amount;
        bytes32 messageHash;
    }

    // Construct contract address
    ARFInterface public ConstructAddress;

    // marketplace order tuple
    struct SellOrderOffChain1 {
        uint256 Id;
        address previousOwner;
        uint256 amount;
        string NFTtype;
        bytes32 messageHash;
    }

    // Events
    /**
     * @dev Emitted when user mints the printer.
     */
    event PrinterMinted(
        address User,
        uint256[] TokenIds,
        uint256 EpochId,
        uint256 PoolId,
        uint256 AvaxPrice,
        uint256 NiozPrice,
        string NFTtype
    );

    /**
     * @dev Emitted when user sells processed part to factory.
     */
    event PartBurned(
        address User,
        uint256 PartTokenId,
        uint256 PartId,
        uint256 PrinterId,
        uint256 PrinterTokenId,
        uint256 NiozAmount,
        string NFTtype
    );

    /**
     * @dev Emitted when user buys listed nft from marketplace.
     */
    event TokenPurchased(
        address PreviousOwner,
        address NewOwner,
        uint256 Price,
        uint256 TokenId,
        string TokenType
    );

    /**
     * @dev Emitted when user buys listed nft from marketplace.
     */
    event TokenPurchasedOffChain(
        address PreviousOwner,
        address NewOwner,
        uint256 Price,
        uint256 TokenId,
        string NFTtype
    );

    /**
     * @dev Emitted when user buys listed nft from marketplace.
     */
    event TokenBurned(
        address PreviousOwner,
        uint256[] TokenIds,
        address BurnedBy,
        string NFTtype
    );

    // Initialization
    function initialize() public initializer {
        __ERC721_init("Alloy Space S1", "ARC");
        __Ownable_init();
        __ReentrancyGuard_init();

        baseUri = "https://assets.alloy.space/token-uri-s1/";
        baseExtension = "-token-uri.json";

        tokenCounter = 0;
        allowedPrinters = 3;

        NiozERC20Address = IERC20Upgradeable(
            0x7c0AA72dbd7058D0Aee8bF99391B827A3AF04878
        );
        MerchantWallet = 0x25fC99eF8C2bE73c303f7e54A0c2Da423E48326b;

        commissionFee = 60;
    }

    /**
     * @dev Only allowed address can perform specific task.
     */
    modifier onlyMaster() {
        require(
            msg.sender == address(ARFtokenAddress),
            "AlloyERC721: Only Master can call"
        );
        _;
    }

    /**
     * @dev mints the ARC according ARF epoch.
     *
     * @param _owner mints to owner address.
     *
     * Requirements:
     * - msg.sender must be called by ARF contract.
     *
     */
    function mintARC(
        address _owner
    ) external virtual onlyMaster returns (uint256) {
        tokenCounter += 1;
        _mint(_owner, tokenCounter);
        return tokenCounter;
    }

    /**
     * @dev updated token URI
     *
     * @param _baseuri base URI
     * @param _extension extension URI
     *
     * Requirements:
     * - msg.sender must be owner address of this contract.
     *
     */
    function upadateDefaultUri(
        string memory _baseuri,
        string memory _extension
    ) external virtual onlyOwner {
        baseUri = _baseuri;
        baseExtension = _extension;
    }

    /**
     * @dev updated contract values
     *
     * @param _merchant_address merchant wallet address
     * @param _Nioz_address Nioz token address
     * @param _Arf_address ARF token address
     * @param _num_allowed allowed printers to be mint in one transaction
     * @param _fee_percent commission fee percentage
     *
     * Requirements:
     * - msg.sender must be owner address of this contract.
     *
     */

    function updateMerchantWalletAndNiozAddress(
        address _merchant_address,
        address _Nioz_address,
        address _Arf_address,
        address _construct_address,
        uint256 _num_allowed,
        uint256 _fee_percent
    ) external virtual onlyOwner {
        MerchantWallet = _merchant_address;
        NiozERC20Address = IERC20Upgradeable(_Nioz_address);
        ARFtokenAddress = ARFInterface(_Arf_address);
        ConstructAddress = ARFInterface(_construct_address);
        allowedPrinters = _num_allowed;
        commissionFee = _fee_percent;
    }

    /**
     * @dev User mints the printer w.r.t to Avax
     *
     * @param _order order tuple
     * @param _signature signature
     *
     * Requirements:
     * - msg.sender must have AVAX balance in wallet
     *
     * Emits a {PrinterMinted} event.
     */
    function mintPrinterARC(
        Order_Printer calldata _order,
        bytes memory _signature
    ) external payable virtual nonReentrant {
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                owner(),
                _order.message_hash,
                _signature
            ) &&
                !isVerified[_signature] &&
                !(NiozERC20Address.isVerified(_signature)) &&
                !(ARFtokenAddress.isVerified(_signature)),
            "AlloyERC721: Not allowed"
        );
        require(
            ARFtokenAddress.checkEpochStatus(_order.epoch_id) &&
                ARFtokenAddress
                    .epochDetails(_order.epoch_id)
                    .totalQuantityARC >=
                (ARFtokenAddress
                    .epochDetails(_order.epoch_id)
                    .quantityCounterARC + _order.quantity) &&
                (_order.epoch_id == 6 ||
                    _order.epoch_id == 7 ||
                    _order.epoch_id == 8) &&
                ARFtokenAddress
                    .FactoryPools(_order.epoch_id, _order.pool_id)
                    .totalQuantityARC >=
                ARFtokenAddress
                    .FactoryPools(_order.epoch_id, _order.pool_id)
                    .quantityCounterARC +
                    _order.quantity,
            "AlloyERC721: This epoch is closed or printer is out of stock"
        );
        require(
            ARFtokenAddress
                .FactoryPools(_order.epoch_id, _order.pool_id)
                .avaxPriceARC *
                _order.quantity ==
                msg.value,
            "AlloyERC721: Invalid price"
        );

        uint256[] memory temp;
        require(
            _order.quantity <= allowedPrinters,
            "AlloyERC721: Invalid quantity"
        );
        temp = new uint256[](_order.quantity);

        for (uint256 i = 0; i < _order.quantity; i++) {
            tokenCounter += 1;
            NFTtypes[tokenCounter] = "PRINTER";

            _safeMint(msg.sender, tokenCounter);
            temp[i] = tokenCounter;
        }

        payable(MerchantWallet).transfer(msg.value);
        if (
            ARFtokenAddress
                .FactoryPools(_order.epoch_id, _order.pool_id)
                .NiozPriceARC > 0
        ) {
            NiozERC20Address.safeTransfer(
                msg.sender,
                address(this),
                ARFtokenAddress
                    .FactoryPools(_order.epoch_id, _order.pool_id)
                    .NiozPriceARC
            );
            NiozERC20Address.approve(
                MerchantWallet,
                ARFtokenAddress
                    .FactoryPools(_order.epoch_id, _order.pool_id)
                    .NiozPriceARC
            );
            NiozERC20Address.safeTransfer(
                address(this),
                MerchantWallet,
                ARFtokenAddress
                    .FactoryPools(_order.epoch_id, _order.pool_id)
                    .NiozPriceARC
            );
        }

        ARFtokenAddress.updateCounter(
            _order.epoch_id,
            _order.pool_id,
            _order.quantity
        );

        emit PrinterMinted(
            msg.sender,
            temp,
            _order.epoch_id,
            _order.pool_id,
            msg.value,
            ARFtokenAddress
                .FactoryPools(_order.epoch_id, _order.pool_id)
                .NiozPriceARC,
            "PRINTER"
        );
    }

    /**
     * @dev User sells processed part to factory.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Requirements:
     * - msg.sender must have own part token id.
     *
     * Emits a {PartBurned} event.
     */
    function sellProcessedPart(
        Order memory _order,
        bytes memory _signature
    ) external virtual nonReentrant {
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                owner(),
                _order.messageHash,
                _signature
            ) &&
                !isVerified[_signature] &&
                !(NiozERC20Address.isVerified(_signature)) &&
                !(ARFtokenAddress.isVerified(_signature)),
            "AlloyERC721: Not allowed"
        );
        isVerified[_signature] = true;

        if (_order.isSendToWallet) {
            NiozERC20Address.mint(msg.sender, _order.amount);
        }

        if (!_order.isSendToWallet) {
            require(
                ownerOf(_order.printerTokenId) == msg.sender,
                "AlloyERC721: Not a owner"
            );
        }

        emit PartBurned(
            msg.sender,
            _order.partTokenId,
            _order.partId,
            _order.printerId,
            _order.printerTokenId,
            _order.amount,
            "PART"
        );
    }

    /**
     * @dev user buys the tokens from marketplaces.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Emits a {TokenPurchased} event.
     */
    function buy(
        SellOrder memory _order,
        bytes memory _signature
    ) external payable virtual nonReentrant {
        address previousOwner = ownerOf(_order.Id);
        require(
            NiozERC20Address.recoverSigner(_order.messageHash, _signature) ==
                previousOwner,
            "AlloyERC721: Not listed"
        );
        require(
            _order.amount == msg.value &&
                !isVerified[_signature] &&
                !(NiozERC20Address.isVerified(_signature)) &&
                !(ARFtokenAddress.isVerified(_signature)),
            "AlloyERC721: Prize is incorrect or invalid"
        );

        _safeTransfer(previousOwner, msg.sender, _order.Id, "");
        isVerified[_signature] = true;

        // transfer fee
        uint256 fee = feeCalculation(msg.value);
        payable(MerchantWallet).transfer(fee);
        payable(previousOwner).transfer(msg.value - fee);

        emit TokenPurchased(
            previousOwner,
            msg.sender,
            msg.value,
            _order.Id,
            NFTtypes[_order.Id]
        );
    }

    /**
     * @dev user buys the tokens from marketplaces.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Emits a {TokenPurchasedOffChain} event.
     */
    function buyOffChain(
        SellOrderOffChain1 memory _order,
        bytes memory _signature
    ) external payable virtual nonReentrant {
        require(
            NiozERC20Address.recoverSigner(_order.messageHash, _signature) ==
                _order.previousOwner,
            "AlloyERC721: Not listed"
        );
        require(
            _order.amount == msg.value &&
                !isVerified[_signature] &&
                !(NiozERC20Address.isVerified(_signature)) &&
                !(ARFtokenAddress.isVerified(_signature)),
            "AlloyERC721: Prize is incorrect or invalid"
        );

        isVerified[_signature] = true;

        // transfer fee
        uint256 fee = feeCalculation(msg.value);
        payable(MerchantWallet).transfer(fee);
        payable(_order.previousOwner).transfer(msg.value - fee);

        emit TokenPurchasedOffChain(
            _order.previousOwner,
            msg.sender,
            msg.value,
            _order.Id,
            _order.NFTtype
        );
    }

    /**
     * @dev only owner can burn the token ids
     *
     * @param _tokenIds array of Ids
     *
     * Requirements:
     * - msg.sender must have contract owner or tokenOwner or construct token address.
     */
    function burnTokens(uint256[] calldata _tokenIds, string memory _nft_type) external virtual {
        emit TokenBurned(ownerOf(_tokenIds[0]), _tokenIds, msg.sender, _nft_type);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                msg.sender == ownerOf(_tokenIds[i]) ||
                    msg.sender == owner() ||
                    msg.sender == address(ConstructAddress),
                "AlloyERC721: Invalid owner"
            );
            _burn(_tokenIds[i]);
        }
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "AlloyERC721: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    baseUri,
                    StringsUpgradeable.toString(_tokenId),
                    baseExtension
                )
            );
    }

    /**
     * @dev Returns calculated tax fee.
     */
    function feeCalculation(
        uint256 _total_amount
    ) internal view returns (uint256 Fee) {
        Fee = (commissionFee * _total_amount) / 1000;
    }
}
