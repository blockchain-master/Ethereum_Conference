pragma solidity ^0.4.16;

contract owned {
	address public owner;

	function owned() public {
		owner = msg.sender;
	}

	modifier onlyOwner  { 
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
		owner = newOwner;
	}
	
}

interface tokenRecipient {
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract MyToken is owned {
	mapping (address => uint256) public balanceOf;
	mapping (address => bool) public approvedAccount;

	string public name;
	string public symbol;
	uint8 public decimals = 18; // 18 decimals is the strongly suggested default.
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
		timeOfLastProof = now;
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

	// proof of work

	bytes32 public currentChallenge;
	uint public timeOfLastProof;
	uint public difficulty = 10**32;

	function proofOfWork(uint nonce) {
		bytes8 n = bytes8(sha3(nonce, currentChallenge)); // Generate a random hash based on input
		require(n >= bytes8(difficulty)); // Check if it's under the difficulty

		uint timeSinceLastProof = (now - timeOfLastProof); // Calculate time since last reward was given
		require(timeSinceLastProof >= 5 seconds); // reward cannot be given too quickly
		balanceOf[msg.sender] += timeSinceLastProof / 60 seconds; // The reward to the winner grows by the minute

		difficulty = difficulty * 10 minutes / timeSinceLastProof + 1; // Adjusts the difficulty

		timeOfLastProof = now;
		currentChallenge = sha3(nonce, currentChallenge, block.blockhash(block.number - 1)); // Save a hash that will be used as the next proof
	}
}