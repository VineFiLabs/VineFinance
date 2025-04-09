const hre = require("hardhat");
const fs = require('fs');
const VineAaveV3LendMain02ABI = require("../artifacts/contracts/hook/aave/VineAaveV3LendMain02.sol/VineAaveV3LendMain02.json");
const Set=require('../set.json');

async function main() {
    const [owner, manager] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    console.log("manager:",manager.address);
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

    const VineAaveV3LendMain02Address = config.Deployed.VineAaveV3LendMain02Hook0;
    const VineAaveV3LendMain02Hook0 = new ethers.Contract(VineAaveV3LendMain02Address, VineAaveV3LendMain02ABI.abi, owner);
    const managerVineAaveV3LendMain02Hook0 = new ethers.Contract(VineAaveV3LendMain02Address, VineAaveV3LendMain02ABI.abi, manager);

    const updateFinallyAmount = await managerVineAaveV3LendMain02Hook0.updateFinallyAmount(0, 2);
    const updateFinallyAmountTx = await updateFinallyAmount.wait();
    console.log("updateFinallyAmount tx:", updateFinallyAmountTx.hash);

    const withdraw = await VineAaveV3LendMain02Hook0.withdraw(0, 2);
    const withdrawTx = await withdraw.wait();
    console.log("Withdraw tx:", withdrawTx.hash);

    const withdrawFee = await VineAaveV3LendMain02Hook0.withdrawFee(0, 2);
    const withdrawFeeTx = await withdrawFee.wait();
    console.log("WithdrawFee tx:", withdrawFeeTx.hash);

    const officeWithdraw = await VineAaveV3LendMain02Hook0.officeWithdraw(0, 2);
    const officeWithdrawTx = await officeWithdraw.wait();
    console.log("OfficeWithdraw tx:", officeWithdrawTx.hash);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});