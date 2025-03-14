const hre = require("hardhat");

//avax fuji Governance: 0x914FAd29EF54e3923278c5994Ee84fc2C747c482
//avax fuji CoreCrossCenter: 0x7Fa010f6946442b4d92a6Ea5bBAD063eA70d184C

//arb sepolia VineHookCenter: 0x4C6927CDAD54f0dDB978cE925AC7BBfe595B36C8
//arb sepolia CrossCenter: 0x2f660fe3a0D4A4e8CBa41E31Bd921442b9446aCd

//op sepolia VineHookCenter Address: 0x34D7CD4fd9F27683b36826ED4617125891A62463
//op sepolia CrossCenter Address: 0x52A5C2F449100426CAAAe7ce8C35534cB9B65cD0

//base sepolia VineHookCenter Address: 0x38Eb163609F028De1C95Ae3F00F246314168b9Bb
//base sepolia CrossCenter Address: 0xCD5F93F142323dA16d71c6309d854852Fe3eE3D3

// owner: 0xaE67336f06B10fbbb26F31d31AbEA897290109B9
// manager: 0xE95CC1a820F2152D1d928772bBf88E2c4A8EcED9

const GovernanceABI = require("../artifacts/contracts/core/Governance.sol/Governance.json");
const VineHookCenterABI = require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
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

    // await sendETH(manager.address, "0.03");

    const feeManager = owner.address;
    const caller = manager.address;

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

    config.timestamp = new Date().toISOString();
    
    let Governance;
    let GovernanceAddress;
    let CoreCrossCenterAddress;
    let CrossCenterAddress;
    let thisGovernanceABI;
    let thisCrossCenter;
    if (chainId === 43113n) {
        thisGovernanceABI = GovernanceABI.abi;
        const governance = await ethers.getContractFactory("Governance");
        Governance = await governance.deploy(
          owner.address, 
          manager.address, 
          feeManager, 
          caller,
          config.WormholeRelayer
        );
        GovernanceAddress = await Governance.target;
        console.log("Governance Address:", GovernanceAddress);
        config.Deployed.Governance = GovernanceAddress; 

        const coreCrossCenter = await ethers.getContractFactory("CoreCrossCenter");
        const CoreCrossCenter = await coreCrossCenter.deploy(
          owner.address, 
          manager.address, 
          GovernanceAddress, 
          config.USDC, 
          config.TokenMessenger, 
          config.MessageTransmitter
        );
        CoreCrossCenterAddress = await CoreCrossCenter.target;
        console.log("Core CrossCenter Address:", CoreCrossCenterAddress);
        config.Deployed.CoreCrossCenter = CoreCrossCenterAddress;
        thisCrossCenter = CoreCrossCenterAddress;
    } else{
        thisGovernanceABI = VineHookCenterABI.abi;
        const governance = await ethers.getContractFactory("VineHookCenter");
        Governance = await governance.deploy(owner.address, manager.address, caller);
        GovernanceAddress = await Governance.target;
        console.log("VineHookCenter Address:", GovernanceAddress);
        config.Deployed.VineHookCenter = GovernanceAddress;

        const crossCenter = await ethers.getContractFactory("CrossCenter");
        const CrossCenter = await crossCenter.deploy(
          owner.address, 
          manager.address, 
          GovernanceAddress, 
          config.TokenMessenger, 
          config.MessageTransmitter
        );
        CrossCenterAddress = await CrossCenter.target;
        console.log("CrossCenter Address:", CrossCenterAddress);
        config.Deployed.CrossCenter = CrossCenterAddress;
        thisCrossCenter = CrossCenterAddress;
    }

    const managerGovernance = new ethers.Contract(GovernanceAddress, thisGovernanceABI, manager);

    const changeCrossCenter = await managerGovernance.changeCrossCenter(0, thisCrossCenter);
    await changeCrossCenter.wait();
    console.log("changeCrossCenter success");

    if(chainId === 11155420n || chainId === 421614n || chainId === 84532n){
        const changeL2Encode = await managerGovernance.changeL2Encode(config.L2Encode);
        await changeL2Encode.wait();
        console.log("changeL2Encode success");
    }

    if (chainId === 43113n) {
        const register = await managerGovernance.register(
          0,
          500n,
          432000n,
          864000n,
          manager.address
        );
        await register.wait();
        console.log("register success");
    } else{
        const register = await managerGovernance.register(0);
        await register.wait();
        console.log("register success");
    }

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