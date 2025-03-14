const hre = require("hardhat");
const USDCABI = require("../json/USDC.json");
const messageTransmitterABI = require("../json/MessageTransmitter.json");
const { getAttestation } = require("./attestationservice");
const  CrossCenterABI = require("../artifacts/contracts/core/CrossCenter.sol/CrossCenter.json");

const { Wallet } = require("ethers");

require("dotenv").config();
async function main() {
    const [owner, manager] = await hre.ethers.getSigners();
    console.log("owner:", owner.address);
    console.log("manager:", manager.address);
    const AttestationStatus = {
        COMPLETE: 'complete',
        PENDING_CONFIRMATIONS: 'pending_confirmations',
    };

    const provider = ethers.provider;
    const network = await provider.getNetwork();
    const chainId = network.chainId;
    console.log("Chain ID:", chainId);

    const arbUSDC="0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d";
    const opUSDC="0x5fd84259d66Cd46123540766Be93DFE6D43130D7";
    const baseUSDC="0x036CbD53842c5426634e7929541eC2318f3dCF7e";
    const sepoliaUSDC="0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238";

    
    const arbTokenMessager = "0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5";
    const opTokenMessager = "0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5";
    const baseTokenMessager = "0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5";
    const sepoliaTokenMessager = "0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5";

    const arbMessageTransmitter = "0xaCF1ceeF35caAc005e15888dDb8A3515C41B4872";
    const opMessageTransmitter = "0x7865fAfC2db2093669d92c0F33AeEF291086BEFD";
    const baseMessageTransmitter = "0x7865fAfC2db2093669d92c0F33AeEF291086BEFD";
    const sepoliaMessageTransmitter = "0x7865fAfC2db2093669d92c0F33AeEF291086BEFD";

    const arbCrossCenterAddress="0xEc2D417D61bAf83e2244b3d58b76d1C882368507";  //arb sepolia
    const opCrossCenterCCTPAddress="0xcA43aA3b5d882840368d1e299f9B6d6eCD8fe443";  //op sepolia
    const baseCrossCenterCCTPAddress="0x210B1A76Ded6efA2846D85E91C0D67C439EfE811";  //base sepolia
    const sepoliaCrossCenterAddress="0x08F7e93ac2EE0508D59d9fd176a5b7Cb06D93948";  //sepolia

    let USDCAddress;
    let tokenMessagerAddress;
    let messageTransmitterAddress;
    let crossCenterAddress;
    if(chainId === 42161n || chainId === 421614n){
        USDCAddress=arbUSDC;
        tokenMessagerAddress=arbTokenMessager;
        messageTransmitterAddress=arbMessageTransmitter;
        crossCenterAddress = arbCrossCenterAddress;
    }else if(chainId === 10n || chainId === 11155420n){
        USDCAddress=opUSDC;
        tokenMessagerAddress=opTokenMessager;
        messageTransmitterAddress=opMessageTransmitter;
        crossCenterAddress = opCrossCenterCCTPAddress;
    }else if(chainId === 8453n || chainId === 84532n){
        USDCAddress=baseUSDC;
        tokenMessagerAddress=baseTokenMessager;
        messageTransmitterAddress=baseMessageTransmitter;
        crossCenterAddress = baseCrossCenterCCTPAddress;
    }else if(chainId === 1n || chainId === 11155111n){
        USDCAddress=sepoliaUSDC;
        tokenMessagerAddress=sepoliaTokenMessager;
        messageTransmitterAddress=sepoliaMessageTransmitter;
        crossCenterAddress = sepoliaCrossCenterAddress;
    }else{
        throw("Not chain id")
    }

    const CrossCenter=new ethers.Contract(crossCenterAddress,CrossCenterABI.abi,manager);


    const arbProvider = new ethers.JsonRpcProvider(process.env.Arbitrum_Api_Key);
    const arbSigner = new ethers.Wallet(
        process.env.PRIVATE_KEY,
        arbProvider
    );
    const MessageTransmitter = new ethers.Contract(messageTransmitterAddress, messageTransmitterABI, arbSigner);

    async function fetchPastEvents() {
        try {
            const hookAddress="0xAe6271f75b159e00203A8b9f97Dc3E3812d19468";
            const bytes32Address = await CrossCenter.addressToBytes32(hookAddress);
            const hookCrossRecord = await CrossCenter.getHookCrossRecord(bytes32Address);
            console.log("hookCrossRecord:",hookCrossRecord);
            const inputBlock = await hookCrossRecord.lastestBlock;
            console.log("inputBlock:",inputBlock);
            const resultMessage = await ARBMessageTransmitter.queryFilter('MessageSent', inputBlock, inputBlock + 200n);
            console.log("resultMessage:",resultMessage);
            const message = resultMessage[0].args[0];
            console.log("message result:", message);

            const messageHash = ethers.keccak256(message);
            console.log('messageHash:', messageHash);
            // const intervalId = setInterval(async () => {
            const attestationResponse = await getAttestation(messageHash);
            if (attestationResponse && attestationResponse.status === AttestationStatus.COMPLETE) {
                try{
                    let attestation=attestationResponse.message;
                    console.log("attestation:",attestation);
                }catch(e){
                    console.log("Attestation generate error:",e);
                }
            }else{
                console.log("Attestation generate...");
            }
        }catch(e){
            console.log("Error:", e);
        }
    }

    async function fetchPastEventsByHash(){
        try{
            const txHash = "0x84c80cc33836bea7523f15007109843595eb463efe60d133f26efe61381f82ce"; 
            const receipt = await provider.getTransactionReceipt(txHash);
            const logs = receipt.logs.filter(log => log.address === messageTransmitterAddress);
            console.log("logs:",logs);
            if (logs.length > 0) {
                const parsedLog = MessageTransmitter.interface.parseLog(logs[0]);
                console.log("message:", parsedLog.args[0]);
                const messageHash = ethers.keccak256(parsedLog.args[0]);
                console.log("messageHash:", messageHash);
                const attestationResponse = await getAttestation(messageHash);
                if (attestationResponse && attestationResponse.status === AttestationStatus.COMPLETE) {
                    try{
                        let attestation=attestationResponse.message;
                        console.log("attestation:",attestation);
                    }catch(e){
                        console.log("Attestation generate error:",e);
                    }
                }else{
                    console.log("Attestation generate...");
                }
            }else{
                console.log("No log found");
            }
        }catch(e){
            console.log("Error:", e);
        }
    }

    // await fetchPastEvents();

    // await fetchPastEventsByHash();

    setInterval(async () => {
            await fetchPastEventsByHash();
        }, 10000);

    
    // setInterval(async () => {
    //     await fetchPastEvents();
    // }, 25000);

    

}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});