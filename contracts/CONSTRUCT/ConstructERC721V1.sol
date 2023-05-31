// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./MintpegInterface.sol";

contract ConstructERC721V1 is
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    // token counter
    uint256 public tokenCounter;

    // token URI
    string baseUri;
    string baseExtension;

    // merchant wallet
    address public MerchantWallet;

    // arc contract address
    Mintpeg public ARCAddress;

    // arf contract address
    Mintpeg public ARFtokenAddress;

    // ERC20 Nioz address
    IERC20Upgradeable public NiozERC20Address;

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

    // constructor order tuple
    struct ConstructOrder {
        uint256 constructId;
        bytes32 messageHash;
    }

    // mapping
    mapping(bytes => bool) public isVerified;

    // construct sold to econine status
    mapping(uint256 => bool) public isConstructMintable;

    // construct sold to econine status
    mapping(uint256 => bool) public isConstructSold;

    // constructor order tuple
    struct ConvertConstruct {
        uint256[] constructIds;
        bytes32 messageHash;
    }

    uint256[] private ids;

    // constructor order tuple
    struct ConvertConstruct1 {
        uint256[] constructIds;
        uint256[] constructTokenIds;
        bytes32 messageHash;
    }

    // Events
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
     * @dev Emitted when user buys listed nft from marketplace.
     */
    event TokenPurchasedOffChain(
        address PreviousOwner,
        address NewOwner,
        uint256 Price,
        uint256 TokenId,
        string TokenType
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
     * @dev Emitted when user sells the construct.
     */
    event SoldConstruct(
        address User,
        uint256 Amount,
        uint256 ConstructId,
        string NFTtype
    );

    /**
     * @dev Emitted when user mints the construct.
     */
    event ConstructConverted(
        address User,
        uint256[] ConstructId,
        uint256[] ConstructTokenId,
        string NFTtype
    );

    // Initialization
    function initialize() public initializer {
        __ERC721_init("Alloy Space Construct", "Construct-TT");
        __Ownable_init();
        __ReentrancyGuard_init();

        baseUri = "https://assets.alloy.space/token-uri-s2/";
        baseExtension = "-token-uri.json";

        tokenCounter = 0;

        MerchantWallet = 0x25fC99eF8C2bE73c303f7e54A0c2Da423E48326b;
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
     * @param _arc_address ARC token address
     * @param _merchant_address merchant wallet address
     *
     * Requirements:
     * - msg.sender must be owner address of this contract.
     *
     */
    function updateWallets(
        address _arc_address,
        address _merchant_address,
        address _nioz_address,
        address _Arf_address
    ) external onlyOwner {
        ARCAddress = Mintpeg(_arc_address);
        NiozERC20Address = IERC20Upgradeable(_nioz_address);
        MerchantWallet = _merchant_address;
        ARFtokenAddress = Mintpeg(_Arf_address);
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
            SignatureCheckerUpgradeable.isValidSignatureNow(
                previousOwner,
                _order.messageHash,
                _signature
            ) &&
                !isVerified[_signature] &&
                !(NiozERC20Address.isVerified(_signature)) &&
                !(ARCAddress.isVerified(_signature)),
            "ConstructERC721: Not listed"
        );
        require(
            _order.amount == msg.value,
            "ConstructERC721: Prize is incorrect or invalid"
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
            "CONSTRUCT"
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
        SellOrderOffChain memory _order,
        bytes memory _signature
    ) external payable virtual nonReentrant {
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                _order.previousOwner,
                _order.messageHash,
                _signature
            ) &&
                !isVerified[_signature] &&
                !(NiozERC20Address.isVerified(_signature)) &&
                !(ARCAddress.isVerified(_signature)),
            "ConstructERC721: Not listed"
        );
        require(
            _order.amount == msg.value,
            "ConstructERC721: Prize is incorrect or invalid"
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
            "CONSTRUCT"
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
    ) external virtual nonReentrant {
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                owner(),
                _order.messageHash,
                _signature
            ) &&
                !isVerified[_signature] &&
                !(NiozERC20Address.isVerified(_signature)) &&
                !(ARFtokenAddress.isVerified(_signature)) &&
                !(ARCAddress.isVerified(_signature)),
            "ConstructERC721: Not allowed"
        );
        require(
            !isConstructSold[_order.constructId] &&
                !isConstructMintable[_order.constructId],
            "ConstructERC721: Already sold or minted or OFF"
        );

        tokenCounter += 1;

        _safeMint(msg.sender, tokenCounter);
        isVerified[_signature] = true;
        isConstructMintable[_order.constructId] = true;

        emit ConstructMinted(
            msg.sender,
            _order.constructId,
            tokenCounter,
            "CONSTRUCT"
        );
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
    ) external virtual nonReentrant {
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                owner(),
                _order.messageHash,
                _signature
            ) &&
                !isVerified[_signature] &&
                !(NiozERC20Address.isVerified(_signature)) &&
                !(ARFtokenAddress.isVerified(_signature)) &&
                !(ARCAddress.isVerified(_signature)),
            "ConstructERC721: Not allowed"
        );
        require(
            !isConstructSold[_order.Id] && !isConstructMintable[_order.Id],
            "ConstructERC721: Already sold"
        );

        NiozERC20Address.mint(msg.sender, _order.amount);
        isVerified[_signature] = true;
        isConstructSold[_order.Id] = true;

        emit SoldConstruct(msg.sender, _order.amount, _order.Id, "CONSTRUCT");
    }

    /**
     * @dev User sells Construct and gets the NIOZ tokens.
     *
     * @param _order order tuple
     * @param _signature platform signature
     *
     * Emits a {SoldConstruct} event.
     */
    function convertConstruct(
        ConvertConstruct1 memory _order,
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
                !(ARFtokenAddress.isVerified(_signature)) &&
                !(ARCAddress.isVerified(_signature)),
            "ConstructERC721: Not allowed"
        );
        delete ids;
        for (uint256 i = 0; i < _order.constructIds.length; i++) {
            require(
                !isConstructSold[_order.constructIds[i]] &&
                    !isConstructMintable[_order.constructIds[i]],
                "ConstructERC721: Already sold"
            );
            isConstructMintable[_order.constructIds[i]] = true;
            tokenCounter += 1;

            _safeMint(msg.sender, tokenCounter);
            ids.push(tokenCounter);
        }
        ARCAddress.burnTokens(_order.constructTokenIds, "CONSTRUCT");

        isVerified[_signature] = true;

        emit ConstructConverted(msg.sender, _order.constructIds, ids, "CONSTRUCT");
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ConstructERC721: URI query for nonexistent token"
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
    ) public view returns (uint256 Fee) {
        Fee = (ARCAddress.commissionFee() * _total_amount) / 1000;
    }
}