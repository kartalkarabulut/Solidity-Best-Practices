// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MultiSig {

    address[] public owners;
    uint256 requiredVoteCount;

    event Deposit(uint256 amount, address sender);
    event Approved(address approverOwner, uint256 approvedTransaction);
    event ExecuteTransaction(uint256 txId, uint256 amount);
    event CreateTransaction(address creator);

    struct Transaction{
        address creator;
        address to;
        uint256 amount;
        uint256 voteCount;
        bool executed;
    }
 
    constructor(address[] memory  _owners, uint256 _requiredVoteCount) {
        require(_owners.length >=2);
        require(_requiredVoteCount <= _owners.length);

        // CHECK  if owners are valid address
        for(uint i; i<_owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0));
            owners.push(owner);
            isOwner[owner] = true;
        }
        requiredVoteCount = _requiredVoteCount;

    }
    
    modifier notExecuted(uint256 transactionId) {
        require(transactions[transactionId].executed == false,
            "Transaction is already executed"
        );
        _;
    }

    modifier onlyOwners() {
       require(isOwner[msg.sender] == true, "You arent a owner");
       _;
    }

    /*
        Walletnonce is incrementing after a transaction is totally done, 
        thats why walletNonce is always equal to transactionId,
        so if transactionId isnt equal to walletNonce its mean is transaction
        isnt existing are alreay executed.
    */
    modifier transactionExist(uint256 transactionId){
        require(transactionId ==walletNonce, "A transaction with this id isnt existing.");
        _;
    }


    //nonce must chane after every execution
    uint256 public walletNonce;

    // owners => txId => true||false
    mapping(address => mapping(uint256 => bool)) public isApproved;

    // txID||walletNonce => Transaction
    mapping(uint256 => Transaction) public transactions;
    mapping(address => bool) public isOwner;

    /*
        We use this mapping, because if there is already a proposel waiting 
        for execution you will cant create a new one, 
        if you want create a new one you have to execute or delete the pending proposal
    */
    mapping(uint => bool) public isTransactionPending; 


    function createTxProposal(address _to, uint256 _amount) public onlyOwners {
        require(_to != address(0), "Invalid address to send ");
        require(isTransactionPending[walletNonce] == false,
            "A transaction with this id is already waiting for execution"
        );

        isTransactionPending[walletNonce] = true;
        transactions[walletNonce] = Transaction(msg.sender,_to, _amount,0,false);
        emit CreateTransaction(msg.sender);
    }

    
    function approveTransaction(uint256 _txId)
        public
        onlyOwners
        notExecuted(_txId)
        transactionExist(_txId)
    {
        require(isApproved[msg.sender][_txId] == false, "You have already approved");
        transactions[_txId].voteCount +=1;
        isApproved[msg.sender][_txId] = true;
    }

    function showApprovalCount(uint256 _txId) public view returns(uint256) {
        return transactions[_txId].voteCount;
    }

    function cancelApprove(uint256 _txId)
        public onlyOwners
        notExecuted(_txId)
        transactionExist(_txId) 
    {
        require(isApproved[msg.sender][_txId] == true,
            "You havent approved this transaction"
        );

        transactions[_txId].voteCount -=1;
        isApproved[msg.sender][_txId] = false;
    }

   function showBalance() public view  returns(uint256) {
       return address(this).balance;
   }

    function executeTransaction(uint256 _txId) 
        public
        onlyOwners
        notExecuted(_txId)
        transactionExist(_txId)
    {       
        uint  value = transactions[_txId].amount;
        require(transactions[_txId].voteCount >= requiredVoteCount,
            "The Transaction didnt voted enough"
        );
        require(value <= address(this).balance, "Invalid amount"); 
        
        transactions[_txId].executed = true;
        isTransactionPending[_txId] = false;
        walletNonce +=1;

        (bool sent, ) = transactions[_txId].to.call{value: value}("");
        require(sent == true, "transaction couldnt executed");
        
        emit ExecuteTransaction(_txId,transactions[_txId].amount);
    }


    function deleteTransaction(uint256 _txId)
        public
        onlyOwners
        notExecuted(_txId)
    {
        delete transactions[_txId];

        address[] memory _owners = owners;

        for(uint i; i < _owners.length; i++){
            isApproved[_owners[i]][_txId] = false;
        }
        
    }

    receive() external payable {
        emit Deposit(msg.value,msg.sender);
    }

    function kill(address payable to) public onlyOwners {
        selfdestruct(to);
    }
}


 //Simply send money to your wallet
contract SendMoney{
    function sendMoney(address to) public payable  {

        (bool sent, ) = to.call{value: msg.value}("");
        require(sent,"Cantttt");
    }
}

