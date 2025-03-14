const hre = require("hardhat");
const fs = require('fs');

const GovernanceABI=require("../artifacts/contracts/core/Governance.sol/Governance.json");
const VineHookCenterABI=require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineAaveV3LendMain02FactoryABI=require("../artifacts/contracts/hook/aave/VineAaveV3LendMain02Factory.sol/VineAaveV3LendMain02Factory.json");
const VineInL2LendFactoryABI=require("../artifacts/contracts/hook/aave/VineInL2LendFactory.sol/VineInL2LendFactory.json");
const VineInETHLendFactoryABI=require("../artifacts/contracts/hook/aave/VineInETHLendFactory.sol/VineInETHLendFactory.json");

const Set=require('../set.json');


async function main() {
    const [owner, manager, testUser1, testUser3 ,testUser4] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    console.log("manager:",manager.address);
    console.log("testUser1:",testUser1.address);
    console.log("testUser3:",testUser3.address);
    console.log("testUser4:",testUser4.address);

    const provider = ethers.provider;
    const network = await provider.getNetwork();
    const chainId = network.chainId;
    console.log("Chain ID:", chainId);

    let currentUser = testUser3;

    async function sendETH(toAddress, amountInEther) {
        const amountInWei = ethers.parseEther(amountInEther);
        const tx = {
            to: toAddress,
            value: amountInWei,
        };
        const transactionResponse = await owner.sendTransaction(tx);
        await transactionResponse.wait();
        console.log("Transfer eth success");
    }

    await sendETH(currentUser.address, "0.03");


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

    if(chainId === 43113n){
        const UserGovernance=new ethers.Contract(config.Deployed.Governance, GovernanceABI.abi, currentUser);

        //30 days
        const register = await UserGovernance.register(
            0,
            1000,
            304800n,
            604800n,
            currentUser.address
        );
        await register.wait();
        console.log("register success");

        const lastestId=await UserGovernance.ID();
        console.log("lastestId:", lastestId);
        const ID=lastestId - 1n;

        const marketInfo = await UserGovernance.getMarketInfo(ID);
        console.log("marketInfo:", marketInfo);

        const testUserFactory=new ethers.Contract(config.Deployed.VineAaveV3LendMain02Factory, VineAaveV3LendMain02FactoryABI.abi, currentUser);
        const createMainMarket = await testUserFactory.createMarket(manager.address, manager.address, "Vine USDC Share" + `${ID}`, "V-USDC-SHARE" + `${ID}`);
        await createMainMarket.wait();
        console.log("createMainMarket success");
        const getUserIdToHook=await testUserFactory.getUserIdToHook(ID);
        console.log("Hook:", getUserIdToHook);
        config.Deployed[`VineAaveV3LendMain02Hook${ID}`]=getUserIdToHook;
    }else if(chainId === 11155420n || chainId === 84532n || chainId === 421614n){
        const UserGovernance=new ethers.Contract(config.Deployed.VineHookCenter, VineHookCenterABI.abi, currentUser);
        const register = await UserGovernance.register(0);
        await register.wait();
        console.log("register success");
        
        const lastestId=await UserGovernance.ID();
        console.log("lastestId:", lastestId);
        const ID=lastestId - 1n;

        const marketInfo = await UserGovernance.getMarketInfo(ID);
        console.log("marketInfo:", marketInfo);

        const testUserFactory=new ethers.Contract(config.Deployed.VineInL2LendFactory, VineInL2LendFactoryABI.abi, currentUser);
        const createMainMarket = await testUserFactory.createMarket(manager.address, manager.address);
        await createMainMarket.wait();
        console.log("createMainMarket success");
        const getUserIdToHook=await testUserFactory.getUserIdToHook(ID);
        console.log("Hook:", getUserIdToHook);
        config.Deployed[`VineInL2LendHook${ID}`]=getUserIdToHook;
    }else if(chainId === 11155111n){
      const UserGovernance=new ethers.Contract(config.Deployed.VineHookCenter, VineHookCenterABI.abi, currentUser);
      const lastestId=await UserGovernance.ID();
      console.log("lastestId:", lastestId);
      const ID=lastestId - 1n;

      const marketInfo = await UserGovernance.getMarketInfo(ID);
      console.log("marketInfo:", marketInfo);
      const register = await UserGovernance.register(0);
      await register.wait();
      console.log("register success");

        const testUserFactory=new ethers.Contract(config.Deployed.VineInL2LendFactory, VineInETHLendFactoryABI.abi, currentUser);
        const govern=await testUserFactory.govern();
        console.log("govern:", govern);
        const createMainMarket = await testUserFactory.createMarket(manager.address, manager.address);
        await createMainMarket.wait();
        console.log("createMainMarket success");
        const getUserIdToHook=await testUserFactory.getUserIdToHook(ID);
        console.log("Hook:", getUserIdToHook);
        config.Deployed[`VineInETHLendHook${ID}`]=getUserIdToHook;
    }else{
        throw("Not chain id");
    }

    const setPath = "./set.json";
    const currentSet = JSON.parse(fs.readFileSync(setPath, "utf8"));
    currentSet[networkName] = config;
    fs.writeFileSync(setPath, JSON.stringify(currentSet, null, 2));
    console.log("set.json updated");


}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});