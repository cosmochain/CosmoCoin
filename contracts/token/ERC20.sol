pragma solidity ^0.4.18;

/**
 *   @title ERC20
 *   @dev Standart ERC20 token interface
 */
contract ERC20 {
    uint256 public totalSupply = 0;
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}