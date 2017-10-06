contract owned {
	address public owner;

	function owned() {
		owner = msg.sender;
	}

	modifier onlyOwner  { 
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner {
		owner = newOwner;
	}
	
}

contract MyToken is owned {
	mapping (address => uint256) public balanceOf;
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;

	event Transfer(address indexed from, address indexed to, uint256 value);

	function MyToken( uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits, address centralMinter ) {
		totalSupply = initialSupply;
		balanceOf[msg.sender] = initialSupply;
		name = tokenName;
		symbol = tokenSymbol;
		decimals = decimalUnits;

		if (centralMinter != 0) owner = centralMinter;
	}

	/* Internal transfer, only can be called by this contract */
	function _transfer(address _from, address _to, uint _value) internal {
		require(_to != 0x0);
		require(balanceOf[_from] > _value);
		require(balanceOf[_to] + _value > balanceOf[_to]);
		require(!frozenAccount[_from]);
		require(!frozenAccount[_to]);
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;

		/* Notify anyone listening that this transfer took place */
		Transfer(_from, _to, _value);
	}

	function mintToken(address target, uint256 mintedAmount) onlyOwner {
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		Transfer(0, owner, mintedAmount);
		Transfer(owner, target, mintedAmount);
	}
}