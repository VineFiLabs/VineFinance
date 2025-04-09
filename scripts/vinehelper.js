const hre = require("hardhat");

const VineHelperABI = require("../artifacts/contracts/helper/VineHelper.sol/VineHelper.json");

const Set=require('../set.json');
const fs = require('fs'); 

async function main() {
    const [owner, manager] = await hre.ethers.getSigners();
    console.log("owner:", owner.address);
    console.log("manager:", manager.address);
    const provider = ethers.provider;
    const network = await provider.getNetwork();
    const chainId = network.chainId;
    console.log("Chain ID:", chainId);

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

    const vineHelper = await ethers.getContractFactory("VineHelper");
    const VineHelper = await vineHelper.deploy(config.Deployed.Governance, config.Deployed.VineRouter02);
    const VineHelperAddress = VineHelper.target;
    console.log("VineHelperAddress:", VineHelperAddress);

    // const VineHelperAddress = "0x3133b5BD3928b44C467461396bFB680AbbA71a11";
    // const VineHelper = new ethers.Contract(VineHelperAddress, VineHelperABI.abi, owner);

    // const changeConfig = await VineHelper.changeConfig(config.Deployed.Governance, config.Deployed.VineRouter02);
    // const changeConfigTx = await changeConfig.wait();
    // console.log("changeConfig Tx:", changeConfigTx.hash);
    const getMarketInfoList = await VineHelper.getMarketInfoList(0n);
    console.log("getMarketInfoList:", getMarketInfoList);

    const getUserSupplyToHookAmount = await VineHelper.getUserSupplyToHookAmount(0, owner.address);
    console.log("getUserSupplyToHookAmount:", getUserSupplyToHookAmount);

    const getUserFinallyAmount = await VineHelper.getUserFinallyAmount(0, owner.address);
    console.log("getUserFinallyAmount:", getUserFinallyAmount);


    const getUserMarketInfoList = await VineHelper.getUserMarketInfoList(
      owner.address,
      0
    );
    console.log("getUserMarketInfoList:", getUserMarketInfoList);

    config.Deployed.VineHeper = VineHelperAddress;

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