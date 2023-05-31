// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./MintpegInterface.sol";

contract ArfERC721V2 is ERC721Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;

    // token counter
    uint256 public tokenCounter;

    // token URI
    string baseUri;
    string baseExtension;

    // epoch pool structure
    struct EpochPool {
        uint256 totalQuantityARF;
        uint256 quantityCounterARF;
        uint256 totalQuantityARC;
        uint256 quantityCounterARC;
    }

    // mapping of epoch Id w.r.t its data
    mapping(uint256 => EpochPool) public epochDetails;

    // mapping epoch id status
    mapping(uint256 => bool) public checkEpochStatus;

    // Joepegs token contract address
    Mintpeg public JoepegsTokenAddress;

    // ARC token contract address
    Mintpeg public ARCAddress;

    // whitelisting for whitelist epoch
    mapping(address => bool) public whitelistedARFAddress;

    // whitelisting for whitelist epoch
    mapping(address => bool) public whitelistedARCAddress;

    // whitelist for eggnite epoch
    mapping(address => bool) public whitelistedAddressEggnite;

    // whitelisting for Reserve epoch
    mapping(address => bool) public whitelistedARFReserve;

    // whitelisting for Reserve epoch
    mapping(address => bool) public whitelistedARCReserve;

    // whitelisting for Alloy Team epoch
    mapping(address => bool) public whitelistedARFAlloyTeam;

    // whitelisting for Alloy Team epoch
    mapping(address => bool) public whitelistedARCAlloyTeam;

    // factory pool data
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
    // mapping of factory pools w.r.t its epoch Id
    mapping(uint256 => mapping(uint256 => Pools)) public FactoryPools;

    // mapping of token ids w.r.t its types
    mapping(uint256 => string) public NFTtypes;

    // signature verifier
    mapping(bytes => bool) public isVerified;

    // allowed tokens to be minted
    uint256 public allowedPrinters;

    // NIOZ ERC20 token address
    IERC20Upgradeable public NiozERC20Address;

    // merchant wallet address
    address public MerchantWallet;

    // Order tuple for minting printer
    struct Order {
        uint256 epoch_id;
        uint256 pool_id;
        uint256 quantity;
        bytes32 message_hash;
    }

    // marketplace order
    struct SellOrder {
        uint256 Id;
        uint256 amount;
        bytes32 messageHash;
    }

    // marketplace order tuple
    struct SellOrderOffChain {
        uint256 Id;
        address previousOwner;
        uint256 amount;
        bytes32 messageHash;
    }

    // ARC token contract address
    Mintpeg public ConstructTokenAddress;

    // Events

    /**
     * @dev Emitted when users are whitelisted.
     */
    event WhitelistedARFAddress(address[] Addresses, bool Status);

    /**
     * @dev Emitted when users are whitelisted.
     */
    event WhitelistedARCAddress(address[] Addresses, bool Status);

    /**
     * @dev Emitted when users are whitelisted.
     */
    event WhitelistedAddressEggnite(address[] Addresses, bool Status);

    /**
     * @dev Emitted when user mints ARF whitelisted.
     */
    event ARFminted(address Owner, uint256 TokenId, uint256 EpochId);

    /**
     * @dev Emitted when user mints ARC whitelisted.
     */
    event ARCminted(address Owner, uint256 TokenId, uint256 EpochId);

    /**
     * @dev Emitted when user uses joepeg NFTs and mint ARCs & ARFs.
     */
    event ARC_ARF_Minted_Multiple(
        address Owner,
        uint256 EpochId,
        uint256[] ARC_TokenId,
        uint256[] ARF_TokenId,
        uint256[] JoePeg_TokenId
    );

    /**
     * @dev Emitted when user claims eggnite.
     */
    event Eggnite_Minted(
        address Owner,
        uint256 EpochId,
        uint256 ARC_TokenIds,
        uint256 ARF_TokenIds
    );

    /**
     * @dev Emitted when user mints ARF printer.
     */
    event PrinterMinted(
        address User,
        uint256[] TokenIds,
        uint256 EpochId,
        uint256 PoolId,
        uint256 AvaxPrice,
        uint256 NiozPrice,
        bool IsLimited,
        string NFTtype
    );

    /**
     * @dev Emitted when user buys from our platform marketplace.
     */
    event TokenPurchased(
        address PreviousOwner,
        address NewOwner,
        uint256 Price,
        uint256 TokenId,
        string TokenType
    );

     /**
     * @dev Emitted when users are whitelisted.
     */
    event WhitelistedARCReserves(address[] Addresses, bool Status);

     /**
     * @dev Emitted when users are whitelisted.
     */
    event WhitelistedARFReserves(address[] Addresses, bool Status);

     /**
     * @dev Emitted when users are whitelisted.
     */
    event WhitelistedARCAlloyTeams(address[] Addresses, bool Status);

     /**
     * @dev Emitted when users are whitelisted.
     */
    event WhitelistedARFAlloyTeams(address[] Addresses, bool Status);

     /**
     * @dev Emitted when users are whitelisted.
     */
    event ARC_Internal_Minted(address Owner, uint256 TokenId, uint256 EpochId);

     /**
     * @dev Emitted when users are whitelisted.
     */
    event ARF_Internal_Minted(address Owner, uint256 TokenId, uint256 EpochId);

    /**
     * @dev Emitted when user buys listed nft from marketplace.
     */
    event TokenPurchasedOffChain(
        address PreviousOwner,
        address NewOwner,
        uint256 Price,
        uint256 TokenId
    );

    // Initialization
    function initialize() public initializer {
        __ERC721_init("Alloy Space ARF", "ARF");
        __Ownable_init();
        __ReentrancyGuard_init();

        baseUri = "https://assets.alloy.space/token-uri-s2/";
        baseExtension = "-token-uri.json";

        tokenCounter = 0;

        uint16[8] memory _quantity_arf = [
            545,
            101,
            250,
            250,
            2005,
            1002,
            1001,
            401
        ];

        uint16[8] memory _quantity_arc = [
            1505,
            505,
            0,
            250,
            2005,
            2004,
            2003,
            2003
        ];

        for (uint256 i = 0; i < _quantity_arf.length; i++) {
            EpochPool memory _data = EpochPool(
                _quantity_arf[i],
                0,
                _quantity_arc[i],
                0
            );
            epochDetails[i + 1] = _data;
        }

        ARCAddress = Mintpeg(0x6BC174805568608e7092D554Ba5FeFD5461b5194);
        
        NiozERC20Address = IERC20Upgradeable(
            0x07B057133d28d44Fc1C917D8F77A5a8099f01A97
        );

        MerchantWallet = 0x4F68437579a7077010290e6b713076495fEe37E6;
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
     * @dev updated Epoch status
     *
     * @param _epoch_id epoch Id
     * @param _status status
     *
     * Requirements:
     * - msg.sender must be owner address of this contract.
     *
     */
    function updateEpochStatus(uint256[] calldata _epoch_id, bool _status)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < _epoch_id.length; i++) {
            checkEpochStatus[_epoch_id[i]] = _status;
        }
    }

    /**
     * @dev updated ARC epoch details
     *
     * @param _epoch_id array of epoch Ids
     * @param _quantity_arc array of quantities
     * @param _quantity_arf array of quantities
     *
     * Requirements:
     * - msg.sender must be owner address of this contract.
     *
     */
    function updateEpochDetails(
        uint256[] calldata _epoch_id,
        uint256[] calldata _quantity_arc,
         uint256[] calldata _quantity_arf
    ) external virtual onlyOwner {
        for (uint256 i = 0; i < _epoch_id.length; i++) {
            epochDetails[_epoch_id[i]].totalQuantityARC = _quantity_arc[i];
            epochDetails[_epoch_id[i]].totalQuantityARF = _quantity_arf[i];
        }
    }

    /**
     * @dev updated ARC factory pools data
     *
     * @param _epoch_id epoch Id
     * @param _pool_id array of pool Ids
     * @param _quantity_arf array of quantities
     * @param _avax_price array of avax price
     * @param _Nioz_price array of nioz price
     *
     * Requirements:
     * - msg.sender must be owner address of this contract.
     *
     */

    function updateARCPoolDetails(
        uint256 _epoch_id,
        uint256[] calldata _pool_id,
        uint256[] calldata _quantity_arf,
        uint256[] calldata _avax_price,
        uint256[] calldata _Nioz_price
    ) external virtual onlyOwner {
        for (uint256 i = 0; i < _pool_id.length; i++) {
            FactoryPools[_epoch_id][_pool_id[i]].poolId = _pool_id[i];
            FactoryPools[_epoch_id][_pool_id[i]]
                .totalQuantityARC = _quantity_arf[i];
            FactoryPools[_epoch_id][_pool_id[i]].avaxPriceARC = _avax_price[i];
            FactoryPools[_epoch_id][_pool_id[i]].NiozPriceARC = _Nioz_price[i];
        }
    }

    /**
     * @dev updated ARF factory pools data
     *
     * @param _epoch_id epoch Id
     * @param _pool_id array of pool Ids
     * @param _quantity_arf array of quantities
     * @param _avax_price array of avax price
     * @param _Nioz_price array of nioz price
     *
     * Requirements:
     * - msg.sender must be owner address of this contract.
     *
     */
    function updateARFPoolDetails(
        uint256 _epoch_id,
        uint256[] calldata _pool_id,
        uint256[] calldata _quantity_arf,
        uint256[] calldata _avax_price,
        uint256[] calldata _Nioz_price
    ) external virtual onlyOwner {
        for (uint256 i = 0; i < _pool_id.length; i++) {
            FactoryPools[_epoch_id][_pool_id[i]].poolId = _pool_id[i];
            FactoryPools[_epoch_id][_pool_id[i]]
                .totalQuantityARF = _quantity_arf[i];
            FactoryPools[_epoch_id][_pool_id[i]].avaxPriceARF = _avax_price[i];
            FactoryPools[_epoch_id][_pool_id[i]].NiozPriceARF = _Nioz_price[i];
        }
    }

    /**
     * @dev whitelist the user address
     *
     * @param _address array of addresses
     * @param _status status
     *
     * Requirements:
     * - msg.sender must owner of contract
     *
     * Emits a {WhitelistedARFAddress} event.
     */
    function whitelistARFAddresses(address[] calldata _address, bool _status)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < _address.length; i++) {
            whitelistedARFAddress[_address[i]] = _status;
        }

        emit WhitelistedARFAddress(_address, _status);
    }

    /**
     * @dev whitelist the user address
     *
     * @param _address array of addresses
     * @param _status status
     *
     * Requirements:
     * - msg.sender must owner of contract
     *
     * Emits a {WhitelistedARFAddress} event.
     */
    function whitelistARCAddresses(address[] calldata _address, bool _status)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < _address.length; i++) {
            whitelistedARCAddress[_address[i]] = _status;
        }

        emit WhitelistedARCAddress(_address, _status);
    }

    /**
     * @dev whitelist the user address
     *
     * @param _address array of addresses
     * @param _status status
     *
     * Requirements:
     * - msg.sender must owner of contract
     *
     * Emits a {WhitelistedARFAddress} event.
     */
    function whitelistAddressesEggnite(
        address[] calldata _address,
        bool _status
    ) external virtual onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            whitelistedAddressEggnite[_address[i]] = _status;
        }

        emit WhitelistedAddressEggnite(_address, _status);
    }

    /**
     * @dev whitelist the user address
     *
     * @param _address array of addresses
     * @param _status status
     *
     * Requirements:
     * - msg.sender must owner of contract
     *
     * Emits a {WhitelistedARFReserves} event.
     */
    function whitelistARFReserves(address[] calldata _address, bool _status)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < _address.length; i++) {
            whitelistedARFReserve[_address[i]] = _status;
        }
         emit WhitelistedARFReserves(_address, _status);
    }

    /**
     * @dev whitelist the user address
     *
     * @param _address array of addresses
     * @param _status status
     *
     * Requirements:
     * - msg.sender must owner of contract
     *
     * Emits a {WhitelistedARCReserves} event.
     */
    function whitelistARCReserves(address[] calldata _address, bool _status)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < _address.length; i++) {
            whitelistedARCReserve[_address[i]] = _status;
        }
        emit WhitelistedARCReserves(_address, _status);
    }

    /**
     * @dev whitelist the user address
     *
     * @param _address array of addresses
     * @param _status status
     *
     * Requirements:
     * - msg.sender must owner of contract
     *
     * Emits a {WhitelistedARFAlloyTeams} event.
     */
    function whitelistARFAlloyTeam(address[] calldata _address, bool _status)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < _address.length; i++) {
            whitelistedARFAlloyTeam[_address[i]] = _status;
        }
         emit WhitelistedARFAlloyTeams(_address, _status);
    }

    /**
     * @dev whitelist the user address
     *
     * @param _address array of addresses
     * @param _status status
     *
     * Requirements:
     * - msg.sender must owner of contract
     *
     * Emits a {WhitelistedARCAlloyTeams} event.
     */
    function whitelistARCAlloyTeam(address[] calldata _address, bool _status)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < _address.length; i++) {
            whitelistedARCAlloyTeam[_address[i]] = _status;
        }

        emit WhitelistedARCAlloyTeams(_address, _status);
    }

    /**
     * @dev updated contract values
     *
     * @param _joepeg_address joepeg contract address
     * @param _Nioz_address Nioz token address
     * @param _arc_address ARC token address
     * @param _num_allowed allowed printers to be mint in one transaction
     * @param _merchant_address merchant wallet address
     * @param _construct_address construct contract address
     *
     * Requirements:
     * - msg.sender must be owner address of this contract.
     *
     */
    function updateWallets(
        address _joepeg_address,
        address _arc_address,
        address _merchant_address,
        address _Nioz_address,
        address _construct_address,
        uint256 _num_allowed
    ) external onlyOwner {
        JoepegsTokenAddress = Mintpeg(_joepeg_address);
        ARCAddress = Mintpeg(_arc_address);
        MerchantWallet = _merchant_address;
        NiozERC20Address = IERC20Upgradeable(_Nioz_address);
        allowedPrinters = _num_allowed;
        ConstructTokenAddress = Mintpeg(_construct_address);
    }

    /**
     * @dev updated epoch details
     *
     * @param epoch_id epoch id
     * @param pool_id factory pool id
     * @param quantity quantity to be updated
     *
     * Requirements:
     * - msg.sender must be ARC contract address.
     *
     */
    function updateCounter(
        uint256 epoch_id,
        uint256 pool_id,
        uint256 quantity
    ) external {
        require(
            msg.sender == address(ARCAddress),
            "ArfERC721V1: Not permitted"
        );
        epochDetails[epoch_id].quantityCounterARC += quantity;
        FactoryPools[epoch_id][pool_id].quantityCounterARC += quantity;
    }

    /**
     * @dev User mints ARF whitelist tokens.
     *
     * Requirements:
     * - msg.sender must be whitelisted in whitelist epoch.
     *
     * Emits a {ARFminted} event.
     */
    function mintARF() external virtual {
        require(
            checkEpochStatus[3] &&
                epochDetails[3].quantityCounterARF <
                epochDetails[3].totalQuantityARF,
            "ArfERC721V1: Invalid epoch id or not enough quantity"
        );

        require(
            whitelistedARFAddress[msg.sender],
            "ArfERC721V1: Not whitelisted user"
        );
        whitelistedARFAddress[msg.sender] = false;

        tokenCounter += 1;
        _mint(msg.sender, tokenCounter);
        epochDetails[3].quantityCounterARF += 1;

        emit ARFminted(msg.sender, tokenCounter, 3);
    }

    /**
     * @dev User mints ARC whitelist tokens.
     *
     * Requirements:
     * - msg.sender must be whitelisted in whitelist epoch.
     *
     * Emits a {ARCminted} event.
     */
    function mintARC() external virtual nonReentrant {
        require(
            checkEpochStatus[3] &&
                epochDetails[3].quantityCounterARC <
                epochDetails[3].totalQuantityARC,
            "ArfERC721V1: Invalid epoch id or not enough quantity"
        );

        require(
            whitelistedARCAddress[msg.sender],
            "ArfERC721V1: Not whitelisted user"
        );
        whitelistedARCAddress[msg.sender] = false;
        epochDetails[3].quantityCounterARC += 1;

        uint256 tokenId = ARCAddress.mintARC(msg.sender);

        emit ARCminted(msg.sender, tokenId, 3);
    }

    /**
     * @dev User mints ARF whitelist tokens for epoch reserve and alloy team.
     *
     * Requirements:
     * -  msg.sender must be whitelisted in reserve or alloy team epoch.
     *
     * Emits a {ARC_Internal_Minted} event.
     */
    function mintInternalARC(uint256 epoch_id) external nonReentrant {
        require(
            checkEpochStatus[epoch_id] &&
                epochDetails[epoch_id].quantityCounterARC <
                epochDetails[epoch_id].totalQuantityARC &&
                (epoch_id == 1 || epoch_id == 2),
            "ArfERC721V1: Invalid epoch id or not enough quantity"
        );
        if (epoch_id == 1) {
            require(
                whitelistedARCReserve[msg.sender],
                "ArfERC721V1: Not whitelisted user"
            );
            whitelistedARCReserve[msg.sender] = false;
        }

        if (epoch_id == 2) {
            require(
                whitelistedARCAlloyTeam[msg.sender],
                "ArfERC721V1: Not whitelisted user"
            );
            whitelistedARCAlloyTeam[msg.sender] = false;
        }

        epochDetails[epoch_id].quantityCounterARC += 1;

        uint256 tokenId = ARCAddress.mintARC(msg.sender);

        emit ARC_Internal_Minted(msg.sender, tokenId, epoch_id);
    }

    /**
     * @dev User mints ARF whitelist tokens for epoch reserve and alloy team.
     *
     * Requirements:
     * - msg.sender must be whitelisted in reserve or alloy team epoch.
     *
     * Emits a {ARF_Internal_Minted} event.
     */
    function mintInternalARF(uint256 epoch_id) external {
        require(
            checkEpochStatus[epoch_id] &&
                epochDetails[epoch_id].quantityCounterARF <
                epochDetails[epoch_id].totalQuantityARF &&
                (epoch_id == 1 || epoch_id == 2),
            "ArfERC721V1: Invalid epoch id or not enough quantity"
        );
        if (epoch_id == 1) {
            require(
                whitelistedARFReserve[msg.sender],
                "ArfERC721V1: Not whitelisted user"
            );
            whitelistedARFReserve[msg.sender] = false;
        }

        if (epoch_id == 2) {
            require(
                whitelistedARFAlloyTeam[msg.sender],
                "ArfERC721V1: Not whitelisted user"
            );
            whitelistedARFAlloyTeam[msg.sender] = false;
        }

        epochDetails[epoch_id].quantityCounterARF += 1;

        tokenCounter += 1;
        _mint(msg.sender, tokenCounter);

        emit ARF_Internal_Minted(msg.sender, tokenCounter, epoch_id);
    }

    /**
     * @dev User mints ARC and ARF whitelist tokens.
     *
     * Requirements:
     * - msg.sender must be whitelisted in eggnite epoch.
     *
     * Emits a {Eggnite_Minted} event.
     */
    function mintEggnite() external virtual nonReentrant{
        require(
            (checkEpochStatus[4] &&
                epochDetails[4].quantityCounterARF <
                epochDetails[4].totalQuantityARF) &&
                epochDetails[4].quantityCounterARC <
                epochDetails[4].totalQuantityARC,
            "ArfERC721V1: Invalid epoch id or not enough quantity"
        );
        require(
            whitelistedAddressEggnite[msg.sender],
            "ArfERC721: Not whitelisted"
        );

        uint256 id = ARCAddress.mintARC(msg.sender);
        epochDetails[4].quantityCounterARC += 1;

        tokenCounter += 1;
        _mint(msg.sender, tokenCounter);
        epochDetails[4].quantityCounterARF += 1;

        whitelistedAddressEggnite[msg.sender] = false;

        emit Eggnite_Minted(msg.sender, 4, id, tokenCounter);
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
    function mintPrinterARF(
        Order calldata _order,
        bytes memory _signature,
        bool isLimited
    ) external payable virtual nonReentrant{
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                owner(),
                _order.message_hash,
                _signature
            ) &&
                !isVerified[_signature] &&
                !(NiozERC20Address.isVerified(_signature)) &&
                !(ARCAddress.isVerified(_signature)),
            "ArfERC721V1: Not allowed"
        );
        require(
            checkEpochStatus[_order.epoch_id] &&
                epochDetails[_order.epoch_id].totalQuantityARF >=
                epochDetails[_order.epoch_id].quantityCounterARF +
                    _order.quantity &&
                (_order.epoch_id == 6 ||
                    _order.epoch_id == 7 ||
                    _order.epoch_id == 8) &&
                FactoryPools[_order.epoch_id][_order.pool_id]
                    .totalQuantityARF >=
                FactoryPools[_order.epoch_id][_order.pool_id]
                    .quantityCounterARF,
            "ArfERC721V1: This epoch is closed or printer is out of stock"
        );

        require(
            FactoryPools[_order.epoch_id][_order.pool_id]
                .avaxPriceARF *
                _order.quantity ==
                msg.value,
            "ArfERC721V1: Invalid price"
        );

        uint256[] memory temp;
        require(
            _order.quantity <= allowedPrinters,
            "ArfERC721V1: Invalid quantity"
        );
        temp = new uint256[](_order.quantity);

        for (uint256 i = 0; i < _order.quantity; i++) {
            tokenCounter += 1;
            NFTtypes[tokenCounter] = "PRINTER";

            _safeMint(msg.sender, tokenCounter);
            temp[i] = tokenCounter;
        }

        payable(MerchantWallet).transfer(msg.value);
        if (FactoryPools[_order.epoch_id][_order.pool_id].NiozPriceARC > 0) {
            NiozERC20Address.safeTransfer(
                msg.sender,
                address(this),
                FactoryPools[_order.epoch_id][_order.pool_id].NiozPriceARF
            );
            NiozERC20Address.approve(
                MerchantWallet,
                FactoryPools[_order.epoch_id][_order.pool_id].NiozPriceARF
            );
            NiozERC20Address.safeTransfer(
                address(this),
                MerchantWallet,
                FactoryPools[_order.epoch_id][_order.pool_id].NiozPriceARC
            );
        }

        epochDetails[_order.epoch_id].quantityCounterARC += _order.quantity;
        FactoryPools[_order.epoch_id][_order.pool_id]
            .quantityCounterARF += _order.quantity;
        
        isVerified[_signature] = true;

        emit PrinterMinted(
            msg.sender,
            temp,
            _order.epoch_id,
            _order.pool_id,
            msg.value,
            FactoryPools[_order.epoch_id][_order.pool_id].NiozPriceARC,
            isLimited,
            "PRINTER"
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
            ) &&
                !isVerified[_signature] &&
                !(NiozERC20Address.isVerified(_signature)) &&
                !(ARCAddress.isVerified(_signature)),
            "ArfERC721V1: Not listed"
        );
        require(
            _order.amount == msg.value,
            "ArfERC721V1: Prize is incorrect or invalid"
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
     * Emits a {TokenPurchased} event.
     */
    function buyOffChain(SellOrderOffChain memory _order, bytes memory _signature)
        external
        payable
        virtual
        nonReentrant
    {
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                _order.previousOwner,
                _order.messageHash,
                _signature
            ) &&
                !isVerified[_signature] &&
                !(NiozERC20Address.isVerified(_signature)) &&
                !(ARCAddress.isVerified(_signature)),
            "ArfERC721V1: Not listed"
        );
        require(
            _order.amount == msg.value,
            "ArfERC721V1: Prize is incorrect or invalid"
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
            _order.Id
        );
    }

    /**
     * @dev User mints ARF and ARC tokens.
     *
     * @param _token_id array of token Ids
     *
     * Requirements:
     * - msg.sender must be have joepeg NFTs.
     *
     * Emits a {ARC_ARF_Minted_Multiple} event.
     */
    function JoepegsMultiple(uint256[] calldata _token_id) external virtual nonReentrant{
        require(
            checkEpochStatus[5] &&
                epochDetails[5].quantityCounterARF + _token_id.length <=
                epochDetails[5].totalQuantityARF &&
                epochDetails[5].quantityCounterARC + _token_id.length <=
                epochDetails[5].totalQuantityARC,
            "ArfERC721V1: Invalid epoch id or not enough quantity"
        );
        uint256[] memory arf_tokens = new uint256[](_token_id.length);
        uint256[] memory arc_tokens = new uint256[](_token_id.length);
        for (uint256 i = 0; i < _token_id.length; i++) {
            require(
                JoepegsTokenAddress.ownerOf(_token_id[i]) == msg.sender,
                "ArfERC721: Not a owner"
            );

            JoepegsTokenAddress.transferFrom(msg.sender, address(this), _token_id[i]);
            JoepegsTokenAddress.approve(
                address(0x000000000000000000000000000000000000dEaD),
                _token_id[i]
            );
            JoepegsTokenAddress.transferFrom(
                address(this),
                address(0x000000000000000000000000000000000000dEaD),
                _token_id[i]
            );

            uint256 tokenId = ARCAddress.mintARC(msg.sender);
            tokenCounter += 1;
            arf_tokens[i] = tokenCounter;
            arc_tokens[i] = tokenId;

            _mint(msg.sender, tokenCounter);
            epochDetails[5].quantityCounterARC += 1;
            epochDetails[5].quantityCounterARF += 1;
        }

        emit ARC_ARF_Minted_Multiple(
            msg.sender,
            5,
            arc_tokens,
            arf_tokens,
            _token_id
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
            "ArfERC721V1: URI query for nonexistent token"
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
        public
        view
        returns (uint256 Fee)
    {
        Fee = (ARCAddress.commissionFee() * _total_amount) / 1000;
    }
}