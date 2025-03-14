const hre = require("hardhat");

const ERC20ABI=require("../artifacts/contracts/TestToken.sol/TestToken.json");
const HyperOmniGNSCoreABI=require("../artifacts/contracts/hook/gns/HyperOmniGNSCore.sol/HyperOmniGNSCore.json");

async function main() {
    const [owner] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    const provider = ethers.provider;
    const ADDRESS_ZERO="0x0000000000000000000000000000000000000000";
    
    // const hyperOmniGNSCore = await ethers.getContractFactory("HyperOmniGNSCore");
    // const HyperOmniGNSCore = await hyperOmniGNSCore.deploy();
    // const HyperOmniGNSCoreAddress = await HyperOmniGNSCore.target;
    // console.log("HyperOmniGNSCore Address:",HyperOmniGNSCoreAddress);

    const HyperOmniGNSCoreAddress="0xAb8d7DD42ca2a64fb6a00983398DECcC9be85A66";
    const HyperOmniGNSCore=new ethers.Contract(HyperOmniGNSCoreAddress, HyperOmniGNSCoreABI.abi, owner);

    const spender="0xd659a15812064C79E189fd950A189b15c75d3186";
    const gnsMarket="0xd659a15812064C79E189fd950A189b15c75d3186";
    
    const gainUSDC="0x4cC7EbEeD5EA3adf3978F19833d2E1f3e8980cD6";
    const USDC=new ethers.Contract(gainUSDC, ERC20ABI.abi, owner);

    const gainUSDCBalance=await USDC.balanceOf(owner.address);
    console.log("USDC balance:", gainUSDCBalance);

    if(gainUSDCBalance < 2000000000n){
      throw("USDC Insufficient");
    }

    const allowance=await USDC.allowance(owner.address, HyperOmniGNSCoreAddress);
    if(allowance < ethers.parseEther("1")){
      const approve=await USDC.approve(HyperOmniGNSCoreAddress, ethers.parseEther("1000000"));
      await approve.wait();
      console.log("Approve success");
    }else{
      console.log("Not approve");
    }

    const Trade={
      user: owner.address,
      index: 0,
      pairIndex: 1,
      leverage: 1100,        //1.1倍
      long: true,
      isOpen: true,
      collateralIndex: 3,
      tradeType: 0,
      collateralAmount: 2000000000n,
      openPrice: 33867200000000n,
      tp: 0,
      sl: 0,
      __placeholder: 0
    };
    const maxSlippageP=10000n; //10%

    //open order
    // const openOrder=await HyperOmniGNSCore.openOrder(
    //   gnsMarket,
    //   Trade,
    //   maxSlippageP,
    //   gainUSDC,
    //   spender
    // );
    // const openOrderTx=await openOrder.wait();
    // console.log("openOrder success:", openOrderTx);

    //close order
    const closeOrder=await HyperOmniGNSCore.closeTradeMarket(gnsMarket, 0, 34557200000000n);
    const closeOrderTx=await closeOrder.wait();
    console.log("closeOrder:",closeOrderTx);

     
    

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});