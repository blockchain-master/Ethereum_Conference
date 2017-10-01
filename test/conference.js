var Conference = artifacts.require("./Conference.sol");

contract('Conference', function(accounts) {
	it("Initial conference settings should match", function(done) {
		Conference.new({ from: accounts[0] }).then(
			function(conference) {
				conference.quota.call().then(
					function(quota) {
						assert.equal(quota, 500, "Quota doesn't match!");
					}
				).then(function() {
					return conference.changeQuota(300);
				})
				.then(function(result) {
					console.log(result);
					return conference.quota.call();
				})
				.then(function(quota) {
					assert.equal(quota, 300, "New quota is not correct");
				})
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
});