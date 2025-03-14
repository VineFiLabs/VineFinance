const hre = require("hardhat");

const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const VineMorphoCoreABI = require("../artifacts/contracts/hook/morpho/VineMorphoCore.sol/VineMorphoCore.json");

async function main() {
  const [owner] = await hre.ethers.getSigners();
  console.log("owner:", owner.address);
  const provider = ethers.provider;
  const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";

  // const vineMorphoCore = await ethers.getContractFactory("VineMorphoCore");
  // const VineMorphoCore = await vineMorphoCore.deploy();
  // const VineMorphoCoreAddress = await VineMorphoCore.target;
  // console.log("VineMorphoCore Address:",VineMorphoCoreAddress);

  const VineMorphoCoreAddress = "0x680B5A206864903cf092f3f2EE20b2dE213e50a1";
  const VineMorphoCore = new ethers.Contract(
    VineMorphoCoreAddress,
    VineMorphoCoreABI.abi,
    owner
  );

  const baseUSDC = "0x036CbD53842c5426634e7929541eC2318f3dCF7e";
  const baseWETH = "0x4200000000000000000000000000000000000006";
  const baseOracle = "0x1631366C38d49ba58793A5F219050923fbF24C81";

  const USDC = new ethers.Contract(baseUSDC, ERC20ABI.abi, owner);

  const USDCBalance = await USDC.balanceOf(owner.address);
  console.log("USDC balance:", USDCBalance);

  const allowance = await USDC.allowance(owner.address, VineMorphoCoreAddress);
  if (allowance < ethers.parseEther("1")) {
    const approve = await USDC.approve(
      VineMorphoCoreAddress,
      ethers.parseEther("1000000")
    );
    await approve.wait();
    console.log("Approve success");
  } else {
    console.log("Not approve");
  }

  const baseMorphoMarket = "0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb";
  const ID =
    "0xe36464b73c0c39836918f7b2b9a6f1a8b70d7bb9901b38f29544d9b96119862e";

  const marketParams = await VineMorphoCore.getIdToMarketParams(
    baseMorphoMarket,
    ID
  );
  console.log("marketParams:", marketParams);

  const MarketParams = {
    loanToken: marketParams[0],
    collateralToken: marketParams[1],
    oracle: marketParams[2],
    irm: marketParams[3],
    lltv: marketParams[4],
  };
  const amount = 10000n;
  // const supply=await VineMorphoCore.supply(
  //   MarketParams,
  //   baseMorphoMarket,
  //   amount,
  //   0n
  // );
  // const supplyTx=await supply.wait();
  // console.log("supply tx:", supplyTx.hash);

  // const withdraw = await VineMorphoCore.withdraw(
  //   MarketParams,
  //   baseMorphoMarket,
  //   amount,
  //   0,
  //   VineMorphoCoreAddress,
  //   owner.address
  // );
  // const withdrawTx = await withdraw.wait();
  // console.log("withdraw:", withdrawTx.hash);

  const getPosition=await VineMorphoCore.getPosition(
    baseMorphoMarket,
    ID,
    VineMorphoCoreAddress
  );
  console.log("getPosition:", getPosition);

  const getMarket=await VineMorphoCore.getMarket(
    baseMorphoMarket,
    ID
  );
  console.log("getMarket:", getMarket);






}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
