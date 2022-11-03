// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const Lib = await ethers.getContractFactory("Helper");
    const lib = await Lib.deploy();
    await lib.deployed();

    PTracker = await ethers.getContractFactory("ProductTracker", {
      libraries: {
        Helper: lib.address,
      },
    });
    pTracker = await PTracker.deploy();
    await pTracker.deployed();

  console.log("Contract deployed to: ", pTracker.address);
};


const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();