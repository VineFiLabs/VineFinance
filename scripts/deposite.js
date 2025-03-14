
const hre = require("hardhat");

const WETHABI=require("../artifacts/contracts/WETH.sol/WETH9.json");
const ERC20ABI=require("../artifacts/contracts/TestToken.sol/TestToken.json");
const VineHookCenterABI=require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineAaveV3InL2LendABI=require("../artifacts/contracts/hook/aave/VineAaveV3InL2Lend.sol/VineAaveV3InL2Lend.json");
const VineUniswapFactoryABI=require("../artifacts/contracts/hook/uniswap/VineUniswapV3Factory.sol/VineUniswapV3Factory.json");
const VineUniswapCoreABI=require("../artifacts/contracts/hook/uniswap/VineUniswapV3Core.sol/VineUniswapV3Core.json");

async function main() {
    const [owner, manager] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    console.log("manager:",manager.address);
    const provider = ethers.provider;

    const usdc="0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d";
    const ausdc="0x460b97BD498E1157530AEb3086301d5225b91216";
    const arbWETH="0x1dF462e2712496373A347f8ad10802a5E95f053D";
    const aavePool="0xBfC91D59fdAA134A4ED45f7B584cAf96D7792Eff";
    const GovernanceAddress = "0x834444686dE80CDFD2AF4282EF40eaB567EaD8f6";
    const Governance = new ethers.Contract(GovernanceAddress, VineHookCenterABI.abi, manager);

    const getMarketInfo=await Governance.getMarketInfo(2n);
    console.log("getMarketInfo:", getMarketInfo);

    const ERC20Contract=new ethers.Contract(usdc, ERC20ABI.abi, owner);
    const AUSDCContract=new ethers.Contract(ausdc, ERC20ABI.abi, owner);

    // const vineAaveV3InL2LendAddress="0x737219A26F75957Ad29276692457e7E301f9A6a0";
    // const VineAaveV3InL2Lend=new ethers.Contract(vineAaveV3InL2LendAddress,VineAaveV3InL2LendABI.abi,manager);

    // const thisBalance=await ERC20Contract.balanceOf(vineAaveV3InL2LendAddress);
    // console.log("thisBalance:", thisBalance);

    const WETH=new ethers.Contract(arbWETH, WETHABI.abi, owner);
    
    const vineUniswapHookAddress="0x1BAA3aa1FB8318393675BfdC54F6C314D6606B89";
    const VineUniswapHook=new ethers.Contract(vineUniswapHookAddress, VineUniswapCoreABI.abi, manager);


    // const depositeETH=await WETH.deposit({value: ethers.parseEther("0.001")});
    // await depositeETH.wait();
    // console.log("depositeETH success");

    // const WETHBalance=await WETH.balanceOf(owner.address);
    // console.log("WETHBalance:",WETHBalance);

    // const transfer=await WETH.transfer(vineUniswapHookAddress, WETHBalance);
    // await transfer.wait();
    // console.log("Transfer success");

    // const cross=await VineAaveV3InL2Lend.crossUSDC(
    //     1,
    //     3,
    //     0,
    //     usdc,
    //     thisBalance
    // );
    // const crossTx=await cross.wait();
    // console.log("Cross hash:", crossTx.hash);

    // const allowance=await ERC20Contract.allowance(owner.address, market);
    // if(allowance<1000n){
    //     const approveERC20=await ERC20Contract.approve(market, 1000n);
    //     await approveERC20.wait();
    //     console.log("approve erc20 success");
    // };

    // const deposite=await Market.deposite(
    //     1000n,
    //     market,
    //     aavePool
    // );
    // const depositeTx=await deposite.wait();
    // if(depositeTx.status === 1){
    //     console.log("depositeTx:", depositeTx);
    // }else{
    //     console.log("deposite fail");
    // }

    // const getUserSupply=await Market.getUserSupply(owner.address);
    // console.log("getUserSupply:", getUserSupply);  

    const ausdcBalance=await AUSDCContract.balanceOf(vineUniswapHookAddress);
    console.log("ausdcBalance:",ausdcBalance);

    const inL2Withdraw=await VineUniswapHook.inL2Withdraw(
      aavePool,
      ausdc,
      ausdcBalance
    );
    const inL2WithdrawTx=await inL2Withdraw.wait();
    console.log("inL2WithdrawTx:", inL2WithdrawTx.hash);



}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});