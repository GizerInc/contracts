pragma solidity ^0.4.11;

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

contract Token {
  /// @return total amount of tokens
  function totalSupply() constant returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
  string public symbol;
}

contract StandardToken is Token {

  function transfer(address _to, uint256 _value) returns (bool success) {
    //Default assumes totalSupply can't be over max (2^256 - 1).
    //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
    //Replace the if with this one instead.
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    //if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    //same as above. Replace this line with the following if you want to protect against wrapping uints.
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

  uint256 public totalSupply;
}

contract GZR is StandardToken, SafeMath {
    
    address public minter;
    address public hedgeContract;
    string public name = "GZR";
    string public symbol = "GZR";
    uint public decimals = 18;

   function GZR() {
	minter = msg.sender;
	balances[msg.sender] = 100000000000000000000;  
}
    
    function create(uint amount) {
        if (msg.sender != minter) throw;
        balances[msg.sender] = safeAdd(balances[msg.sender], amount);
        totalSupply = safeAdd(totalSupply, amount);
    }
  
    function destroy(uint amount) {
        if (msg.sender != minter) throw;
        if (balances[msg.sender] < amount) throw;
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        totalSupply = safeSub(totalSupply, amount);
    }
}

contract GZRItems {
   
   Item[] items;
   mapping (uint256 => address) public itemIndexToOwner;

   struct Item {
        uint256 propertyA;
        uint256 propertyB;
        uint256 propertyC;
    }
    
    function totalSupply() public returns (uint) {
        return items.length - 1;
    }
    
    function ownerOf(uint256 _tokenId) external returns (address) {
        address owner = itemIndexToOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }
    
    function newItem(uint _propertyA, uint _propertyB, uint _propertyC) returns (uint) {
        uint newId = items.length++;
        Item I = items[newId];
        I.propertyA = _propertyA;
        I.propertyB = _propertyB;
        I.propertyC = _propertyC;
        itemIndexToOwner[newId] = tx.origin; 
        return newId;
    }
    
    function getProperty(uint _id) public returns (uint256 propA, uint256 propB, uint256 propC) {
        Item I = items[_id];
        return (I.propertyA, I.propertyB, I.propertyC);
    }
}

contract GZRTokenToItemGeneration {
    address public gzr;
    address public gzrItems;
    
    uint randA = uint(block.blockhash(block.number-1))%10 + 1;
    uint randB = uint(block.blockhash(block.number-1))%10 + 1;
    uint randC = uint(block.blockhash(block.number-1))%10 + 1;
    
    function setUpAddresses(address _gzr, address _gzrItems) {
        gzr = _gzr;
        gzrItems = _gzrItems;
    }
    
    function spendGZRToGetAnItem() {
        GZR g = GZR(gzr);
        GZRItems gI = GZRItems(gzrItems);
        if(g.balanceOf(msg.sender) < 1) throw;
        // remember to have user approve first
        g.transferFrom(msg.sender, this, 1);
        gI.newItem(randA, randB, randC);
    }
}
