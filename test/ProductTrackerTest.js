const { expect } = require("chai");
const { ethers } = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { BigNumber } = require("ethers");

const producerInfo = {
  name: "Dugme Üretici Firma",
  location: "Dugme Üretici Adres Mah.",
};
const producer2Info = {
  name: "Kumaş Üretici Firma",
  location: "Kumaş Üretici Adres Mah.",
};
const producer3Info = {
  name: "Kazak Üretici Firma",
  location: "Kazak Üretici Adres Mah.",
};

describe("Product Tracker Contract", function () {
  let pTracker, PTracker;
  let owner;

  before(async function () {
    [owner, producer, producer2, producer3, user] = await ethers.getSigners();
    const Lib = await ethers.getContractFactory("Helper");
    const lib = await Lib.deploy();
    await lib.deployed();

    PTracker = await ethers.getContractFactory("ProductTracker", {
      libraries: {
        Helper: lib.address,
      },
    });
    pTracker = await PTracker.connect(owner).deploy();
    await pTracker.deployed();
    await pTracker
      .connect(owner)
      .createFirmAndOwner(
        producer.address,
        producerInfo.name,
        producerInfo.location,
        true
      );
    await pTracker
      .connect(owner)
      .createFirmAndOwner(
        producer2.address,
        producer2Info.name,
        producer2Info.location,
        true
      );
    await pTracker
      .connect(owner)
      .createFirmAndOwner(
        producer3.address,
        producer3Info.name,
        producer3Info.location,
        true
      );
  });

  it("should contract owner correctly set", async function () {
    let _owner = await pTracker.owner();
    expect(_owner).to.equal(owner.address);
  });

  describe("Role", function() {
    it("should get role", async function () {
      expect(await pTracker.connect(user).getRole()).to.equal(0);
      expect(await pTracker.connect(owner).getRole()).to.equal(1);
      expect(await pTracker.connect(producer).getRole()).to.equal(2);
      expect(await pTracker.connect(producer2).getRole()).to.equal(2);
      expect(await pTracker.connect(producer3).getRole()).to.equal(2);
    })
  });

  describe("Add Product", function () {
    it("should add product not allowed for unauthorized roles", async function () {
      let product = { _productName: "Düğme" };
      await expect(pTracker.connect(owner).addNewProduct(product._productName))
        .to.be.reverted;
      await expect(pTracker.connect(user).addNewProduct(product._productName))
        .to.be.reverted;
    });

    it("should add product allowed for producer", async function () {
      let product = { _productName: "Jakar" };
      await expect(
        pTracker.connect(producer).addNewProduct(product._productName)
      )
        .to.emit(pTracker, "AddProduct")
        .withArgs(
          anyValue,
          producerInfo.name,
          producerInfo.location,
          product._productName
        );
    });
  });

  describe("Sub Product", function () {
    before(async function () {
      let tx = await pTracker.connect(producer).addNewProduct("Düğme");
      let rc = await tx.wait();
      uidDugme = rc.events[0].args.uid;
      tx = await pTracker.connect(producer2).addNewProduct("Kumaş");
      rc = await tx.wait();
      uidKumas = rc.events[0].args.uid;
      tx = await pTracker.connect(producer3).addNewProduct("Kazak");
      rc = await tx.wait();
      uidKazak = rc.events[0].args.uid;

    });

    it("should not add sub product because address not product owner", async function () {
      await expect(
        pTracker.connect(producer2).addSubProduct(uidKazak, uidKumas)
      ).to.be.revertedWith("You are not product owner");
    });

    it("should add sub product", async function () {
      let expectedResults = {
        newProductId: uidKazak,
        verifySubProductId: uidKumas,
        status: 2,
        subProductName: "Kumaş",
        parentProductName: "Kazak",
        requestor: producer3Info.name,
        confirmer: producer2Info.name
      };
      await expect(
        pTracker.connect(producer3).addSubProduct(uidKazak, uidKumas)
      )
        .to.emit(pTracker, "VerifyProduct")
        .withArgs(
          expectedResults.newProductId,
          expectedResults.verifySubProductId,
          expectedResults.status,
          anyValue,
          expectedResults.subProductName,
          expectedResults.parentProductName,
          expectedResults.requestor,
          expectedResults.confirmer,
          anyValue
        );
    });

    it("should not verify sub product because address not product owner", async function () {
      let tx = await pTracker.connect(producer3).addSubProduct(uidKazak, uidKumas);
      let rc = await tx.wait();
      let verifyId = (BigNumber.from(rc.events[0].args.verifyId).toNumber());

      await expect(
        pTracker.connect(producer3).verifySubProduct(verifyId, 1)
      ).to.be.revertedWith("You are not product owner");
    });

    it("should verify sub product", async function () {
      let tx = await pTracker.connect(producer3).addSubProduct(uidKazak, uidKumas);
      let rc = await tx.wait();
      let verifyId = (BigNumber.from(rc.events[0].args.verifyId).toNumber());

      let expectedResults = {
        newProductId: uidKazak,
        verifySubProductId: uidKumas,
        status: 1,
        subProductName: "Kumaş",
        parentProductName: "Kazak",
        requestor: producer3Info.name,
        confirmer: producer2Info.name
      };
      await expect(
        pTracker.connect(producer2).verifySubProduct(verifyId, 1)
      )
        .to.emit(pTracker, "VerifyProduct")
        .withArgs(
          expectedResults.newProductId,
          expectedResults.verifySubProductId,
          expectedResults.status,
          anyValue,
          expectedResults.subProductName,
          expectedResults.parentProductName,
          expectedResults.requestor,
          expectedResults.confirmer,
          verifyId
        );
    });
  });
});
