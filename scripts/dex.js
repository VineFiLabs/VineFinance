const hre = require("hardhat");

const ERC20ABI = require("../artifacts/contracts/TestToken.sol/TestToken.json");
const VineUniswapCoreABI = require("../artifacts/contracts/hook/uniswap/VineUniswapV3Core.sol/VineUniswapV3Core.json");

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

  const governance = "0x4F01FC3e6dFd0F9c2238DCd1f0048161db166f6f";
  const arb_nonfungiblePositionManager = "0x6b2937Bde17889EDCf8fbD8dE31C3C2a70Bc4d65";
  const arb_factory = "0x248AB79Bbb9bC29bB72f7Cd42F17e054Fc40188e";
  const arb_uniswapV3Router = "0x101F443B4d1b059569D643917553c771E1b9663E";
  const arbUSDCAddress = "0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d";

  const USDC = new ethers.Contract(arbUSDCAddress, ERC20ABI.abi, owner);

  // const vineUniswapCore = await ethers.getContractFactory("VineUniswapCore");
  // const VineUniswapCore = await vineUniswapCore.deploy(
  //     owner.address,
  //     manager.address,
  //     governance,
  //     0
  // );
  // const VineUniswapCoreAddress = await VineUniswapCore.target;
  // console.log("VineUniswapCore Address:", VineUniswapCoreAddress);

  //   const fakeETH = await ethers.getContractFactory("TestToken");
  //   const FakeETH = await fakeETH.deploy("Fake ETH", "FakeETH", 18);
  //   const FakeETHAddress = await FakeETH.target;
  //   console.log("FakeETH Address:", FakeETHAddress);

  const FakeETHAddress = "0xf6B8b7544217876DcFb0d0dFcfD5AF953A8A234a";
  const FakeETH = new ethers.Contract(FakeETHAddress, ERC20ABI.abi, owner);

  const VineUniswapCoreAddress = "0x7d1F07C3C6b0b4f6426972957995eA0DdB878Aea";
  const VineUniswapCore = new ethers.Contract(
    VineUniswapCoreAddress,
    VineUniswapCoreABI.abi,
    manager
  );

  const approveMax = ethers.parseEther("100000000000");
  const minAllowance = ethers.parseEther("100000");
  async function Approve(token, spender) {
    try {
      const ERC20Contract = new ethers.Contract(token, ERC20ABI.abi, owner);
      const allowance = await ERC20Contract.allowance(owner.address, spender);
      if (allowance <= minAllowance) {
        const usdcApprove = await ERC20Contract.approve(spender, approveMax);
        await usdcApprove.wait();
        console.log("Approve success");
      } else {
        console.log("Not approve");
      }
    } catch (e) {
      console.log("Approve fail");
    }
  }
  await Approve(arbUSDCAddress, VineUniswapCoreAddress);
  await Approve(FakeETHAddress, VineUniswapCoreAddress);

  const arbUSDCBalance = await USDC.balanceOf(owner.address);
  console.log("arbUSDCBalance:", arbUSDCBalance);

  const fakeETHBalance = await FakeETH.balanceOf(owner.address);
  console.log("fakeETHBalance:", fakeETHBalance);

  // const transferFakeETH = await FakeETH.transfer(VineUniswapCoreAddress, ethers.parseEther("50"));
  // const transferFakeETHTx = await transferFakeETH.wait();
  // console.log("transferFakeETH hash:", transferFakeETHTx.hash);

  async function CreateAndInit(poolFee, token0, token1, sqrtPriceX96) {
    try {
      const pool = await VineUniswapCore.getV3Pool(
        arb_factory,
        token0,
        token1,
        poolFee
      );
      console.log("pool:", pool);
      const CreatePoolAndInit = {
        poolInitAddress: arb_nonfungiblePositionManager,
        token0: token0,
        token1: token1,
        poolFee: poolFee,
        sqrtPriceX96: sqrtPriceX96,
      };
      const createPool = await VineUniswapCore.createPool(CreatePoolAndInit);
      const createPoolTx = await createPool.wait();
      console.log("createPool:", createPoolTx.hash);
    } catch (e) {
      console.log("CreateAndInit", e);
    }
  }

  //AddLiquidity
  async function MintNewPosition(
    poolFee,
    token0,
    token1,
    tickLower,
    tickUpper,
    amount0,
    amount1,
    sqrtPriceX96
  ) {
    try {
      const MintNewPositionParams1 = {
        nonfungiblePositionManager: arb_nonfungiblePositionManager,
        token0: token0,
        token1: token1,
        tickLower: tickLower,
        tickUpper: tickUpper,
        poolFee: poolFee,
        token0Amount: amount0,
        token1Amount: amount1,
      };
      await CreateAndInit(poolFee, token0, token1, sqrtPriceX96);
      const mintNewPosition = await VineUniswapCore.mintLiquidityPool(
        MintNewPositionParams1
      );
      const mintNewPositionTx = await mintNewPosition.wait();
      console.log("mintNewPosition tx:", mintNewPositionTx.hash);
    } catch (e) {
      console.log("mintNewPosition fail:", e);
    }
  }

  async function CreateAndMintLiquidity(
    poolFee,
    token0,
    token1,
    tickLower,
    tickUpper,
    amount0,
    amount1,
    sqrtPriceX96
  ) {
    const CreatePoolAndInit = {
      poolInitAddress: arb_nonfungiblePositionManager,
      token0: token0,
      token1: token1,
      poolFee: poolFee,
      sqrtPriceX96: sqrtPriceX96,
    };
    const MintNewPositionParams = {
      nonfungiblePositionManager: arb_nonfungiblePositionManager,
      token0: token0,
      token1: token1,
      tickLower: tickLower,
      tickUpper: tickUpper,
      poolFee: poolFee,
      token0Amount: amount0,
      token1Amount: amount1,
    };
    try {
      const createAndMintLiquidity =
        await VineUniswapCore.createAndMintLiquidity(
          CreatePoolAndInit,
          MintNewPositionParams
        );
      const createAndMintLiquidityTx = await createAndMintLiquidity.wait();
      console.log("createAndMintLiquidity tx:", createAndMintLiquidityTx.hash);
    } catch (e) {
      console.log("CreateAndMintLiquidity fail:", e);
    }
  }

  const getTokenContracts = await VineUniswapCore.getTokenContracts(
    arbUSDCAddress,
    FakeETHAddress
  );
  console.log("getTokenContracts:", getTokenContracts);
  const tokenA = getTokenContracts[0];

  const pool = await VineUniswapCore.getV3Pool(
    arb_factory,
    FakeETHAddress,
    arbUSDCAddress,
    500
  );
  console.log("pool:", pool);

  //eth-usdc 1eth : 3500usdc
  //放入 ethers.parseEther("0.0001") , 0.35*10**6
  // let amountAIn;
  // let amountBIn;
  // if (tokenA === arbUSDCAddress) {
  //   amountAIn = 35000n;
  //   amountBIn = ethers.parseEther("0.0001");
  // } else {
  //   amountAIn = ethers.parseEther("0.0001");
  //   amountBIn = 35000n;
  // }

    // await CreateAndMintLiquidity(
    //   500,
    //   arbUSDCAddress,
    //   FakeETHAddress,
    //   -887200,
    //   887200,
    //   35000n,
    //   ethers.parseEther("0.0001"),
    //   1991447441458989793028435463n
    // );

    // await MintNewPosition(
    //   500,
    //   arbUSDCAddress,
    //   FakeETHAddress,
    //   -887200,
    //   887200,
    //   35000n,
    //   ethers.parseEther("0.0001"),
    //   1991447441458989793028435463n
    // );

  const v3LiquidityTokenIdsLength=await VineUniswapCore.v3LiquidityTokenIdsLength();

  const tokenId = await VineUniswapCore.indexV3LiquidityTokenIds(v3LiquidityTokenIdsLength - 1n);
  console.log("tokenId:", tokenId);

  // const v3LiquidityInfo = await VineUniswapCore.getV3LiquidityInfo(tokenId);
  // console.log("v3LiquidityInfo:", v3LiquidityInfo);

  // const V3LiquidityParams = {
  //   deadline: 30n,
  //   nonfungiblePositionManager: arb_nonfungiblePositionManager,
  //   tokenId: tokenId,
  //   tokenA: arbUSDCAddress,
  //   tokenB: FakeETHAddress,
  //   amountAIn: 35000n,
  //   amountBIn: ethers.parseEther("0.0001"),
  //   amountAMin: 0n,
  //   amountBMin: 0n,
  // };

  // const addV3Liquidity = await VineUniswapCore.addV3Liquidity(
  //   V3LiquidityParams
  // );
  // const addV3LiquidityTx = await addV3Liquidity.wait();
  // console.log("addV3Liquidity success:", addV3LiquidityTx.hash);

  // const removeV3LiquidityParams = {
  //   deadline: 30n,
  //   nonfungiblePositionManager: arb_nonfungiblePositionManager,
  //   nftAddress: "0x6b2937Bde17889EDCf8fbD8dE31C3C2a70Bc4d65",
  //   tokenId: tokenId,
  //   liquidity: 100n,
  //   amountAMin: 0n,
  //   amountBMin: 0n,
  // };

  // const removeV3Liquidity = await VineUniswapCore.removeV3Liquidity(
  //   removeV3LiquidityParams
  // );
  // const removeV3LiquidityTx = await removeV3Liquidity.wait();
  // console.log("removeV3Liquidity success:", removeV3LiquidityTx.hash);

  // const collectAllFees = await VineUniswapCore.collectAllFees(tokenId, arb_nonfungiblePositionManager);
  // const  collectAllFeesTx = await collectAllFees.wait();
  // console.log("collectAllFeesTx success:", collectAllFeesTx.hash);


  const v3LiquidityInfoAfter = await VineUniswapCore.getV3LiquidityInfo(tokenId);
  console.log("v3LiquidityInfoAfter:", v3LiquidityInfoAfter);
  

  //v3Swap
  const ZeroAddress="0x0000000000000000000000000000000000000000";
  const V3SwapParams = {
    fee: 500,
    deadline: 60,
    sqrtPriceLimitX96: 0,
    tokenIn: FakeETHAddress,
    tokenOut: arbUSDCAddress,
    sender: ZeroAddress,
    amountIn: 100000000000n,
    amountOutMinimum: 0,
    v3Router: arb_uniswapV3Router
  };
  const v3Swap=await VineUniswapCore.v3Swap(
    V3SwapParams
  );
  const v3SwapTx=await v3Swap.wait();
  console.log(v3SwapTx.hash);



}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
