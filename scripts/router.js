const hre = require("hardhat");
const fs = require('fs'); 

const GovernanceABI = require("../artifacts/contracts/core/Governance.sol/Governance.json");
const VineHookCenterABI = require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineRouter02ABI=require("../artifacts/contracts/helper/VineRouter02.sol/VineRouter02.json");
const VineAaveV3LendMainABI=require("../artifacts/contracts/hook/aave/VineAaveV3LendMain02.sol/VineAaveV3LendMain02.json");
const VineAaveV3LendMain02FactoryABI=require("../artifacts/contracts/hook/aave/VineAaveV3LendMain02Factory.sol/VineAaveV3LendMain02Factory.json");
const ERC20ABI=require("../artifacts/contracts/TestToken.sol/TestToken.json");

const Set=require('../set.json');

//router: 
async function main() {
    const [owner, manager] = await hre.ethers.getSigners();
    console.log("owner:", owner.address);
    console.log("manager:", manager.address);
    const provider = ethers.provider;
    const network = await provider.getNetwork();
    const chainId = network.chainId;
    console.log("Chain ID:", chainId);

    const marketId = 5;

    let config;
    let networkName;
    if(chainId === 1n){
      config = Set.Ethereum_Mainnet;
      networkName = "Ethereum_Mainnet";
    }else if(chainId === 43114n){
      config = Set.Avalanche_Mainnet;
      networkName = "Avalanche_Mainnet";
    }else if(chainId === 10n){
      config = Set.Op_Mainnet;
      networkName = "Op_Mainnet";
    }else if(chainId === 42161n){
      config = Set.Arbitrum_Mainnet;
      networkName = "Arbitrum_Mainnet";
    }else if(chainId === 8453n){
      config = Set.Base_Mainnet;
      networkName = "Base_Mainnet";
    }else if(chainId === 11155111n){
      config = Set.Sepolia;
      networkName = "Sepolia";
    }else if(chainId === 43113n){ 
      config = Set.Avalanche_fuji;
      networkName = "Avalanche_fuji";
    }else if(chainId === 11155420n){
      config = Set.Op_Sepolia;
      networkName = "Op_Sepolia";
    }else if(chainId === 421614n){
      config = Set.Arbitrum_Sepolia;
      networkName = "Arbitrum_Sepolia";
    }else if(chainId === 84532n){
      config = Set.Base_Sepolia;
      networkName = "Base_Sepolia";
    }else{
      throw("Not chain id");
    }

    const Governance=new ethers.Contract(config.Deployed.Governance, GovernanceABI.abi, manager);
    const getMarketInfo=await Governance.getMarketInfo(marketId);
    console.log("getMarketInfo:", getMarketInfo);

    // const vineRouter01 = await ethers.getContractFactory("VineRouter01");
    // const VineRouter01 = await vineRouter01.deploy(avaxGovernance, avaxUSDC);
    // const VineRouter01Address = await VineRouter01.target;
    // console.log("VineRouter01 Address:", VineRouter01Address);

    // const vineRouter02 = await ethers.getContractFactory("VineRouter02");
    // const VineRouter02 = await vineRouter02.deploy(config.Deployed.Governance, config.Deployed.VineConfig1);
    // const VineRouter02Address = await VineRouter02.target;
    // console.log("VineRouter02 Address:", VineRouter02Address);

    // const VineRouter01Address="";
    // const VineRouter01=new ethers.Contract(VineRouter01Address, VineRouter01ABI.abi, owner);

    const VineRouter02Address="0xBdc50f0c068cdD4F57Ad99aC41979E2beE98eF73";
    const VineRouter02=new ethers.Contract(VineRouter02Address, VineRouter02ABI.abi, owner);
    config.Deployed.VineRouter02 = VineRouter02Address;

    const getCuratorId = await Governance.getCuratorId(manager.address)
    console.log("getCuratorId:", getCuratorId);

    // const VineAaveV3LendMain02Factory=new ethers.Contract(config.Deployed.VineAaveV3LendMain02Factory, VineAaveV3LendMain02FactoryABI.abi, owner);
    const market = getMarketInfo[7];
    console.log("Market:", market);

    const ERC20Contract=new ethers.Contract(config.USDC, ERC20ABI.abi, owner);

    const allowance=await ERC20Contract.allowance(owner.address, VineRouter02Address);
    if(allowance<1000000n){
        const approveERC20=await ERC20Contract.approve(VineRouter02Address, 100000000000n);
        await approveERC20.wait();
        console.log("approve erc20 success");
    }else{
      console.log("Not approve");
    }

    const deposite=await VineRouter02.deposite(
        marketId,
        0,
        2000000n,  //1 usdc
        market
    );
    const depositeTx=await deposite.wait();
    console.log("deposite success:", depositeTx.hash);

    // const getUserShareTokenBalance=await VineRouter02.getUserTokenBalance(market[1], owner.address);
    // console.log("getUserShareTokenBalance:", getUserShareTokenBalance);

    // const transferUsdc = await ERC20Contract.transfer(market, 1000000n);  //1 usdc
    // await transferUsdc.wait();
    // console.log("transferUsdc success");

    // const marketContract = new ethers.Contract(market[1], VineAaveV3LendMainABI.abi, owner);

    // const deposite=await marketContract.deposite(
    //     0,
    //     0,
    //     20000n,
    //     owner.address
    // );
    // const depositeTx=await deposite.wait();
    // console.log("deposite success:", depositeTx.hash);

    // //update
    // const updateFinallyAmount=await managerMarketContract.updateFinallyAmount(arbUSDC);
    // await updateFinallyAmount.wait();
    // console.log("updateFinallyAmount success");

    // const getUserTokenBalance=await VineRouter01.getUserTokenBalance(arbUSDC, market);
    // console.log("getUserTokenBalance:", getUserTokenBalance);

    // const withdraw =await marketContract.withdraw(
    //     arbUSDC
    // );
    // const withdrawTx=await withdraw.wait();
    // console.log("withdraw success:", withdrawTx);

    const setPath = './set.json';
    const currentSet = JSON.parse(fs.readFileSync(setPath, 'utf8'));
    currentSet[networkName] = config;
    fs.writeFileSync(setPath, JSON.stringify(currentSet, null, 2));
    console.log("set.json updated");



}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});