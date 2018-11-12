pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/IdeaFactory.sol";

contract TestIdea {
  IdeaFactory ideaFactory = IdeaFactory(DeployedAddresses.IdeaFactory());

  function testComeUpWithIdea() public {
    uint returned = ideaFactory.comeUpWithIdea("Get more money!");

    uint expected = 0;

    Assert.equal(returned, expected, "Idea ID 0 should be recorded.");
  }

  function testGetIdea() public {
    string memory expected = "Get more money!";

    string memory returned = ideaFactory.getIdea(0);

    Assert.equal(returned, expected, "'Get more money!' should be recorded.");
  }
}
