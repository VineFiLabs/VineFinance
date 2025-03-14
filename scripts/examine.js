const hre = require("hardhat");

const GovernanceABI=require("../artifacts/contracts/core/Governance.sol/Governance.json");

async function main() {
    const [owner, manager] = await hre.ethers.getSigners();
    console.log("owner:",owner.address);
    console.log("manager:",manager.address);
    const provider = ethers.provider;

    const GovernanceAddress = "0xb1ABE6a9fe2C1174B6Acd18B9D03bD886C643aCD";
    const Governance = new ethers.Contract(GovernanceAddress, GovernanceABI.abi, manager);

    const examine = await Governance.examine(0, true);
    await examine.wait();
    console.log("Examine success");

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});