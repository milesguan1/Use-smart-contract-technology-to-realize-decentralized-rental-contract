// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HouseAuction {
    struct Bid {
        address bidder;
        uint256 bidAmount;
    }

    address public landlord;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public minimumPrice;
    uint256 public maximumPrice;
    uint256 public deposit;
    uint256 public refundThreshold1; 
    uint256 public refundThreshold2; 
    Bid public winningBid;
    mapping(address => uint256) public refunds;
    mapping(address => bool) public hasDeposited;
    mapping(address => Bid) public bids; 
    address[] public allParticipants; 

    constructor(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _minimumPrice,
        uint256 _maximumPrice,
        uint256 _deposit,
        uint256 _refundThreshold1,
        uint256 _refundThreshold2
    ) {
        landlord = msg.sender;
        startTime = _startTime;
        endTime = _endTime;
        minimumPrice = _minimumPrice;
        maximumPrice = _maximumPrice;
        deposit = _deposit;
        refundThreshold1 = _refundThreshold1;
        refundThreshold2 = _refundThreshold2;
    }

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only landlord can perform this action");
        _;
    }

    modifier onlyAfterAuction() {
        require(block.timestamp > endTime, "Auction not yet ended");
        _;
    }

    function submitDeposit() external payable {
        require(msg.value == deposit, "Incorrect deposit amount");
        hasDeposited[msg.sender] = true;
    }

    function placeBid(uint256 minBidAmount, uint256 maxBidAmount) external {
        require(hasDeposited[msg.sender], "Deposit not submitted");

        
        if (maxBidAmount > winningBid.bidAmount) {
            
            if (maxBidAmount > maximumPrice) {
                maxBidAmount = maximumPrice;
            }
            
            refunds[winningBid.bidder] += winningBid.bidAmount;
            winningBid = Bid(msg.sender, maxBidAmount);

            
            bids[msg.sender] = Bid(msg.sender, maxBidAmount);

            
            allParticipants.push(msg.sender);
        }
    }

    function finalizeAuction() external onlyLandlord onlyAfterAuction {
        
        for (uint256 i = 0; i < allParticipants.length; i++) {
            address participant = allParticipants[i];
            if (participant != winningBid.bidder) {
                refunds[participant] += deposit;
            }
        }

        
        allParticipants = new address[](0);
        winningBid = Bid(address(0), 0);
    }

    function withdrawRefund() external {
        uint256 refundAmount = refunds[msg.sender];
        require(refundAmount > 0, "No refund available");

        
        if (block.timestamp >= refundThreshold1) {
            refunds[msg.sender] = 0; 
            payable(msg.sender).transfer(refundAmount);
        }
        
        else if (block.timestamp >= refundThreshold2) {
            uint256 halfRefundAmount = refundAmount / 2;
            refunds[msg.sender] -= halfRefundAmount; 
            
        }
        
        else {
            revert("Cannot withdraw deposit yet");
        }
    }

    function claimLandlordReward() external onlyLandlord {
        
        require(block.timestamp > endTime, "Auction not yet ended");
        uint256 landlordReward = refunds[address(this)]; 
        require(landlordReward > 0, "No reward available");

        
        refunds[address(this)] = 0;
        payable(landlord).transfer(landlordReward);
    }

    function getAuctionResult() external view onlyAfterAuction returns (address, uint256) {
        return (winningBid.bidder, winningBid.bidAmount);
    }
}
