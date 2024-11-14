// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


contract FundMe {
    mapping (address => uint256) public fundersToAmount;
    uint256 MIN_VAULE = 100 * 10 ** 18;
    AggregatorV3Interface internal dataFeed;

    uint256 constant TARGET = 1000 * 10 ** 18;
    address public owner ;
    uint256 deploymentTimestamp;
    uint256 lockTime;

    address erc20Addr;
    bool public getFundSuccess = false;

    constructor(uint256 _lockTime) {
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        owner = msg.sender;
        deploymentTimestamp = block.timestamp;
        lockTime = _lockTime;
    }

    function fund() external payable {
        require(convertEthToUSD(msg.value) >= MIN_VAULE, "send more ETH");
        require(block.timestamp < deploymentTimestamp + lockTime, "window is closed");
        fundersToAmount[msg.sender] = msg.value;
    }
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function convertEthToUSD(uint256 ethAmount) internal  view returns (uint256){
        uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer());
        return ethAmount * ethPrice / (10 ** 8);
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "this function can only be called by owner");
        owner = newOwner;
    }

    function getFund() external windowclosed {
        require(msg.sender == owner, "this function can only be called by owner");
        require(convertEthToUSD(address(this).balance) >= TARGET, "TARGET is not reached");
        //transfer
        //payable(msg.sender).transfer(address(this).balance);
        //send
        //bool result = payable(msg.sender).send(address(this).balance);
        //require(result, "tx failed");
        //call
        bool result;
        (result, ) = payable(msg.sender).call{value: address(this).balance}("");
        fundersToAmount[msg.sender] = 0;
        getFundSuccess = true; // flag
    }

    function reFund() external windowclosed {
        require(convertEthToUSD(address(this).balance) < TARGET, "TARGET is reached");
        require(fundersToAmount[msg.sender] != 0, "there is no fund for you");
        bool result;
        (result, ) = payable(msg.sender).call{value: fundersToAmount[msg.sender]}("");
        fundersToAmount[msg.sender] - 0;
    }

    function setFunderToAmount(address funder, uint256 amountToUpdate) external {
        require(msg.sender == erc20Addr, "you do not have permission to call this funtion");
        fundersToAmount[funder] = amountToUpdate;
    }

    function setErc20Addr(address _erc20Addr) public {
        require(msg.sender == owner, "this function can only be called by owner");
        erc20Addr = _erc20Addr;
    }

    modifier windowclosed {
        require(block.timestamp >= deploymentTimestamp + lockTime, "window is not closed");
        _;
    }

}