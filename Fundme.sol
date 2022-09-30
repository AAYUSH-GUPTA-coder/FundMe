// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NOT_OWNER();
error SEND_MORE_ETH();
error TRANSFER_FUND_FAIL();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    mapping(address => bool) public isAlreadyFunder;
    address[] public funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    
    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        if(msg.value.getConversionRate() < MINIMUM_USD){
            revert SEND_MORE_ETH();
        }
        
        addressToAmountFunded[msg.sender] += msg.value;
        // condition to check whether the msg.sender is already a funder
        if(!isAlreadyFunder[msg.sender]){
            isAlreadyFunder[msg.sender] = true;
            funders.push(msg.sender);
        }
        
    }
    
    function getVersion() public view returns (uint256){
        // ETH/USD price feed address of Goerli Network.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.version();
    }
    
    modifier onlyOwner {
        if (msg.sender != i_owner) revert NOT_OWNER();
        _;
    }
    
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        if(!callSuccess) revert TRANSFER_FUND_FAIL();
        // require(callSuccess, "Call failed");
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}
