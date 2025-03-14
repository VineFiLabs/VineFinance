const hre = require("hardhat");

const ERC20ABI=require("../artifacts/contracts/TestToken.sol/TestToken.json");
const VineLFJCoreABI=require("../artifacts/contracts/hook/lfj/VineLFJCore.sol/VineLFJCore.json");

async function main() {
    const [owner, manager] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    console.log("manager:",manager.address);
    const provider = ethers.provider;
    const ADDRESS_ZERO="0x0000000000000000000000000000000000000000";

    const router="0x18556DA13313f3532c54711497A8FedAC273220E";

    // const usdc=await ethers.getContractFactory("TestToken");
    // const USDC=await usdc.deploy("USDC","USDC",6);
    // const USDCAddress=await USDC.target;

    const USDCAddress="0x7897F215f89b51c94F82CB1f6b288d75DfcD71E6"
    const USDC=new ethers.Contract(USDCAddress,ERC20ABI.abi,owner);
   
    // const usdt=await ethers.getContractFactory("TestToken");
    // const USDT=await usdt.deploy("USDT","USDT",8);
    // const USDTAddress=await USDT.target;
    // console.log("USDT Address:",USDTAddress);
    const USDTAddress="0xae2E2263b7bF5B39B6A08Af81B145ae78488f738"
    const USDT=new ethers.Contract(USDTAddress,ERC20ABI.abi,owner);
   
    // const vineLFJCore=await ethers.getContractFactory("VineLFJCore");
    // const VineLFJCore=await vineLFJCore.deploy();
    // const VineLFJCoreAddress=await VineLFJCore.target;
    // console.log("VineLFJCore Address:",VineLFJCoreAddress);

    const VineLFJCoreAddress="0xB5c2f404F59E4387CD500d693d0c65394b32bE8c";
    const VineLFJCore=new ethers.Contract(VineLFJCoreAddress, VineLFJCoreABI.abi, owner);

    async function Approve(TokenContract, spender, amount) {
        try{
            const allowance=await TokenContract.allowance(owner.address,spender);
            console.log("allowance:",allowance);
            if(allowance<ethers.parseEther("100")){
                const approve=await TokenContract.approve(spender,amount);
                const approveTx=await approve.wait();
                console.log("approveTx:",approveTx.hash);
            }else{
                console.log("Not approve");
            }
        }catch(e){
            console.log("Approve error:",e);
        }
    }

    await Approve(USDC,router,ethers.parseEther("10000000000"));
    await Approve(USDT,router,ethers.parseEther("10000000000"));

    
    const createLBPair=await VineLFJCore.createLBPair(USDC,USDT,8387451n,10n);
    const createLBPairTx=await createLBPair.wait();
    console.log("createLBPairTx:",createLBPairTx.hash);

    const liquidityInfo=await VineLFJCore.liquidityInfo(VineLFJCoreAddress);
    console.log("liquidityInfo:",liquidityInfo);

    //addLiquidity
    const addLiquidityParams={
        pair: liquidityInfo.pair,
        router: router,
        tokenX: USDCAddress,
        tokenY: USDTAddress, 
        amountx: 10000000000n, 
        amounty: 1000000000000n,
        binStep: 10n,
        slippage: 1000n,
        deadline: 100n,
        deltaIds: [0],
        distributionX: [1000000000000000000n],
        distributionY: [1000000000000000000n]
    };
    const addLiquidity=await VineLFJCore.addLiquidity(
        addLiquidityParams
    );
    const addLiquidityTx=await addLiquidity.wait();
    console.log("addLiquidityTx:",addLiquidityTx.hash);

    const liquidityInfoAfter=await VineLFJCore.liquidityInfo(VineLFJCoreAddress);
    console.log("liquidityInfoAfter:",liquidityInfoAfter);

    //removeLiquidity
    const removeLiquidityParams={
        router: router,
        thisPairId: liquidityInfoAfter.pair,
        tokenX: USDCAddress,
        tokenY: USDTAddress,
        binStep: 100n,
        amountXMin: 0n,
        amountYMin: 0n,
        ids: [],
        amounts: [],
        deadline: 100n
    }
    // const removeLiquidity=await VineLFJCore.removeLiquidity(
    //     removeLiquidityParams
    // );
    // const removeLiquidityTx=await removeLiquidity.wait();
    // console.log("removeLiquidityTx:",removeLiquidityTx.hash);





    
    

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});