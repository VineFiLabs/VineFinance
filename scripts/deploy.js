const hre = require("hardhat");

// owner: 0xaE67336f06B10fbbb26F31d31AbEA897290109B9
// manager: 0xE95CC1a820F2152D1d928772bBf88E2c4A8EcED9

const GovernanceABI = require("../artifacts/contracts/core/Governance.sol/Governance.json");
const VineHookCenterABI = require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineConfig1ABI = require("../artifacts/contracts/core/VineConfig1.sol/VineConfig1.json");
const RewardPoolABI = require("../artifacts/contracts/reward/RewardPool.sol/RewardPool.json");
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

    const ZERO_ADDRESS="0x0000000000000000000000000000000000000000";

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

    const vineConfig1 = await ethers.getContractFactory("VineConfig1");
        const VineConfig1 = await vineConfig1.deploy(
          owner.address, 
          manager.address
        );
    const VineConfig1Address = await VineConfig1.target;
    // const VineConfig1Address = config.Deployed.VineConfig1;
    console.log("VineConfig1Address:", VineConfig1Address);
    config.Deployed.VineConfig1 = VineConfig1Address; 
    
    const managerVineConfig = new ethers.Contract(VineConfig1Address, VineConfig1ABI.abi, manager);

    if (chainId === 43113n) {
        const setCalleeInfo= await managerVineConfig.setCalleeInfo(
          0,
          config.USDC,
          config.AUSDC,
          config.AavePool,
          ZERO_ADDRESS,
          ZERO_ADDRESS
        );
        const setCalleeInfoTx = await setCalleeInfo.wait();
        console.log("setCalleeInfo tx:", setCalleeInfoTx.hash);

        thisGovernanceABI = GovernanceABI.abi;
        const governance = await ethers.getContractFactory("Governance");
        Governance = await governance.deploy(
          owner.address, 
          manager.address, 
          caller,
          config.WormholeRelayer
        );
        GovernanceAddress = await Governance.target;
        // GovernanceAddress = "";
        Governance = new ethers.Contract(GovernanceAddress, thisGovernanceABI, owner);
        console.log("Governance Address:", GovernanceAddress);
        config.Deployed.Governance = GovernanceAddress; 

        // const rewardPool = await ethers.getContractFactory("RewardPool");
        // const RewardPool = await rewardPool.deploy(GovernanceAddress, owner.address);
        // const RewardPoolAddress = await RewardPool.target;
        const RewardPoolAddress = config.Deployed.RewardPool;
        const RewardPool = new ethers.Contract(RewardPoolAddress, RewardPoolABI.abi, owner);
        console.log("RewardPool address:", RewardPoolAddress);
        config.Deployed.RewardPool = RewardPoolAddress; 

        const changeGovern = await RewardPool.changeGovern(GovernanceAddress);
        const changeGovernTx = await changeGovern.wait();
        console.log("changeGovern tx:", changeGovernTx.hash);

        const vineVaultCoreFactory = await ethers.getContractFactory("VineVaultCoreFactory");
        const VineVaultCoreFactory = await vineVaultCoreFactory.deploy(
          GovernanceAddress
        );
        const VineVaultCoreFactoryAddress = await VineVaultCoreFactory.target;
        // const VineVaultCoreFactoryAddress = "";
        console.log("VineVaultCoreFactoryAddress:", VineVaultCoreFactoryAddress);
        config.Deployed.VineVaultCoreFactory = VineVaultCoreFactoryAddress; 

        const setVineConfig = await Governance.setVineConfig(RewardPoolAddress, VineVaultCoreFactoryAddress, VineConfig1Address);
        const setVineConfigTx = await setVineConfig.wait();
        console.log("setVineConfig tx:", setVineConfigTx.hash);

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
        // CoreCrossCenterAddress = "";
        console.log("Core CrossCenter Address:", CoreCrossCenterAddress);
        config.Deployed.CoreCrossCenter = CoreCrossCenterAddress;

        const changeCrossCenter = await Governance.changeCrossCenter(0, CoreCrossCenterAddress);
        await changeCrossCenter.wait();
        console.log("changeCrossCenter success");

        thisCrossCenter = CoreCrossCenterAddress;
    } else if(chainId === 43113n){
      
    }else {
        const setCalleeInfo1= await managerVineConfig.setCalleeInfo(
          0,
          config.USDC,
          config.AUSDC,
          config.AavePool,
          ZERO_ADDRESS,
          ZERO_ADDRESS
        );
        const setCalleeInfo1Tx = await setCalleeInfo1.wait();
        console.log("setCalleeInfo1 tx:", setCalleeInfo1Tx.hash);

        thisGovernanceABI = VineHookCenterABI.abi;
        const governance = await ethers.getContractFactory("VineHookCenter");
        Governance = await governance.deploy(
          owner.address, 
          manager.address, 
          caller,
          config.WormholeRelayer
        );
        GovernanceAddress = await Governance.target;
        // GovernanceAddress = config.Deployed.VineHookCenter;

        const managerGovernance = new ethers.Contract(GovernanceAddress, thisGovernanceABI, manager);
        console.log("VineHookCenter Address:", GovernanceAddress);
        config.Deployed.VineHookCenter = GovernanceAddress;

        const vineVaultFactory = await ethers.getContractFactory("VineVaultFactory");
        const VineVaultFactory = await vineVaultFactory.deploy(
          GovernanceAddress
        );
        const VineVaultFactoryAddress = VineVaultFactory.target;
        // const VineVaultFactoryAddress = "";
        config.Deployed.VineVaultFactory = VineVaultFactoryAddress;
        console.log("VineVaultFactory Address:", VineVaultFactoryAddress);

        const setVineConfig = await Governance.setVineConfig(VineVaultFactoryAddress, VineConfig1Address);
        const setVineConfigTx = await setVineConfig.wait();
        console.log("setVineConfig tx:", setVineConfigTx.hash);

        const crossCenter = await ethers.getContractFactory("CrossCenter");
        const CrossCenter = await crossCenter.deploy(
          owner.address, 
          manager.address, 
          GovernanceAddress, 
          config.USDC,
          config.TokenMessenger, 
          config.MessageTransmitter
        );
        CrossCenterAddress = await CrossCenter.target;
        // CrossCenterAddress = "";
        console.log("CrossCenter Address:", CrossCenterAddress);
        config.Deployed.CrossCenter = CrossCenterAddress;
        
        const changeCrossCenter = await managerGovernance.changeCrossCenter(0, CrossCenterAddress);
        await changeCrossCenter.wait();
        console.log("changeCrossCenter success");

        thisCrossCenter = CrossCenterAddress;
    }
    
    const managerGovernance = new ethers.Contract(GovernanceAddress, thisGovernanceABI, manager);

    if(chainId === 84532n){
      const setCalleeInfo2= await managerVineConfig.setCalleeInfo(
        1,
        config.USDC,
        ZERO_ADDRESS,
        config.MorphoMarket,
        ZERO_ADDRESS,
        ZERO_ADDRESS
      );
      const setCalleeInfo2Tx = await setCalleeInfo2.wait();
      console.log("setCalleeInfo2 tx:", setCalleeInfo2Tx.hash);

      const setCalleeInfo3 = await managerVineConfig.setCalleeInfo(
        2,
        config.USDC,
        config.CompoundUSDCMarket,
        config.CompoundUSDCMarket,
        ZERO_ADDRESS,
        ZERO_ADDRESS
      );
      const setCalleeInfo3Tx = await setCalleeInfo3.wait();
      console.log("setCalleeInfo3 tx:", setCalleeInfo3Tx.hash);

      const getCalleeInfo1 = await managerVineConfig.getCalleeInfo(1);
      console.log("getCalleeInfo1:", getCalleeInfo1);

      const getCalleeInfo2 = await managerVineConfig.getCalleeInfo(2);
      console.log("getCalleeInfo2:", getCalleeInfo2);
    }



    if(chainId === 11155420n || chainId === 421614n || chainId === 84532n){
        const changeL2Encode = await managerGovernance.changeL2Encode(config.L2Encode);
        await changeL2Encode.wait();
        console.log("changeL2Encode success");
    }

    if (chainId === 43113n) {
      const RegisterParams = {
        crossCenterIndex: 0,
        feeRate: 500,
        domain: config.Domain,
        chooseDomains: [Set["Avalanche_fuji"].Domain, Set["Arbitrum_Sepolia"].Domain, Set["Base_Sepolia"].Domain, Set["Op_Sepolia"].Domain],
        bufferTime: 8660000n,
        endTime: 18000000n,
        thisFeeReceiver: owner.address,
        tokenName: "Vine Finance USDC SHARE1",
        tokenSymbol: "VINE-USDC-SHARE1"
      };
        const register = await managerGovernance.register(
          RegisterParams
        );
        const registerTx = await register.wait();
        console.log("register success:", registerTx.hash);
        const lastId = await managerGovernance.ID();
        const currentId = lastId-1n;
        const getMarketInfo = await managerGovernance.getMarketInfo(currentId);
        console.log("getMarketInfo:", getMarketInfo);
        config.Deployed["VineVault" + `${currentId}`]=getMarketInfo[8];
    } else{
        const register = await managerGovernance.register(
          0,
          config.Domain,
          [Set["Avalanche_fuji"].Domain, Set["Arbitrum_Sepolia"].Domain, Set["Base_Sepolia"].Domain, Set["Op_Sepolia"].Domain]
        );
        const registerTx = await register.wait();
        console.log("register success:", registerTx.hash);
        const lastId = await managerGovernance.ID();
        const currentId = lastId-1n;
        const getMarketInfo = await managerGovernance.getMarketInfo(currentId);
        console.log("getMarketInfo:", getMarketInfo);
        config.Deployed["VineVault" + `${currentId}`] = getMarketInfo[4];
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