var IdeaFactory = artifacts.require('./IdeaFactory.sol');

contract('IdeaFactory', function(accounts) {
  it('', function() {
    return IdeaFactory.deployed().then(function(instance) {
      ideaFactory = instance;
      const expected = 'お金欲しい'
      return ideaFactory.comeUpWithIdea.call(expected);
    }).then(function(id) {
      return ideaFactory.getIdea.call(id.toString(10));
    }).then(function(idea) {
      assert.equal(expected, idea, 'Returned idea should be "お金欲しい"');
    });
  });
});
