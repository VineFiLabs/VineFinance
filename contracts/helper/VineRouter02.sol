// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IGovernance} from "../interfaces/core/IGovernance.sol";
import {IVineConfig1} from "../interfaces/core/IVineConfig1.sol";
import {IVineAaveV3LendMain02} from "../interfaces/hook/aave/IVineAaveV3LendMain02.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineRouter02 is Ownable{   
    using SafeERC20 for IERC20;

    IGovernance public Governance;
    address public vineConfig;

    constructor(address _Governance, address _vineConfig)Ownable(msg.sender){
        Governance = IGovernance(_Governance);
        vineConfig = _vineConfig;
    }

    mapping(address => mapping(uint32 => uint256[])) private _UserJoinGroup;

    mapping(address => uint32) private _UserLastPage;

    mapping(address => mapping(uint256 => bool)) private _UserIfJoin;

    event depositeEvent(address indexed user, bytes resultData);

    function changeVineConfig(address _vineConfig) external onlyOwner {
        vineConfig = _vineConfig;
    }

    function changeGovern(address _Governance) external onlyOwner {
        Governance = IGovernance(_Governance);
    }

    function deposite(
        uint256 id,
        uint8 indexConfig,
        uint64 amount,
        address coreLendMarket
    ) external {
        address token = IVineConfig1(vineConfig).getCalleeInfo(indexConfig).mainToken;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(coreLendMarket, amount);
        bytes memory payload = abi.encodeCall(
            IVineAaveV3LendMain02(coreLendMarket).deposite,
            (id, indexConfig, amount, msg.sender)
        );
        (bool suc, bytes memory data)=coreLendMarket.call{value: 0}(payload);
        require(suc, "Call deposite fail");
        //clear approve
        IERC20(token).approve(coreLendMarket, 0);
        if (_UserIfJoin[msg.sender][id] == false) {
            _UserJoinGroup[msg.sender][_UserLastPage[msg.sender]].push(
                id
            );
            _UserIfJoin[msg.sender][id] = true;
        }
        if (_UserJoinGroup[msg.sender][_UserLastPage[msg.sender]].length >= 10) {
            _UserLastPage[msg.sender]++;
        }
        emit depositeEvent(msg.sender, data);
    }

    function getUserJoinGroup(address user, uint32 indexPage) public view returns(uint256[] memory newJoinGroup) {
        uint256 pageLength = _UserJoinGroup[user][indexPage].length;
        newJoinGroup = new uint256[](pageLength);
        unchecked {
            for(uint256 i; i<pageLength; i++){
                newJoinGroup[i] = _UserJoinGroup[user][indexPage][i];
            }
        }
        return newJoinGroup;
    }

    function getUserLastPage(address user) public view returns(uint32 lastPage) {
        lastPage = _UserLastPage[user];
    }

    function getUserIfJoin(address user, uint256 id) public view returns(bool ifJoin) {
        ifJoin = _UserIfJoin[user][id];
    }


}