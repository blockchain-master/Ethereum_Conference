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
	mapping (address => bool) public approvedAccount;

	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	uint256 public sellPrice;
	uint256 public buyPrice;
	uint minBalanceForAccounts;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event FrozenFunds(address target, bool frozen);

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
		require(approvedAccount[_from]);
		require(approvedAccount[_to]);
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;

		/* Notify anyone listening that this transfer took place */
		Transfer(_from, _to, _value);
	}

	function transfer(address _to, uint256 _value) {
		require(approvedAccount[msg.sender]);

		/* send coins to sustain minimum balance */
		if (_to.balance < minBalanceForAccounts)
			_to.sell((minBalanceForAccounts - _to.balance) / sellPrice);
	}

	function mintToken(address target, uint256 mintedAmount) onlyOwner {
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		Transfer(0, owner, mintedAmount);
		Transfer(owner, target, mintedAmount);
	}

	function freezeAccount(address target, bool freeze) onlyOwner {
		approvedAccount[target] = freeze;
		FrozenFunds(target, freeze);
	}

	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
		sellPrice = newSellPrice;
		buyPrice = newBuyPrice;
	}

	function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
		minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
	}

	function buy() payable returns (uint amount) {
		amount = msg.value / buyPrice;
		require(balanceOf[this] >= amount);
		balanceOf[msg.sender] += amount;
		balanceOf[this] -= amount; // subtracts amount from seller's balance
		Transfer(this, msg.sender, amount);
		return amount;
	}

	function sell(uint amount) returns (uint revenue) {
		require(balanceOf[msg.sender] >= amount); // check if the sender has enough to sell
		balanceOf[this] += amount;
		balanceOf[msg.sender] -= amount;
		revenue = amount * sellPrice;
		require(msg.sender.send(revenue));
		Transfer(msg.sender, this, amount);
		return revenue;
	}
}