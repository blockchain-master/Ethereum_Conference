var Conference = artifacts.require("./Conference.sol");

contract('Conference', function(accounts) {
	it("Initial conference settings should match", function(done) {
		Conference.new({ from: accounts[0] }).then(
			function(conference) {
				conference.quota.call().then(
					function(quota) {
						assert.equal(quota, 500, "Quota doesn't match!");
					}
				)
				.then(function() {
					return conference.numRegistrants.call();
				}).then(function(num) {
					assert.equal(num, 0, "Registrants should be zero!");
					return conference.organizer.call();
				}).then(function(organizer) {
					assert.equal(organizer, accounts[0], "Owner doesn't match!");
					done();
				}).catch(done);
			}
		).catch(done);
	});

	it("should update quota", function(done) {
		Conference.new({ from: accounts[0] }).then(
			function(conference) {
				conference.quota.call().then(
					function(quota) {
						assert.equal(quota, 500, "Quota doesn't match!");
					}
				)
				.then(function() {
					return conference.changeQuota(300);
				})
				.then(function(result) {
					console.log(result);
					return conference.quota.call();
				})
				.then(function(quota) {
					assert.equal(quota, 300, "New quota is not correct");
					done();
				}).catch(done);
			}
		).catch(done);
	});

	it("should let you buy a ticket", function(done) {
		Conference.new({ from: accounts[0] }).then(
			function(conference) {
			var ticketPrice = web3.toWei(.05, 'ether');
			var initialBalance = web3.eth.getBalance(conference.address).toNumber();
			conference.buyTicket({ from: accounts[1], value: ticketPrice })
			.then(function() {
				var newBalance = web3.eth.getBalance(conference.address).toNumber();
				var difference = newBalance - initialBalance;
				assert.equal(difference, ticketPrice, "Difference should be what was sent");
				return conference.numRegistrants.call();
			}).then(function(num) {
				assert.equal(num, 1, "there should be 1 registrant");
				return conference.registrantsPaid.call(accounts[1]);
			}).then(function(amount) {
				assert.equal(amount.toNumber(), ticketPrice, "Sender's paid but is not listed");
				done();
			}).catch(done);
		}).catch(done);
	});
});