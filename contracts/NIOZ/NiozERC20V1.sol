// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

contract NiozERC20V1 is ERC20Upgradeable, OwnableUpgradeable {
    // Max Supply in market
    uint256 public MaxSupply;

    // Token price in avax
    uint256 public tokenPrice;

    // Merchant wallet for tax collection
    address public MerchantWallet;

    // Alloy ERC721 contract address
    IERC721Upgradeable public ERC721TokenAddress;

    // Stake Order
    struct StakeOrder {
        uint256 amount;
        uint256 tokenId;
        uint256 printerId;
        bytes32 messageHash;
    }

    // Order
    struct Order {
        uint256 amount;
        uint256 partId;
        bytes32 messageHash;
    }

    // prevents signature from repeating
    mapping(bytes => bool) public isVerified;

    // Reward Order
    struct Reward {
        uint256 amount;
        bytes32 messageHash;
    }

    // joe trader pair address
    IERC20Upgradeable public pairAddress;

    // platform addresses
    address[] platformWalletAddress;

    // Sell order
    struct SellOrder {
        uint256 id;
        uint256 tokenId;
        uint256 amount;
        bytes32 messageHash;
    }

    // weekly mint data
    struct MintingData {
        uint256 id;
        address walletAddress;
        uint256 weeklyAmt;
        uint256 timeDiff;
        uint256 lastTimestamp;
    }
    // mapping of weekly mint data w.r.t. its type
    mapping(uint256 => MintingData) public MintData;
    
    // ARF ERC721 contract address
    IERC721Upgradeable public ARFtokenAddress;


    //Events
    /**
     * @dev Emitted when user stakes the token into printer.
     */
    event Stake(
        address User,
        uint256 TokenId,
        uint256 PrinterId,
        uint256 Amount
    );

    /**
     * @dev Emitted when user buys the tokens.
     */
    event Bought(address User, uint256 Amount);

    /**
     * @dev Emitted when user sells the unprocessed part.
     */
    event Sold(address User, uint256 PartId, uint256 Amount);

    /**
     * @dev Emitted when user receives the rewards.
     */
    event ExtractionReward(address User, uint256 Amount);

    /**
     * @dev Emitted when user claims the reward.
     */
    event Claim(address User, uint256 Amount);

    /**
     * @dev Emitted when printer is refurbished.
     */
    event PrinterRefurbished(
        address Owner,
        uint256 TokenId,
        uint256 ArcId,
        uint256 Amount
    );

    /**
     * @dev Emitted when tokens are minted weekly.
     */
    event MintWeeklyTokens(address Address, uint256 Amount, uint256 Id);

    // Initialization function
    function initialize() public initializer {
        __ERC20_init("Nioz", "NIOZ");
        __Ownable_init();
        MerchantWallet = 0x25fC99eF8C2bE73c303f7e54A0c2Da423E48326b;
        _mint(msg.sender, 688000 * (10**18));

        uint8[4] memory _ids = [1, 2, 3, 4];
        uint80[4] memory _amounts = [
            48073000000000000000000,
            153846000000000000000000,
            192397000000000000000000,
            96153000000000000000000
        ];
        uint24[4] memory _time = [604800, 604800, 604800, 604800];
        address[4] memory _address = [
            0x25fC99eF8C2bE73c303f7e54A0c2Da423E48326b,
            0x25fC99eF8C2bE73c303f7e54A0c2Da423E48326b,
            0x25fC99eF8C2bE73c303f7e54A0c2Da423E48326b,
            0x25fC99eF8C2bE73c303f7e54A0c2Da423E48326b
        ];

        for (uint256 i = 0; i < _ids.length; i++) {
            MintingData memory _data = MintingData(
                _ids[i],
                _address[i],
                _amounts[i],
                _time[i],
                0
            );
            MintData[_ids[i]] = _data;
        }
    }

    /**
     * @dev Only allowed address can perform specific task.
     */
    modifier onlyAllowedAddress() {
        require(
            msg.sender == address(ERC721TokenAddress),
            "NiozERC20: Not allowed"
        );
        _;
    }

    /**
     * @dev Updates the contract address and Nioz pair address.
     *
     * Only the Owner of the contract can update the addresses
     *
     */
    function updateAddresses(
        address _address,
        address _pair_address,
        address _erc721_address,
        address _Arf_address
    ) external virtual onlyOwner {
        MerchantWallet = _address;
        ARFtokenAddress = IERC721Upgradeable(_Arf_address);
        pairAddress = IERC20Upgradeable(_pair_address);
        ERC721TokenAddress = IERC721Upgradeable(_erc721_address);
    }

    /**
     * @dev Updates the wallet addresses that are on Alloy LP platform.
     *
     * Only the Owner of the contract can update the addresses
     *
     */
    function updatePlatformWallets(address[] calldata _address)
        external
        virtual
        onlyOwner
    {
        delete platformWalletAddress;
        for (uint256 i = 0; i < _address.length; i++) {
            platformWalletAddress.push(_address[i]);
        }
    }

    /**
     * @dev Updates the weelt mint data.
     *
     * Only the Owner of the contract can update the addresses
     *
     */
    function updateMintData(
        uint256[] calldata _ids,
        address[] calldata _address,
        uint256[] calldata _weekly_amts,
        uint256[] calldata _time_diff
    ) external virtual onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            MintingData memory _data = MintingData(
                _ids[i],
                _address[i],
                _weekly_amts[i],
                _time_diff[i],
                MintData[i].lastTimestamp
            );
            MintData[_ids[i]] = _data;
        }
    }

    /**
     * @dev User stakes the Nioz token into printer.
     *
     * @param _tokenId Printer token Id.
     * @param _printerId printer Id
     * @param _amount amount to be staked.
     *
     * Requirements:
     * - msg.sender must be owner of printer token.
     *
     * Emits a {Stake} event.
     */
    function stake(
        uint256 _tokenId,
        uint256 _printerId,
        uint256 _amount
    ) external virtual {
        require(
            ERC721TokenAddress.ownerOf(_tokenId) == msg.sender,
            "NiozERC20: Not an owner"
        );

        _burn(msg.sender, _amount);

        emit Stake(msg.sender, _tokenId, _printerId, _amount);
    }

    /**
     * @dev This method used when the user sell the un processed part to factory.
     *
     * @param _order order details.
     * @param _signature user Signature.
     *
     * Emits a {Sold} event.
     */
    function sellUnprocessedPart(Order memory _order, bytes memory _signature)
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
                !(ERC721TokenAddress.isVerified(_signature)) &&
                !(ARFtokenAddress.isVerified(_signature)),
            "NiozERC20: Not allowed"
        );
        _mint(msg.sender, _order.amount);
        isVerified[_signature] = true;

        emit Sold(msg.sender, _order.partId, _order.amount);
    }

    /**
     * @dev owner can mint new tokens on given destination address.
     *
     * @param _from user address.
     * @param _to destination address
     * @param _amount amount to be minted.
     *
     * Requirements:
     * - only erc721 contract address can call this method
     *
     */
    function safeTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external virtual onlyAllowedAddress {
        _spendAllowance(_from, _to, _amount);
        _transfer(_from, _to, _amount);
    }

    /**
     * @dev mints the Nioz token.
     *
     * @param _who destination address.
     * @param _amount amount to be minted.
     *
     * Requirements:
     * - Only allowed address can mint the tokens.
     *
     */
    function mint(address _who, uint256 _amount)
        external
        virtual
        onlyAllowedAddress
    {
        _mint(_who, _amount);
    }

    /**
     * @dev mints the new Nioz tokens when user receives the reward.
     *
     * @param _order Reward order.
     * @param _signature platform signature.
     *
     * Emits a {ExtractionReward} event.
     */

    function reward(Reward calldata _order, bytes memory _signature) external {
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                owner(),
                _order.messageHash,
                _signature
            ) &&
                !isVerified[_signature] &&
                !(ERC721TokenAddress.isVerified(_signature)) &&
                !(ARFtokenAddress.isVerified(_signature)),
            "NiozERC20: Not allowed"
        );
        require(_order.amount > 0, "NiozERC20: Reward is zero");

        _mint(msg.sender, _order.amount);
        isVerified[_signature] = true;

        emit ExtractionReward(msg.sender, _order.amount);
    }

    /**
     * @dev User can view there share percentage and share details.
     *
     * @param _user user address
     *
     * Requirements:
     * - user must be login to alloy platform and owns the LP tokens.
     *
     * Returns
     * - User address.
     * - Total Supply on platform.
     * - User Token balance.
     * - User token share percentage.
     */
    function viewSharePercent(address _user)
        public
        view
        returns (
            address User,
            uint256 TotalSupply,
            uint256 UserTokenBalance,
            uint256 SharePercentage
        )
    {
        uint256 platformBalance;
        for (uint256 i = 0; i < platformWalletAddress.length; i++) {
            platformBalance += pairAddress.balanceOf(platformWalletAddress[i]);
        }

        User = _user;
        TotalSupply = (pairAddress.totalSupply() - platformBalance);
        UserTokenBalance = pairAddress.balanceOf(_user);
        SharePercentage = (UserTokenBalance * 100000) / TotalSupply;
    }

    /**
     * @dev mints the new Nioz tokens when user claims the reward.
     *
     * @param _order Reward order.
     * @param _signature platform signature.
     *
     * Emits a {Claim} event.
     */
    function claim(Reward calldata _order, bytes memory _signature) external {
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                owner(),
                _order.messageHash,
                _signature
            ) &&
                !isVerified[_signature] &&
                !(ERC721TokenAddress.isVerified(_signature)) &&
                !(ARFtokenAddress.isVerified(_signature)),
            "NiozERC20: Not allowed"
        );
        require(_order.amount > 0, "NiozERC20: Amount is zero");

        _mint(msg.sender, _order.amount);
        isVerified[_signature] = true;

        emit Claim(msg.sender, _order.amount);
    }

    /**
     * @dev burns the Nioz tokens when user refurbished the printer.
     *
     * @param _order sell order.
     * @param _signature platform signature.
     *
     * Emits a {PrinterRefurbished} event.
     */
    function refurbished(SellOrder memory _order, bytes memory _signature)
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
                !(ERC721TokenAddress.isVerified(_signature)) &&
                !(ARFtokenAddress.isVerified(_signature)),
            "NiozERC20: Not allowed"
        );

        require(
            ERC721TokenAddress.ownerOf(_order.tokenId) == msg.sender,
            "NiozERC20: Not a owner"
        );

        _burn(msg.sender, _order.amount);
        isVerified[_signature] = true;

        emit PrinterRefurbished(
            msg.sender,
            _order.tokenId,
            _order.id,
            _order.amount
        );
    }

    /**
     * @dev blacklist the user from transfering and burns its nioz balance.
     *
     * @param _addresses array of addresses
     * @param _status platform status.
     *
     * Requirement:
     * - only owner of contract can call this method
     */
    function blacklist(address[] calldata _addresses, bool _status)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklistAddresses[_addresses[i]] = _status;
            if (_status) {
                _burn(_addresses[i], balanceOf(_addresses[i]));
            }
        }
    }

    /**
     * @dev mints the amount into specified address per week
     *
     * @param id type
     *
     * Requirement:
     * - only owner of contract can call this method
     */
    function mintWeeklyTokens(uint256 id) external virtual onlyOwner {
        require(
            MintData[id].lastTimestamp + MintData[id].timeDiff <=
                block.timestamp,
            "NiozERC20: Time is not up"
        );
        _mint(MintData[id].walletAddress, MintData[id].weeklyAmt);
        MintData[id].lastTimestamp = block.timestamp;

        emit MintWeeklyTokens(
            MintData[id].walletAddress,
            MintData[id].weeklyAmt,
            id
        );
    }
}
