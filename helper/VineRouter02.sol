// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IGovernance} from "../interfaces/core/IGovernance.sol";
import {IVineAaveV3LendMain02} from "../interfaces/IVineAaveV3LendMain02.sol";
import "../libraries/VineLib.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineRouter02 is Ownable{   
    using SafeERC20 for IERC20;

    IGovernance public Governance;
    address public usdc;

    constructor(address _Governance, address _usdc)Ownable(msg.sender){
        Governance = IGovernance(_Governance);
        usdc = _usdc;
    }

    mapping(address => mapping(uint32 => address[])) private _UserJoinGroup;

    mapping(address => uint32) private _UserLastPage;

    mapping(address => mapping(address => bool)) private _UserIfJoin;

    event depositeEvent(address indexed user, bytes resultData);

    function changeUSDCAddress(address newUsdc)external onlyOwner{
        usdc = newUsdc;
    }

    function deposite(
        uint64 amount,
        address coreLendMarket,
        address l2Pool
    ) external {
        IERC20(usdc).transferFrom(msg.sender, address(this), amount);
        IERC20(usdc).approve(coreLendMarket, amount);
        bytes memory payload = abi.encodeCall(
            IVineAaveV3LendMain02(coreLendMarket).deposite,
            (amount, usdc, l2Pool, msg.sender)
        );
        (bool suc, bytes memory data)=coreLendMarket.call{value: 0}(payload);
        require(suc, "Call deposite fail");
        if (_UserIfJoin[msg.sender][coreLendMarket] == false) {
            _UserJoinGroup[msg.sender][_UserLastPage[msg.sender]].push(
                coreLendMarket
            );
            _UserIfJoin[msg.sender][coreLendMarket] = true;
        }
        if (_UserJoinGroup[msg.sender][_UserLastPage[msg.sender]].length >= 10) {
            _UserLastPage[msg.sender]++;
        }
        emit depositeEvent(msg.sender, data);
    }
    
    function _getMarketInfo(uint256 _id)private view returns(IGovernance.MarketInfo memory newMarketInfo){
        newMarketInfo = Governance.getMarketInfo(_id);
    }

    function _getFeeAmount(uint16 _feeRate, uint64 _totalDepositeAmount, address _coreLendMarket)private view returns(uint256 feeAmount){
        feeAmount = VineLib._feeAmount(
            _feeRate, 
            _totalDepositeAmount, 
            getUserTokenBalance(usdc, _coreLendMarket)
        );
    }

    function getUserFinallyAmount(uint256 id, address user)external view returns(uint256 userFinallyAmount){
        IGovernance.MarketInfo memory newMarketInfo = _getMarketInfo(id);
        address coreLendMarket = newMarketInfo.coreLendMarket;
        userFinallyAmount = VineLib._getUserFinallyAmount(
            newMarketInfo.curatorFee, 
            newMarketInfo.protocolFee, 
            getUserSupplyToHookAmount(coreLendMarket, user), 
            getMarketTotalDepositeAmount(coreLendMarket), 
            getUserTokenBalance(coreLendMarket, user),
            getUserTokenBalance(usdc, user),
            getMarketTotalSupply(coreLendMarket)
        );
    }

    function getFeeData(uint256 id)external view returns(uint256, uint256, uint256){
        IGovernance.MarketInfo memory newMarketInfo = _getMarketInfo(id);
        address coreLendMarket = newMarketInfo.coreLendMarket;
        uint64 depositeTotalAmount = getMarketTotalDepositeAmount(coreLendMarket);
        uint256 curatorFee = _getFeeAmount(
            newMarketInfo.curatorFee, 
            depositeTotalAmount, 
            coreLendMarket
        );
        uint256 protocolFee = _getFeeAmount(
            newMarketInfo.protocolFee, 
            depositeTotalAmount, 
            coreLendMarket
        );
        uint256 totalFee = curatorFee + protocolFee;
        return (curatorFee, protocolFee, totalFee);
    }

    function getUserSupplyToHookAmount(address _coreLendMarket, address _user)public view returns(uint64 supplyAmount){
        supplyAmount = IVineAaveV3LendMain02(_coreLendMarket).getUserSupply(_user).pledgeAmount;
    }

    function getMarketTotalSupply(address _coreLendMarket)public view returns(uint256 totalSupply){
        totalSupply = IVineAaveV3LendMain02(_coreLendMarket).totalSupply();
    }

    function getMarketTotalDepositeAmount(address _coreLendMarket)public view returns(uint64 totalDepositeAmount){
        totalDepositeAmount = IVineAaveV3LendMain02(_coreLendMarket).depositeTotalAmount();
    }

    function getMarketFinallyAmount(address _coreLendMarket)public view returns(uint256 finallyAmount){
        finallyAmount = IVineAaveV3LendMain02(_coreLendMarket).finallyAmount();
    }

    function getUserTokenBalance(address token, address account)public view returns(uint256 accountTokenBalance){
        accountTokenBalance = IERC20(token).balanceOf(account);
    }

    function getUserJoinGroup(address user, uint32 indexPage)public view returns(address[] memory){
        uint256 pageLength = _UserJoinGroup[user][indexPage].length;
        address[] memory newJoinGroup = new address[](pageLength);
        unchecked {
            for(uint256 i; i<pageLength; i++){
                newJoinGroup[i] = _UserJoinGroup[user][indexPage][i];
            }
        }
        return newJoinGroup;
    }

    function getUserLastPage(address user)public view returns(uint32 lastPage){
        lastPage = _UserLastPage[user];
    }

    function getUserIfJoin(address user, address coreLendMarket)public view returns(bool ifJoin){
        ifJoin = _UserIfJoin[user][coreLendMarket];
    }


}