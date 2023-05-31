const { expect } = require("chai");
const { ethers } = require("hardhat");
const { factory } = require("typescript");

describe("Alloy Project Contracts", function () {
  let nioz_instance;
  let arc_instance;
  let arf_instance;
  let construct_instance;
  let joepegs_instance;

  it("deployed the all alloy proxy contract", async () => {
    let mycontract = await ethers.getContractFactory("NiozERC20V2");
    nioz_instance = await upgrades.deployProxy(mycontract);
    let value = await nioz_instance.name();
    expect(value.toString()).to.equal("Nioz");

    mycontract = await ethers.getContractFactory("ArfERC721V2");
    arf_instance = await upgrades.deployProxy(mycontract);
    value = await arf_instance.name();
    expect(value.toString()).to.equal("Alloy Space ARF");

    mycontract = await ethers.getContractFactory("ConstructERC721V1");
    construct_instance = await upgrades.deployProxy(mycontract);
    value = await construct_instance.name();
    expect(value.toString()).to.equal("Alloy Space Construct");

    mycontract = await ethers.getContractFactory("AlloyERC721V2");
    arc_instance = await upgrades.deployProxy(mycontract);
    value = await arc_instance.name();
    expect(value.toString()).to.equal("Alloy Space S1");

    mycontract = await ethers.getContractFactory("Joepegs");
    joepegs_instance = await upgrades.deployProxy(mycontract);
    value = await joepegs_instance.name();
    expect(value.toString()).to.equal("Joepegs");
  });

  it("owner should update the address values in all contracts", async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await nioz_instance.updateAddresses(
      addr1.address,
      addr2.address,
      arc_instance.address,
      arf_instance.address,
      construct_instance.address
    );
    let value = await nioz_instance.ERC721TokenAddress();
    expect(value.toString()).to.equal(arc_instance.address);

    await arc_instance.updateMerchantWalletAndNiozAddress(
      addr1.address,
      nioz_instance.address,
      arf_instance.address,
      construct_instance.address,
      3,
      60
    );
    value = await arc_instance.NiozERC20Address();
    expect(value.toString()).to.equal(nioz_instance.address);

    await arf_instance.updateWallets(
      joepegs_instance.address,
      arc_instance.address,
      addr2.address,
      nioz_instance.address,
      construct_instance.address,
      3
    );
    value = await arf_instance.NiozERC20Address();
    expect(value.toString()).to.equal(nioz_instance.address);

    await construct_instance.updateWallets(
      arc_instance.address,
      addr1.address,
      nioz_instance.address,
      arf_instance.address
    );
    value = await construct_instance.ARCAddress();
    expect(value.toString()).to.equal(arc_instance.address);
  });

  it("owner should update the platform wallets, update weekly mint data, and mint the weekly tokens", async () => {
    const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    await nioz_instance.updatePlatformWallets([
      addr1.address,
      addr2.address,
      addr3.address,
      addr4.address,
    ]);
    await nioz_instance.updateMintData(
      [1, 2, 3, 4],
      [addr1.address, addr2.address, addr3.address, addr4.address],
      [
        "200000000000000000000",
        "300000000000000000000",
        "400000000000000000000",
        "500000000000000000000",
      ],
      [300, 300, 300, 300]
    );
    await nioz_instance.mintWeeklyTokens(4);
    let value = await nioz_instance.balanceOf(addr4.address);
    expect(value.toString()).to.equal("500000000000000000000");
  });

  it("owner should update the factory pool data", async () => {
    const [owner] = await ethers.getSigners();
    await arf_instance.updateARCPoolDetails(
      6,
      [1, 2, 3, 4],
      [500, 501, 501, 502],
      [
        "3000000000000000000",
        "5000000000000000000",
        "7000000000000000000",
        "11000000000000000000",
      ],
      [0, 0, 0, 0]
    );
    await arf_instance.updateARCPoolDetails(
      7,
      [1, 2, 3, 4],
      [501, 500, 501, 501],
      [
        "3000000000000000000",
        "5000000000000000000",
        "7000000000000000000",
        "11000000000000000000",
      ],
      [0, 0, 0, 0]
    );
    await arf_instance.updateARCPoolDetails(
      8,
      [1, 2, 3, 4],
      [500, 501, 501, 501],
      [
        "3000000000000000000",
        "5000000000000000000",
        "7000000000000000000",
        "11000000000000000000",
      ],
      [0, 0, 0, 0]
    );

    await arf_instance.updateARFPoolDetails(
      6,
      [1, 2, 3, 4],
      [250, 250, 252, 250],
      [
        "3000000000000000000",
        "5000000000000000000",
        "7000000000000000000",
        "11000000000000000000",
      ],
      [0, 0, 0, 0]
    );
    await arf_instance.updateARFPoolDetails(
      7,
      [1, 2, 3, 4],
      [250, 250, 250, 251],
      [
        "3000000000000000000",
        "5000000000000000000",
        "7000000000000000000",
        "11000000000000000000",
      ],
      [0, 0, 0, 0]
    );
    await arf_instance.updateARFPoolDetails(
      8,
      [1, 2, 3, 4],
      [100, 100, 100, 101],
      [
        "3000000000000000000",
        "5000000000000000000",
        "7000000000000000000",
        "11000000000000000000",
      ],
      [0, 0, 0, 0]
    );
    let value = await arf_instance.FactoryPools(6, 1);

    expect(value.totalQuantityARC.toString()).to.equal("500");
    expect(value.totalQuantityARF.toString()).to.equal("250");
  });

  it("Owner can whitelist for Epoch 1,2 and user can mint ARC in Epoch 1,2", async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await arf_instance.updateEpochStatus([1, 2], true);
    await expect(
      arf_instance.whitelistARCReserves([addr1.address, addr2.address], true)
    )
      .to.emit(arf_instance, "WhitelistedARCReserves")
      .withArgs([addr1.address, addr2.address], true);
    await expect(
      arf_instance.whitelistARCAlloyTeam([addr1.address, addr2.address], true)
    )
      .to.emit(arf_instance, "WhitelistedARCAlloyTeams")
      .withArgs([addr1.address, addr2.address], true);
    let tokenId = await arc_instance.tokenCounter();
    await expect(arf_instance.connect(addr1).mintInternalARC(1))
      .to.emit(arf_instance, "ARC_Internal_Minted")
      .withArgs(addr1.address, Number(tokenId.toString()) + 1, 1);
    tokenId = await arc_instance.tokenCounter();
    await expect(arf_instance.connect(addr2).mintInternalARC(2))
      .to.emit(arf_instance, "ARC_Internal_Minted")
      .withArgs(addr2.address, Number(tokenId.toString()) + 1, 2);
  });

  it("Owner can whitelist for Epoch 1,2 and user can mint ARF in Epoch 1,2", async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await arf_instance.updateEpochStatus([1, 2], true);
    await expect(
      arf_instance.whitelistARFReserves([addr1.address, addr2.address], true)
    )
      .to.emit(arf_instance, "WhitelistedARFReserves")
      .withArgs([addr1.address, addr2.address], true);
    await expect(
      arf_instance.whitelistARFAlloyTeam([addr1.address, addr2.address], true)
    )
      .to.emit(arf_instance, "WhitelistedARFAlloyTeams")
      .withArgs([addr1.address, addr2.address], true);

    await expect(arf_instance.connect(addr1).mintInternalARF(1)).to.emit(
      arf_instance,
      "ARF_Internal_Minted"
    );

    await expect(arf_instance.connect(addr2).mintInternalARF(2)).to.emit(
      arf_instance,
      "ARF_Internal_Minted"
    );
  });

  it("Owner can whitelist for Epoch 3 and user can mint ARF and ARC in Epoch 3", async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await arf_instance.updateEpochStatus([3], true);
    await expect(
      arf_instance.whitelistARCAddresses([addr1.address, addr2.address], true)
    )
      .to.emit(arf_instance, "WhitelistedARCAddress")
      .withArgs([addr1.address, addr2.address], true);
    await expect(
      arf_instance.whitelistARFAddresses([addr1.address, addr2.address], true)
    )
      .to.emit(arf_instance, "WhitelistedARFAddress")
      .withArgs([addr1.address, addr2.address], true);
    let tokenId = await arc_instance.tokenCounter();
    await expect(arf_instance.connect(addr1).mintARC()).to.be.revertedWith(
      "ArfERC721V1: Invalid epoch id or not enough quantity"
    );
    tokenId = await arf_instance.tokenCounter();
    await expect(arf_instance.connect(addr2).mintARF())
      .to.emit(arf_instance, "ARFminted")
      .withArgs(addr2.address, Number(tokenId.toString()) + 1, 3);
  });

  it("Owner can whitelist for Epoch 4 and user can mint ARF in Epoch 4", async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await arf_instance.updateEpochStatus([4], true);
    await expect(
      arf_instance.whitelistAddressesEggnite(
        [addr1.address, addr2.address],
        true
      )
    )
      .to.emit(arf_instance, "WhitelistedAddressEggnite")
      .withArgs([addr1.address, addr2.address], true);
    let tokenIdarc = await arc_instance.tokenCounter();
    let tokenIdarf = await arf_instance.tokenCounter();
    await expect(arf_instance.connect(addr1).mintEggnite())
      .to.emit(arf_instance, "Eggnite_Minted")
      .withArgs(
        addr1.address,
        4,
        Number(tokenIdarc.toString()) + 1,
        Number(tokenIdarf.toString()) + 1
      );
  });

  it("User who own joepegs tokens can mint in 5 epoch.", async () => {
    const [owner, addr1] = await ethers.getSigners();
    await arf_instance.updateEpochStatus([5], true);
    await joepegs_instance.connect(addr1).mint();
    await expect(
      joepegs_instance.connect(addr1).approve(arf_instance.address, 1)
    )
      .to.emit(joepegs_instance, "Approval")
      .withArgs(addr1.address, arf_instance.address, 1);

    let tokenIdarc = await arc_instance.tokenCounter();
    let tokenIdarf = await arf_instance.tokenCounter();

    await expect(arf_instance.connect(addr1).JoepegsMultiple([1]))
      .to.emit(arf_instance, "ARC_ARF_Minted_Multiple")
      .withArgs(
        addr1.address,
        5,
        [Number(tokenIdarc.toString()) + 1],
        [Number(tokenIdarf.toString()) + 1],
        [1]
      );
  });

  it("User mint token factory pools in 6,7,8 epoch.", async () => {
    const [owner, addr1] = await ethers.getSigners();
    await arf_instance.updateEpochStatus([6, 7, 8], true);

    let messageHash = ethers.utils.hashMessage("1");
    let signature = await owner.signMessage("1");
    let price = await arf_instance.FactoryPools(6, 1);

    await expect(
      arf_instance
        .connect(addr1)
        .mintPrinterARF([6, 1, 1, messageHash], signature, true, {
          value: price.avaxPriceARF.toString(),
        })
    ).to.emit(arf_instance, "PrinterMinted");

    messageHash = ethers.utils.hashMessage("2");
    signature = await owner.signMessage("2");
    price = await arf_instance.FactoryPools(7, 1);

    await expect(
      arf_instance
        .connect(addr1)
        .mintPrinterARF([7, 1, 1, messageHash], signature, true, {
          value: price.avaxPriceARF.toString(),
        })
    ).to.emit(arf_instance, "PrinterMinted");

    messageHash = ethers.utils.hashMessage("3");
    signature = await owner.signMessage("3");
    price = await arf_instance.FactoryPools(8, 1);

    await expect(
      arf_instance
        .connect(addr1)
        .mintPrinterARF([8, 1, 1, messageHash], signature, true, {
          value: price.avaxPriceARF.toString(),
        })
    ).to.emit(arf_instance, "PrinterMinted");

    messageHash = ethers.utils.hashMessage("4");
    signature = await owner.signMessage("4");
    price = await arf_instance.FactoryPools(6, 1);

    await expect(
      arc_instance
        .connect(addr1)
        .mintPrinterARC([6, 1, 1, messageHash], signature, {
          value: price.avaxPriceARC.toString(),
        })
    ).to.emit(arc_instance, "PrinterMinted");

    messageHash = ethers.utils.hashMessage("5");
    signature = await owner.signMessage("5");
    price = await arf_instance.FactoryPools(7, 1);

    await expect(
      arc_instance
        .connect(addr1)
        .mintPrinterARC([7, 1, 1, messageHash], signature, {
          value: price.avaxPriceARC.toString(),
        })
    ).to.emit(arc_instance, "PrinterMinted");

    messageHash = ethers.utils.hashMessage("6");
    signature = await owner.signMessage("6");
    price = await arf_instance.FactoryPools(8, 1);

    await expect(
      arc_instance
        .connect(addr1)
        .mintPrinterARC([8, 1, 1, messageHash], signature, {
          value: price.avaxPriceARC.toString(),
        })
    ).to.emit(arc_instance, "PrinterMinted");
  });

  it("User buys the ARF token from onchain and offchain marketplace", async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await arf_instance.updateEpochStatus([6, 7, 8], true);

    let messageHash = ethers.utils.hashMessage("1");
    let signature = await addr1.signMessage("1");
    let seller = await nioz_instance.recoverSigner(messageHash, signature);
    expect(seller === addr1.address)
    await expect(
      arf_instance
        .connect(addr2)
        .buy([1, "10000000000000000000", messageHash], signature, {
          value: "10000000000000000000",
        })
    ).to.emit(arf_instance, "TokenPurchased");

    messageHash = ethers.utils.hashMessage("2");
    signature = await addr1.signMessage("2");

    await expect(
      arf_instance
        .connect(addr2)
        .buyOffChain(
          [122, addr1.address, "10000000000000000000", messageHash],
          signature,
          { value: "10000000000000000000" }
        )
    ).to.emit(arf_instance, "TokenPurchasedOffChain");
  });

  it("User stakes NIOZ into the printer and Foundary", async () => {
    const [owner, addr1] = await ethers.getSigners();

    expect(
      await nioz_instance.transfer(addr1.address, "1000000000000000000000")
    ).to.emit(nioz_instance, "Transfer");

    expect(
      await nioz_instance.connect(addr1).stake(1, 232, "10000000000000000000")
    ).to.emit(nioz_instance, "Stake");

    expect(
      await nioz_instance.connect(addr1).stakeInFoundary("10000000000000000000")
    ).to.emit(nioz_instance, "StakeInFoundary");
  });

  it("User sells un processed part to econine", async () => {
    const [owner, addr1] = await ethers.getSigners();

    let messageHash = ethers.utils.hashMessage("5");
    let signature = await owner.signMessage("5");

    expect(
      await nioz_instance
        .connect(addr1)
        .sellUnprocessedPart(
          ["1000000000000000000000", 123, messageHash],
          signature
        )
    ).to.emit(nioz_instance, "Sold");
  });

  it("User claims the rewards", async () => {
    const [owner, addr1] = await ethers.getSigners();

    let messageHash = ethers.utils.hashMessage("6");
    let signature = await owner.signMessage("6");

    expect(
      await nioz_instance
        .connect(addr1)
        .claim(["1000000000000000000000", messageHash], signature)
    ).to.emit(nioz_instance, "Claim");
  });

  it("User refurbished the printers", async () => {
    const [owner, addr1] = await ethers.getSigners();

    let messageHash = ethers.utils.hashMessage("7");
    let signature = await owner.signMessage("7");

    expect(
      await nioz_instance
        .connect(addr1)
        .refurbished([123, 1, "1000000000000000000000", messageHash], signature)
    ).to.emit(nioz_instance, "PrinterRefurbished");
  });

  it("User burns NIOZ tokens and owner can burn tokens of other user", async () => {
    const [owner, addr1] = await ethers.getSigners();

    expect(
      await nioz_instance.connect(addr1).burnTokens("10000000000000000000")
    ).to.emit(nioz_instance, "BurnTokens");

    expect(
      await nioz_instance.burnTokensAuth(addr1.address, "100000000000000000")
    ).to.emit(nioz_instance, "BurnTokens");
  });

  it("User burns NIOZ tokens and owner can burn tokens of other user", async () => {
    const [owner, addr1] = await ethers.getSigners();

    let messageHash = ethers.utils.hashMessage("8");
    let signature = await owner.signMessage("8");

    expect(
      await arc_instance.connect(addr1).sellProcessedPart(["100000000000000", 1121, 2, true, 123, 1, messageHash], signature)
    ).to.emit(arc_instance, "PartBurned");
  });

  it("User buys the ARC tokens from onchain and offchain marketplace", async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();

    let messageHash = ethers.utils.hashMessage("9");
    let signature = await addr1.signMessage("9");
    let seller = await nioz_instance.recoverSigner(messageHash, signature);
    expect(seller === addr1.address)
    await expect(
      arc_instance
        .connect(addr2)
        .buy([1, "10000000000000000000", messageHash], signature, {
          value: "10000000000000000000",
        })
    ).to.emit(arc_instance, "TokenPurchased");

    messageHash = ethers.utils.hashMessage("10");
    signature = await addr1.signMessage("10");

    await expect(
      arc_instance
        .connect(addr2)
        .buyOffChain(
          [122, addr1.address, "10000000000000000000", "PRINTER", messageHash],
          signature,
          { value: "10000000000000000000" }
        )
    ).to.emit(arc_instance, "TokenPurchasedOffChain");
  });

  it("User can convert their old constructs to new construct tokens", async () => {
    const [owner, addr1] = await ethers.getSigners();

    let messageHash = ethers.utils.hashMessage("11");
    let signature = await owner.signMessage("11");

    expect(
      await construct_instance
        .connect(addr1)
        .convertConstruct([[2],[2], messageHash], signature)
    ).to.emit(construct_instance, "ConstructConverted");
  });

  it("User can mint constructor", async () => {
    const [owner, addr1] = await ethers.getSigners();

    let messageHash = ethers.utils.hashMessage("12");
    let signature = await owner.signMessage("12");

    expect(
      await construct_instance
        .connect(addr1)
        .mintConstruct([122, messageHash], signature)
    ).to.emit(construct_instance, "ConstructMinted");
  });

  it("User sell the construct to Econine", async () => {
    const [owner, addr1] = await ethers.getSigners();

    let messageHash = ethers.utils.hashMessage("13");
    let signature = await owner.signMessage("13");

    expect(
      await construct_instance
        .connect(addr1)
        .sellAlloyConstruct([123, '100000000', messageHash], signature)
    ).to.emit(construct_instance, "SoldConstruct");
  });

  it("User buys the CONSTRUCT token from onchain and offchain marketplace", async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    await arf_instance.updateEpochStatus([6, 7, 8], true);

    let messageHash = ethers.utils.hashMessage("14");
    let signature = await addr1.signMessage("14");
    let seller = await nioz_instance.recoverSigner(messageHash, signature);
    expect(seller === addr1.address)
    await expect(
      construct_instance
        .connect(addr2)
        .buy([1, "10000000000000000000", messageHash], signature, {
          value: "10000000000000000000",
        })
    ).to.emit(construct_instance, "TokenPurchased");

    messageHash = ethers.utils.hashMessage("2");
    signature = await addr1.signMessage("2");

    await expect(
      construct_instance
        .connect(addr2)
        .buyOffChain(
          [124, addr1.address, "10000000000000000000", messageHash],
          signature,
          { value: "10000000000000000000" }
        )
    ).to.emit(construct_instance, "TokenPurchasedOffChain");
  });
});
