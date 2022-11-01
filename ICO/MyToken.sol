// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MYTOKEN {
  string private  name;
  string private symbol;
  uint256 public totalSupply;
  address payable public owner;

  mapping(address => uint256) public balances;

  modifier onlyLeader(){
    require(msg.sender == owner, "ONly owner");
    _;
  }

  constructor(address payable _owner,string memory _name, string memory _symbol, uint256 _totalSupply) {
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply;
    owner = _owner;
    balances[owner] = totalSupply;
  }

  function transfer(address _from, address _to, uint256 _amount) public payable {
    require(_from != address(0), "transfer from the zero address");
    require(_to != address(0), "transfer to the zero address");

    uint256 senderBalance = balances[_from];
    require(senderBalance >= _amount, "Balances arent enough");
    senderBalance -= _amount;
    balances[_to] += _amount;
  }
}