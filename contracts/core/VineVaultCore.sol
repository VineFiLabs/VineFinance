//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ShareToken.sol";
import {IGetHook} from "../interfaces/core/IGetHook.sol";
import {ISharer} from "../interfaces/ISharer.sol";

/// @title VineVaultCore
/// @author VineLabs member 0xlive(https://github.com/VineFiLabs)
/// @notice VineFinance VineVaultCore
/// @dev Segregate funds for each strategy and deposit them in VineVaultCore
contract VineVaultCore is ShareToken{
    using SafeERC20 for IERC20;
    
    bytes1 private immutable ONEBYTES1 = 0x01;
    uint32 public currentDomain;
    address public govern;
    uint256 public currentId;
    constructor(
        uint32 _domain,
        address _govern,
        uint256 _id,
        string memory thisName, 
        string memory thisSymbol
    )ShareToken(thisName, thisSymbol){
        currentDomain = _domain;
        govern = _govern;
        currentId = _id;
    }


    event CallVault(address indexed caller, address indexed token, uint256 amount);
    event CallWayEvent(address indexed caller, address token, uint256 amount, bytes data);
    event NewDomain(uint32 newDomain);
    receive() external payable{}

    modifier onlyValidCaller(){
        _checkValidCaller();
        _;
    }

    function bytes32ToAddress(
        bytes32 _bytes32Account
    ) private pure returns (address) {
        return address(uint160(uint256(_bytes32Account)));
    }

    function _checkValidCaller()private view{
        require(ISharer(msg.sender).govern() == govern, "Invalid hook");
        bytes1 validState;
        for(uint8 i; i<IGetHook(govern).getDestChainValidHooks(currentId, currentDomain).hooks.length; i++){
            if(msg.sender == bytes32ToAddress(IGetHook(govern).getDestChainValidHooks(currentId, currentDomain).hooks[i])){
                validState = ONEBYTES1;
            }
        }
        require(validState == ONEBYTES1, "Invalid caller");
    }

    
    function changeDomain(uint32 _newDomain)external {
        require(msg.sender == govern, "Non governance");
        currentDomain = _newDomain;
        emit NewDomain(_newDomain);
    }

    function callVault(address token, uint256 amount)external onlyValidCaller returns(bool state){
        if(token == address(0)){
            (state, ) = msg.sender.call{value: amount}("");
            require(address(this).balance >=amount, "Insufficient quantity");
        }else{
            require(IERC20(token).balanceOf(address(this)) >=amount, "Insufficient quantity");
            IERC20(token).safeTransfer(msg.sender, amount);
            state = true;
        }
        emit CallVault(msg.sender, token, amount);
    }

    function callWay(
        uint8 tokenType, 
        address token, 
        address caller, 
        uint256 amount, 
        bytes memory data
    )external onlyValidCaller returns(bool success){
        if(tokenType == 0){
            (success, ) = caller.call(data);
        }else if(tokenType == 1){
            (success, ) = caller.call{value: amount}(data);
        }else{
            IERC20(token).approve(caller, amount);
            (success, ) = caller.call(data);
        }
        emit CallWayEvent(caller, token, amount, data);
    }

    function depositeMint(address to, uint256 amount)external onlyValidCaller returns(bytes1){
        _depositeMint(to, amount);
        return ONEBYTES1;
    }

    function withdrawBurn(address to, uint256 amount)external onlyValidCaller returns(bytes1){
        _withdrawBurn(to, amount);
        return ONEBYTES1;
    }

}