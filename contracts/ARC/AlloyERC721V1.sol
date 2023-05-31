// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ArfInterface.sol";

contract AlloyERC721V1 is
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

    // minting printer order tuple
    struct Order_Printer {
        uint256 epoch_id;
        uint256 pool_id;
        uint256 quantity;
        bytes32 message_hash;
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
     * @dev Emitted when user mints the parts.
     */
    event PartMinted(
        address User,
        uint256 TokenId,
        uint256 PartId,
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
        string NFTtype
    );

    /**
     * @dev Emitted when user assembles part by using assembler.
     */
    event AssembleParts(
        address User,
        uint256[] PartIds,
        uint256[] PartTokenids,
        uint256 UpgradeId,
        uint256 UpgradeTokenId,
        string ConstructType
    );

    /**
     * @dev Emitted when user mints the upgrade.
     */
    event UpgradeMinted(
        address User,
        uint256 UpgradeId,
        uint256 UpgradeTokenId,
        string NFTtype
    );

    /**
     * @dev Emitted when user mints the construct.
     */
    event ConstructMinted(
        address User,
        uint256 ConstructId,
        uint256 ConstructTokenId,
        string NFTtype
    );

    /**
     * @dev Emitted when user process part with thread upgrade.
     */
    event ProcessedWithThread(
        address User,
        uint256 ThreadId,
        uint256 ThreadTokenId,
        uint256 PartId,
        uint256 PartTokenId,
        string NFTtype
    );

    /**
     * @dev Emitted when user process part without thread upgrade.
     */
    event ProcessedWithOutThread(
        address User,
        uint256 PartId,
        uint256 PartTokenId,
        string NFTtype
    );

    /**
     * @dev Emitted when user recycle the broken part.
     */
    event RecycledPart(
        address User,
        uint256 PartTokenId,
        uint256 PartId,
        uint256 PrinterId,
        uint256 PrinterTokenId,
        string NFTtype
    );

    /**
     * @dev Emitted when user sells the consumables.
     */
    event SoldConsumable(
        address User,
        uint256 Amount,
        uint256 ConsumableId,
        string NFTtype
    );

    /**
     * @dev Emitted when user sells the construct.
     */
    event SoldConstruct(
        address User,
        uint256 Amount,
        uint256 ConstructId,
        string NFTtype
    );

    /**
     * @dev Emitted when part are processed.
     */
    event PartProcessed(
        address User,
        uint256 PartTokenId,
        uint256 PartId,
        uint256 ThreadUpgradeId,
        uint256 ThreadUpgradeTokenId,
        string NFTtype
    );

    /**
     * @dev Emitted when user upgrades the printer and burns the upgrade token.
     */
    event equipUpgraded(
        address User,
        uint256 PrinterId,
        uint256 PrinterTokenId,
        uint256 UpgradeId,
        uint256 UpgradeTokenId
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
    function mintARC(address _owner)
        external
        virtual
        onlyMaster
        returns (uint256)
    {
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
    function upadateDefaultUri(string memory _baseuri, string memory _extension)
        external
        virtual
        onlyOwner
    {
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
        uint256 _num_allowed,
        uint256 _fee_percent
    ) external virtual onlyOwner {
        MerchantWallet = _merchant_address;
        NiozERC20Address = IERC20Upgradeable(_Nioz_address);
        ARFtokenAddress = ARFInterface(_Arf_address);
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
            ARFtokenAddress.FactoryPools(_order.epoch_id, _order.pool_id).NiozPriceARC,
            "PRINTER"
        );
    }

    /**
     * @dev User mints the part.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Requirements:
     * - msg.sender must have own printer for creating parts.
     *
     * Emits a {PartMinted} event.
     */
    function mintPart(PartOrder memory _order, bytes memory _signature)
        external
        virtual
    {
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

        tokenCounter += 1;
        NFTtypes[tokenCounter] = "PART";

        _safeMint(msg.sender, tokenCounter);
        isVerified[_signature] = true;

        emit PartMinted(msg.sender, tokenCounter, _order.partId, "PART");
    }

    /**
     * @dev User assembles the parts with the help of assembler.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Requirements:
     * - msg.sender must have own part token ids for assembling.
     *
     * Emits a {AssembleParts} event.
     */
    function assembleParts(
        AssembleStruct memory _order,
        bytes memory _signature
    ) external virtual {
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

        for (uint256 i = 0; i < _order.partTokenIds.length; i++) {
            require(
                ownerOf(_order.partTokenIds[i]) == msg.sender,
                "AlloyERC721: Not a part owner"
            );
            require(
                bytes(NFTtypes[_order.partTokenIds[i]]).length ==
                    bytes("PART").length,
                "AlloyERC721: Not a part"
            );
            _burn(_order.partTokenIds[i]);
            NFTtypes[_order.partTokenIds[i]] = "";
            isVerified[_signature] = true;
        }

        require(
            bytes(NFTtypes[_order.assembleUpgradeTokenId]).length ==
                bytes("UPGRADE-ASSEMBLER").length,
            "AlloyERC721: Not a assembler"
        );
        require(
            ownerOf(_order.assembleUpgradeTokenId) == msg.sender,
            "AlloyERC721: Not a assembler owner"
        );
        _burn(_order.assembleUpgradeTokenId);
        NFTtypes[_order.assembleUpgradeTokenId] = "";

        emit AssembleParts(
            msg.sender,
            _order.partIds,
            _order.partTokenIds,
            _order.assembleUpgradeId,
            _order.assembleUpgradeTokenId,
            _order.constructType
        );
    }

    /**
     * @dev User process the part.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Requirements:
     * - msg.sender must have own part token id.
     *
     * Emits a {ProcessedWithThread} event if processed with thread upgrade.
     * Emits a {ProcessedWithOutThread} event if processed without thread upgrade.
     */

    function processPart(ProcessOrder memory _order, bytes memory _signature)
        external
        virtual
    {
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

        tokenCounter += 1;
        _safeMint(msg.sender, tokenCounter);
        NFTtypes[tokenCounter] = "PART";
        isVerified[_signature] = true;

        if (_order.isThread) {
            require(
                ownerOf(_order.threadUpgradeTokenId) == msg.sender,
                "AlloyERC721: Not a owner"
            );
            _burn(_order.threadUpgradeTokenId);

            emit ProcessedWithThread(
                msg.sender,
                _order.threadUpgradeId,
                _order.threadUpgradeTokenId,
                _order.partId,
                tokenCounter,
                "PART"
            );
        } else {
            emit ProcessedWithOutThread(
                msg.sender,
                _order.partId,
                tokenCounter,
                "PART"
            );
        }
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
    function sellProcessedPart(Order memory _order, bytes memory _signature)
        external
        virtual
    {
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
        require(
            bytes(NFTtypes[_order.partTokenId]).length == bytes("PART").length,
            "AlloyERC721: Not a part"
        );
        require(
            ownerOf(_order.partTokenId) == msg.sender,
            "AlloyERC721: Not a owner"
        );

        NFTtypes[_order.partTokenId] = "";
        _burn(_order.partTokenId);
        isVerified[_signature] = true;

        if (_order.isSendToWallet) {
            NiozERC20Address.mint(msg.sender, _order.amount);
        }

        if (!_order.isSendToWallet) {
            require(
                bytes(NFTtypes[_order.printerTokenId]).length ==
                    bytes("PRINTER").length,
                "AlloyERC721: Not a printer"
            );

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
            "PART"
        );
    }

    /**
     * @dev User recycles the broken part in printer.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Requirements:
     * - msg.sender must have own part token id.
     *
     * Emits a {RecycledPart} event.
     */
    function recycleBrokenPart(Order memory _order, bytes memory _signature)
        external
        virtual
    {
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
        require(
            bytes(NFTtypes[_order.partTokenId]).length == bytes("PART").length,
            "AlloyERC721: Not a part"
        );
        require(
            ownerOf(_order.partTokenId) == msg.sender,
            "AlloyERC721: Not a owner"
        );

        NFTtypes[_order.partTokenId] = "";
        _burn(_order.partTokenId);
        isVerified[_signature] = true;

        if (_order.isSendToWallet) {
            NiozERC20Address.mint(msg.sender, _order.amount);
        }

        if (!_order.isSendToWallet) {
            require(
                bytes(NFTtypes[_order.printerTokenId]).length ==
                    bytes("PRINTER").length,
                "AlloyERC721: Not a printer"
            );

            require(
                ownerOf(_order.printerTokenId) == msg.sender,
                "AlloyERC721: Not a owner"
            );
        }

        emit RecycledPart(
            msg.sender,
            _order.partTokenId,
            _order.partId,
            _order.printerId,
            _order.printerTokenId,
            "PART"
        );
    }

    /**
     * @dev User mints the upgrade.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Emits a {UpgradeMinted} event.
     */
    function mintUpgrade(UpgradeOrder memory _order, bytes memory _signature)
        external
        virtual
    {
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

        tokenCounter += 1;
        NFTtypes[tokenCounter] = _order.upgradeType;
        isVerified[_signature] = true;

        _safeMint(msg.sender, tokenCounter);

        emit UpgradeMinted(
            msg.sender,
            _order.upgradeId,
            tokenCounter,
            _order.upgradeType
        );
    }

    /**
     * @dev User mints the construct.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Emits a {ConstructMinted} event.
     */
    function mintConstruct(
        ConstructOrder memory _order,
        bytes memory _signature
    ) external virtual {
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

        tokenCounter += 1;
        NFTtypes[tokenCounter] = "CONSTRUCT";

        _safeMint(msg.sender, tokenCounter);
        isVerified[_signature] = true;

        emit ConstructMinted(
            msg.sender,
            _order.constructId,
            tokenCounter,
            "CONSTRUCT"
        );
    }

    /**
     * @dev User sells consumble and gets the NIOZ tokens.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Emits a {SoldConsumable} event.
     */
    function sellConsumable(SellOrder memory _order, bytes memory _signature)
        external
        virtual
    {
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

        NiozERC20Address.mint(msg.sender, _order.amount);
        isVerified[_signature] = true;

        emit SoldConsumable(msg.sender, _order.amount, _order.Id, "CONSUMABLE");
    }

    /**
     * @dev User sells Construct and gets the NIOZ tokens.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Emits a {SoldConstruct} event.
     */
    function sellAlloyConstruct(
        SellOrder memory _order,
        bytes memory _signature
    ) external virtual {
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
        NiozERC20Address.mint(msg.sender, _order.amount);
        isVerified[_signature] = true;

        emit SoldConstruct(msg.sender, _order.amount, _order.Id, "CONSTRUCT");
    }

    /**
     * @dev process the part by burning upgrade tokens.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Requirements:
     * - msg.sender must have own upgrade token id.
     *
     * Emits a {PartProcessed} event.
     */
    function processPartInventory(
        OrderUpgrade memory _order,
        bytes memory _signature
    ) external virtual {
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

        require(
            ownerOf(_order.pTokenId) == msg.sender,
            "AlloyERC721: Not a owner"
        );
        require(
            ownerOf(_order.uTokenId) == msg.sender,
            "AlloyERC721: Not a owner"
        );
        require(
            bytes(NFTtypes[_order.pTokenId]).length == bytes("PART").length,
            "AlloyERC721: Not a part"
        );
        _burn(_order.uTokenId);
        isVerified[_signature] = true;

        emit PartProcessed(
            msg.sender,
            _order.pTokenId,
            _order.pId,
            _order.uId,
            _order.uTokenId,
            "PART"
        );
    }

    /**
     * @dev upgrade the printer by upgrade token id.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Requirements:
     * - msg.sender must have own upgrade token and printer token.
     *
     * Emits a {equipUpgraded} event.
     */
    function equipUpgrade(OrderUpgrade memory _order, bytes memory _signature)
        external
        virtual
    {
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

        require(
            ownerOf(_order.pTokenId) == msg.sender,
            "AlloyERC721: Not a owner"
        );
        require(
            ownerOf(_order.uTokenId) == msg.sender,
            "AlloyERC721: Not a owner"
        );
        require(
            bytes(NFTtypes[_order.pTokenId]).length == bytes("PRINTER").length,
            "AlloyERC721: Not a printer"
        );
        _burn(_order.uTokenId);
        isVerified[_signature] = true;

        emit equipUpgraded(
            msg.sender,
            _order.pId,
            _order.pTokenId,
            _order.uId,
            _order.uTokenId
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
    function buy(SellOrder memory _order, bytes memory _signature)
        external
        payable
        virtual
        nonReentrant
    {
        address previousOwner = ownerOf(_order.Id);
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                previousOwner,
                _order.messageHash,
                _signature
            ),
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
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
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
    function feeCalculation(uint256 _total_amount)
        internal
        view
        returns (uint256 Fee)
    {
        Fee = (commissionFee * _total_amount) / 1000;
    }
}
