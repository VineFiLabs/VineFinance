const hre = require("hardhat");

const GovernanceABI=require("../artifacts/contracts/core/Governance.sol/Governance.json");
const VineHookCenterABI=require("../artifacts/contracts/core/VineHookCenter.sol/VineHookCenter.json");
const VineAaveV3LendMainFactoryABI=require("../artifacts/contracts/hook/aave/VineAaveV3LendMainFactory.sol/VineAaveV3LendMainFactory.json");
const VineInL2LendFactoryABI=require("../artifacts/contracts/hook/aave/VineInL2LendFactory.sol/VineInL2LendFactory.json");
const VineInETHLendFactoryABI=require("../artifacts/contracts/hook/aave/VineInETHLendFactory.sol/VineInETHLendFactory.json");

//arb sepolia hook: 0x0333A3488a7576530dedFEB2fd36fC70C83A3998
//op sepolia hook: 0xa9EB447Ce68F9074B9e1A6cE43146cE433E3879D
//base sepolia hook: 0xA1d6461697B89111b1ab2F5D93E47Bc39Ca8df8d
//sepolia hook: 0xC6A4DD0d80DaA821eb034049e33be74ceF3E80D8


async function main() {
    const [owner, manager, testUser] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    console.log("manager:",manager.address);
    console.log("testUser:",testUser.address);
    const provider = ethers.provider;
    const network = await provider.getNetwork();
    const chainId = network.chainId;
    console.log("Chain ID:", chainId);

    const arbGovernance="0x72ba808fa4DeC8bDCBc914335fB4aEcAe2bc6351";  //arb sepolia
    const opVineHookCenter="0x87312772D8821f0EDEF7B8269951dd973B2ec285";  //op sepolia
    const baseVineHookCenter="0x5766799bBFEceFAdD90e7C706636B579A4c5Fe44";  //base sepolia
    const sepoliaVineHookCenter="0x7beDdf4DCe5eb5C1415BBA6D5BEB467C5e1984d4";  //sepolia

    const arbHookAddress = "0x47065dc0CcacB0acA9413Ec0Cfc8d95a6a8161fF";
    const opHookAddress = "0xC87d4f35Ea8CF5E0613800258DdBfDCfA49dBB16";
    const baseHookAddress = "0x0eC48B908572f8FCB0a2874AbB0E5Bb33e319B63";
    const sepoliaHookAddress = "0x1f27031D7965D6F03961CC8807040Dd41Dbe1E0b";

    if(chainId === 42161n || chainId === 421614n){
        const testUserGovernance=new ethers.Contract(arbGovernance, GovernanceABI.abi, testUser);
        const initialize = await testUserGovernance.initialize(arbHookAddress);
        await initialize.wait();
        console.log("initialize success");
    }else if(chainId === 10n || chainId === 11155420n){
        const testUserGovernance=new ethers.Contract(opVineHookCenter, VineHookCenterABI.abi, testUser);
        const initialize = await testUserGovernance.initialize(opHookAddress);
        await initialize.wait();
        console.log("initialize success");
    }else if(chainId === 8453n || chainId === 84532n){
        const testUserGovernance=new ethers.Contract(baseVineHookCenter, VineHookCenterABI.abi, testUser);
        const initialize = await testUserGovernance.initialize(baseHookAddress);
        await initialize.wait();
        console.log("initialize success");
    }else if(chainId === 1n || chainId === 11155111n){
        const testUserGovernance=new ethers.Contract(sepoliaVineHookCenter, VineHookCenterABI.abi, testUser);
        const initialize = await testUserGovernance.initialize(sepoliaHookAddress);
        await initialize.wait();
        console.log("initialize success");
    }else{
        throw("Not chain id")
    }

    

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});