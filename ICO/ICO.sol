// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "MyToken.sol";

//Owner of the token is also leader of the ico.
contract ICO {

    // ICO starting and finishing time.
    uint256 public startTime;
    uint256 public endTime;

    //ICO leader account, raised funds will be transfered to it.
    address payable public icoLeader;

    //Token price in ETH pair.
    uint256 public tokenPrice;

    bool public icoStarted;

    //Maximum token amount that every user can buy
    uint256 public tokenLimitPerUser;

    //Max token amount to be distributed
    uint256 public maxDistrituableAmount;
    uint256 public remainingTokens;

    //Total raised funds from ICO, these funds will be transfer to leader.
    uint256 public raisedFunds;

    //Our simple token
    MYTOKEN public myToken;

  
    //We use WrongTiming error if transaction is happening in a wrong time
    error WrongTiming();
   
    event ReceiptOfIco(address leader, uint256 raisedFunds);
    event TokenPurchase(address buyer, uint256 amount);


    modifier onlyLeader(){
      require(msg.sender == icoLeader, "Only ico leader can start it");
      _;
    }

    //Transaction must happen while ico continue, and ico must be already started
    modifier timeChecks(){
      if (block.timestamp < startTime || block.timestamp > endTime) {
        revert WrongTiming();
      }
      if (icoStarted != true) {
        revert WrongTiming();
      }
      _;
    }
    
    constructor(
      address payable _icoLeader,
      MYTOKEN _myToken,
      uint256 _tokenPrice,
      uint256 _maxDistrituableAmount,
      uint256 _tokenLimitPerUser
    ) 
    {
      require(msg.sender == _icoLeader, "Only ico leader can deploy contract");
      /*
      I want ico leader and owner of token be same account, 
      but the below code line causes an error. Please give me feedback about how to fix it
     
      require(_icoLeader == myToken.owner, "not");

      If ico leader and owner of token is different accounts, dont forget to firstly send tokens to leader
      */
      
      tokenPrice = _tokenPrice;
      icoLeader = _icoLeader;
      myToken = _myToken;
      maxDistrituableAmount = _maxDistrituableAmount;
      tokenLimitPerUser = _tokenLimitPerUser;
      remainingTokens = _maxDistrituableAmount;
    }

    receive() external payable{}
    fallback() external payable {}

    struct BuyerInfo {
      uint256 purchasedAmount;
      uint256 payment;
      uint256 purchaseTime;
      bool alreadyPurchased;
    }

    //Informations about token buyers
    mapping(address => BuyerInfo) public buyers;

    function buy(address _buyerAddress,uint256 requestedTokenAmount)
      public 
      payable 
      timeChecks 
    {
      require(_buyerAddress ==msg.sender, "You cant buy behalf of someone else.");
      require(buyers[_buyerAddress].alreadyPurchased == false, "You have already bought tokens");
      
      uint256 receipt = requestedTokenAmount *tokenPrice;
      require(msg.value == receipt, "Sending amount must be equal to receipt");
      
      purchaseTokens(_buyerAddress,requestedTokenAmount);
      transferFundsToLeader(msg.value);
    }

    //Every user can buy only once
    function purchaseTokens(address _purchaser, uint256 _amount) internal {
      require(
        (_amount <= remainingTokens) && (remainingTokens > 0),
        "The amount of coins requested must be less than or equal to the remaining amount"
      );
      require(_amount <= tokenLimitPerUser, "You can't purchase more than your limit");
      uint256  payment = _amount * tokenPrice; 
      buyers[_purchaser]   = BuyerInfo(_amount,payment,block.timestamp,true);
      myToken.transfer(icoLeader,_purchaser,_amount);
      remainingTokens -= _amount;
      emit TokenPurchase(_purchaser, _amount);

    } 
    
    function transferFundsToLeader(uint256 _amount) internal   {
      (bool sent, ) = payable(icoLeader).call{value: _amount}("");
      require(sent, "Falied to transfer funds");
      raisedFunds += _amount;
    }

    function startIco() public onlyLeader {
      require(icoStarted != true, "Ico is Already Started");
      icoStarted = true;
      startTime = block.timestamp;
      endTime = startTime + 7 days;
    }

    //This function shows how many seconds are left for the ico to finish.
    function checkRemainingTime() public view returns (uint256) {
      uint remainingTime = endTime - block.timestamp;
      return  remainingTime;
    }

    //You can't kill contract if the ico didnt start yet or didnt finish yet
    function kill() public onlyLeader {
      if (block.timestamp <= endTime) {
        revert WrongTiming();
      } else if (! icoStarted) {
        revert WrongTiming();
      }
      emit ReceiptOfIco(icoLeader, raisedFunds);
      selfdestruct(icoLeader);
    }
}
