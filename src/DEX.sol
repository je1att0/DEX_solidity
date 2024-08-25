// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CustomERC20 is ERC20 {
    constructor(string memory tokenName) ERC20(tokenName, tokenName) {
        _mint(msg.sender, type(uint).max);
    }
}

contract Dex {
    ERC20 public tokenLP;
    ERC20 public tokenX;
    ERC20 public tokenY;
    uint public totalLP = 0;

    constructor (address _tokenX, address _tokenY) {
        tokenX = ERC20(_tokenX);
        tokenY = ERC20(_tokenY);
        tokenLP = new CustomERC20("LP");
        tokenLP.approve(address(this), type(uint).max);
    }

    function addLiquidity(uint _amountX, uint _amountY, uint _minLpReturn) public returns (uint lpReturnValue) {
        uint poolAmountX = tokenX.balanceOf(address(this));
        uint poolAmountY = tokenY.balanceOf(address(this));     
        require(_amountX > 0, "Amount of tokenX must be greater than 0");
        require(_amountY > 0, "Amount of tokenY must be greater than 0");
        require(tokenX.allowance(msg.sender,address(this)) >= _amountX && tokenY.allowance(msg.sender, address(this)) >= _amountY, "ERC20: insufficient allowance");
        require(tokenX.balanceOf(msg.sender) >= _amountX && tokenY.balanceOf(msg.sender) >= _amountY, "ERC20: transfer amount exceeds balance");
        uint lpReturn;
        if (totalLP == 0) {
            lpReturn = sqrt(_amountX * _amountY);
        }
        else {
            lpReturn = (_amountX * totalLP) / poolAmountX >= (_amountY * totalLP) / poolAmountY ? (_amountY * totalLP) / poolAmountY : (_amountX * totalLP) / poolAmountX;
        }

        require(lpReturn >= _minLpReturn, "Insufficient LP return");
        tokenLP.transfer(msg.sender, lpReturn);
        tokenX.transferFrom(msg.sender, address(this), _amountX);
        tokenY.transferFrom(msg.sender, address(this), _amountY);
        totalLP += lpReturn;
        
        return lpReturn;
    }

    function removeLiquidity(uint _lpReturn, uint _minAmountX, uint _minAmountY) public returns (uint _tx, uint _ty) {
        uint poolAmountX = tokenX.balanceOf(address(this));
        uint poolAmountY = tokenY.balanceOf(address(this));
        _tx = poolAmountX*_lpReturn/totalLP;
        _ty = poolAmountY*_lpReturn/totalLP;
        require(_tx >= _minAmountX && _ty >= _minAmountY, "Insufficient minimum amount");
        require(_lpReturn <= poolAmountX + poolAmountY, "Insufficient LP return");

        tokenX.transfer(msg.sender, _tx);
        tokenY.transfer(msg.sender, _ty);
        totalLP -= _lpReturn;

        return (_tx, _ty);

    }
    function swap(uint _amountX, uint _amountY, uint _minOutput) public returns (uint swapReturn) {
        require(_amountX == 0 || _amountY == 0, "Only one token can be swapped at a time");
        if (_amountY == 0) {
            swapReturn = swapXtoY(_amountX, _amountY, _minOutput);
        }
        if (_amountX == 0) {
            swapReturn = swapYtoX(_amountX, _amountY ,_minOutput);   
        }
    }

    function swapXtoY(uint _amountX,  uint _amountY, uint _minOutput) public returns (uint swapReturn) {
        uint poolAmountX = tokenX.balanceOf(address(this));
        uint poolAmountY = tokenY.balanceOf(address(this));
        swapReturn = poolAmountY - poolAmountX*poolAmountY/(poolAmountX + _amountX);
        swapReturn = swapReturn * 999 / 1000;
        require(swapReturn >= _minOutput, "Insufficient minimum output");
        tokenX.transferFrom(msg.sender, address(this), _amountX);
        tokenY.transfer(msg.sender, swapReturn);
        return swapReturn;
    }

    function swapYtoX(uint _amountX, uint _amountY, uint _minOutput) public returns (uint swapReturn) {
        uint poolAmountX = tokenX.balanceOf(address(this));
        uint poolAmountY = tokenY.balanceOf(address(this));
        swapReturn = poolAmountX - poolAmountX*poolAmountY/(poolAmountY + _amountY);
        swapReturn = swapReturn * 999 / 1000;
        require(swapReturn >= _minOutput, "Insufficient minimum output");
        tokenY.transferFrom(msg.sender, address(this), _amountY);
        tokenX.transfer(msg.sender, swapReturn);
        return swapReturn;
    }

    function sqrt(uint x) internal returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}