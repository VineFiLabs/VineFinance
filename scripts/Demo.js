const hre = require("hardhat");

const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const WETHABI = require("../artifacts/contracts/WETH.sol/WETH9.json");
const DemoABI = require("../artifacts/contracts/demo/Demo.sol/Demo.json");

async function main() {
  const [owner, manager] = await hre.ethers.getSigners();
  console.log("owner:", owner.address);
  console.log("manager:", manager.address);
  const provider = ethers.provider;
  const network = await provider.getNetwork();
  const chainId = network.chainId;
  console.log("Chain ID:", chainId);

  const arbUSDC = "0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d";
  const arbAUSDC = "0x460b97BD498E1157530AEb3086301d5225b91216";
  const arbWETH = "0x1dF462e2712496373A347f8ad10802a5E95f053D";
  const arbWETHVToken = "0x372eB464296D8D78acaa462b41eaaf2D3663dAD3";
  const arbWrappedTokenGateway = "0x20040a64612555042335926d72B4E5F667a67fA1";
  const arbL2Encode = "0x2E45e7dCD1e94d8edf1605FfF4602912FDC662bC";
  const arbPool = "0xBfC91D59fdAA134A4ED45f7B584cAf96D7792Eff";

  const arb_uniswapV3Router = "0x101F443B4d1b059569D643917553c771E1b9663E";

  const FakeETHAddress = "0xf6B8b7544217876DcFb0d0dFcfD5AF953A8A234a";

    // const demo = await ethers.getContractFactory("Demo");
    // const Demo = await demo.deploy(
    //   arbL2Encode
    // );
    // const DemoAddress = await Demo.target;
    // console.log("Demo Address:", DemoAddress);

    const DemoAddress="0xcDA2cA46B8f85FE45E98Cfaf2d999eAD5eA729D9";
    const Demo=new ethers.Contract(DemoAddress, DemoABI.abi, owner);

  const USDCContract = new ethers.Contract(arbUSDC, ERC20ABI.abi, owner);
  const AUSDCContract = new ethers.Contract(arbAUSDC, ERC20ABI.abi, owner);

  async function Approve(token, Spender, Amount) {
    try {
      const Token = new ethers.Contract(token, ERC20ABI.abi, owner);
      const allowance = await Token.allowance(owner.address, Spender);
      if (allowance < Amount) {
        const approve = await Token.approve(
          Spender,
          ethers.parseEther("10000000")
        );
        const approvetx = await approve.wait();
        console.log("Approve success:", approvetx.hash);
      }
    } catch (e) {
      console.log("Approve fail:", e);
    }
  }
  const amount = ethers.parseEther("100000000");
  await Approve(arbUSDC, DemoAddress, amount);
  // await Approve(arbAUSDC, DemoAddress, amount);
  await Approve(FakeETHAddress, DemoAddress, amount)

  //swap
  const V3SwapParams={
    fee: 500,
    deadline: 60,
    sqrtPriceLimitX96: 0,
    tokenIn: arbUSDC,
    tokenOut: FakeETHAddress,
    amountIn: 100000n,
    amountOutMinimum: 0,
    v3Router: arb_uniswapV3Router
  };
  const v3Swap=await Demo.v3Swap(
    V3SwapParams
  );
  const v3SwapTx=await v3Swap.wait();
  console.log("v3Swap Tx:", v3SwapTx.hash);

  // const inL2Supply=await Demo.inL2Supply(
  //   arbPool,
  //   arbUSDC,
  //   amount
  // );
  // const inL2SupplyTx=await inL2Supply.wait();
  // console.log("InL2Supply Tx:", inL2SupplyTx.hash);

  // const borrowAmount=ethers.parseEther("0.0000001");
  // const inL2Borrow=await Demo.inL2Borrow(
  //   arbWETH,
  //   arbWETHVToken,
  //   arbWrappedTokenGateway,
  //   arbPool,
  //   borrowAmount,
  //   2
  // );
  // const inL2BorrowTx=await inL2Borrow.wait();
  // console.log("inL2Borrow Tx:", inL2BorrowTx.hash);

  // const WETH=new ethers.Contract(arbWETH, WETHABI.abi, owner);
  // const WETHAmount1=await WETH.balanceOf(owner.address);
  // console.log("WETH Amount:", WETHAmount1);
  // if(WETHAmount1 < borrowAmount){
  //   const depositeETH=await WETH.deposit({value: ethers.parseEther("0.0001")});
  //   const depositeETHTx=await depositeETH.wait();
  //   console.log("depositeETH:", depositeETHTx.hash);
  // }

  // const WETHAmount2=await WETH.balanceOf(owner.address);
  // console.log("WETH Amount:", WETHAmount2);

  // const repayAmount = ethers.parseEther("0.00000012");
  // await Approve(arbWETH, DemoAddress, repayAmount);

  // const inL2Repay=await Demo.inL2Repay(
  //   arbWETH,
  //   arbPool,
  //   repayAmount,
  //   2
  // );
  // const inL2RepayTx=await inL2Repay.wait();
  // console.log("inL2Repay:", inL2RepayTx.hash);

  // const ausdcBalance = await AUSDCContract.balanceOf(DemoAddress);
  // console.log("AUSDC balance:", ausdcBalance);

  // const inL2Withdraw = await Demo.inL2Withdraw(arbPool, arbAUSDC, ausdcBalance);
  // const inL2WithdrawTx = await inL2Withdraw.wait();
  // console.log("inL2Withdraw tx:", inL2WithdrawTx.hash);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
