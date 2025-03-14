// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

library VineLib {

    function _currentDomain()internal view returns(uint32 _cctpDomain){
        if(block.chainid == 1 || block.chainid == 11155111){
            _cctpDomain = 0;   //eth
        }else if(block.chainid == 43114 || block.chainid == 43113){
            _cctpDomain = 1;   //avax
        }else if(block.chainid == 10 || block.chainid == 11155420){
            _cctpDomain = 2;   //op
        }else if(block.chainid == 42161 || block.chainid == 421614){
            _cctpDomain = 3;   //arb
        }else if(block.chainid == 8453 || block.chainid == 84532){
            _cctpDomain = 6;   //base
        }else if(block.chainid == 137 || block.chainid == 80002){
            _cctpDomain = 7;   //polygon
        }else if(block.chainid == 130 || block.chainid == 1301){
            _cctpDomain = 10;  //uni
        }
    }

    function _protocolFeeAmount(
        uint16 _feeRate,
        uint64 _depositeTotalAmount,
        uint256 _finallyTokenAmount
    )internal pure returns (uint256 _feeAmount){
        if(_finallyTokenAmount >= _depositeTotalAmount + 10000){
            _feeAmount = (_finallyTokenAmount - _depositeTotalAmount) * _feeRate / 10000; 
        }else if(_finallyTokenAmount > _depositeTotalAmount && _finallyTokenAmount < _depositeTotalAmount + 10000){
            _feeAmount = _finallyTokenAmount - _depositeTotalAmount;
        }else{
            _feeAmount = 0;
        }
    }

    function _curatorFeeAmount(
        uint16 _feeRate,
        uint64 _depositeTotalAmount,
        uint256 _finallyTokenAmount
    )internal pure returns (uint256 _feeAmount){
        if(_finallyTokenAmount >= _depositeTotalAmount + 10000){
            _feeAmount = (_finallyTokenAmount - _depositeTotalAmount) * _feeRate / 10000; 
        }else{
            _feeAmount = 0;
        }
    }

    function _getUserFinallyAmount(
        uint16 _curatorFee,
        uint16 _protocolFee,
        uint64 _userSupplyAmount,
        uint64 _depositeTotalAmount,
        uint256 _userShareAmount,
        uint256 _finallyTokenAmount,
        uint256 _totalSupply
    ) internal pure returns (uint256 _finallyAmount) {
        if (_finallyTokenAmount <= _depositeTotalAmount + 10000) {
            if(_finallyTokenAmount == 0){
                _finallyAmount = 0;
            }else{
                _finallyAmount = _userSupplyAmount;
            }
        } else {
            _finallyAmount =
                _userSupplyAmount +
                (_userShareAmount * (_finallyTokenAmount - _depositeTotalAmount) * (10000 - _curatorFee - _protocolFee)) 
                / 10000 / _totalSupply;
        }
    }
}
