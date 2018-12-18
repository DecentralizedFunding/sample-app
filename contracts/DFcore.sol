pragma solidity ^0.4.23;
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";

contract Crediential is ERC721Full {

  constructor() public ERC721Full("DFCrediential", "DFC"){
  }

  uint256 internal nextTokenId = 0;

  function mint(string _message) internal {
    uint256 tokenId = nextTokenId;
    nextTokenId = nextTokenId.add(1);
    super._mint(msg.sender, tokenId);
    super._setTokenURI(tokenId, _message);
  }

  function burn(uint256 _tokenId) external {
    super._burn(msg.sender, _tokenId);
  }

  function supportTokenid(address _owner) public view returns (uint[]) {
    uint[] memory tokenlist = new uint[](balanceOf(_owner));
    for (uint i = 0; i < balanceOf(_owner); i++) {
      tokenlist[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenlist;
  }

}

contract DFcore is Ownable, Crediential {

  event NewPJ(uint id, string title, uint goal, uint amount, uint limit, address[] supporters);
  event Deposit(uint id, uint funded, uint pledged, address[] supporters);

  struct PJ {
    uint id;
    string title;
    uint goal;
    uint amount;
    uint limittime;
    address[] supportersArray;
    mapping (address => uint) funds;  //支援者の誰がどれだけ投げてくれたのかを記録しておく
  }

  PJ[] public PJs;
  mapping (uint => address) public PJToOwner;
  mapping (address => uint) public ownerPJCount;

  modifier onlyOwnerOf(uint _PJId) {
    require(msg.sender == PJToOwner[_PJId]);
    _;
  }

  function makePJ(string _title, uint _goal, uint _limittime) public {  // クラウドファンディングのETHを貯める箱を作る関数
    require(now <= _limittime);
    address[] memory _supportersArray;
    uint _id = PJs.length;
    PJs.push(PJ(_id, _title, _goal, 0, _limittime, _supportersArray));
    PJToOwner[_id] = msg.sender;
    ownerPJCount[msg.sender]++;
    emit NewPJ(_id, _title, _goal, 0, _limittime, _supportersArray);
  }

  function deposit(uint _id, string _URI) public payable { // 箱にETHを投げる関数
    require(PJs[_id].amount < PJs[_id].goal);
    require(now <= PJs[_id].limittime);
    require(msg.sender != PJToOwner[_id]);
    bool flag = false;
    //PJs[_id].supportersArrayで msg.valueがないかどうかループを回して、フラグを立てておく
    //フラグが立っている場合は、 PJs[_id].supportersArray.push(msg.sender)を実行させない
    for (uint i = 0; i < PJs[_id].supportersArray.length; i++) {
      if (PJs[_id].supportersArray[i] == msg.sender) {
        flag = true;
      }
    }
    PJs[_id].amount = PJs[_id].amount + msg.value;
    if (flag == false) {
        PJs[_id].supportersArray.push(msg.sender);
    }
    PJs[_id].funds[msg.sender] += msg.value;
    mint(_URI);
    emit Deposit(PJs[_id].id, PJs[_id].amount, msg.value, PJs[_id].supportersArray);
  }

  function success_withdraw(uint _id) public onlyOwnerOf(_id) {  // 箱の中が満額以上の時のみ、PJ製作者がのみが実行してお金を引き出すことができる
    require(PJs[_id].amount >= PJs[_id].goal);
    uint nakami = PJs[_id].amount;
    PJs[_id].amount = 0;
    ownerPJCount[PJToOwner[_id]]--;
    PJToOwner[_id] = owner(); //ownerはコントラクト作成者
    ownerPJCount[owner()]++;
    msg.sender.transfer(nakami);
  }

  function failure_withdraw(uint _id) public {  // 期限を超えて、目標額集まらなかった時に、貯めたお金を支援者に返金する
    require(now > PJs[_id].limittime);
    require(PJs[_id].amount < PJs[_id].goal);
    for (uint i = 0; i < PJs[_id].supportersArray.length; i++) {
      address supporteraddress = PJs[_id].supportersArray[i];
      uint siengaku = PJs[_id].funds[supporteraddress];
      PJs[_id].funds[supporteraddress] = 0;
      supporteraddress.transfer(siengaku);
    }
  }

  function getPJByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](ownerPJCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < PJs.length; i++) {
      if (PJToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  function getPJInfo(uint _id) public view returns(uint256, string, uint256, uint256, uint256, address[]) {
    return (PJs[_id].id, PJs[_id].title, PJs[_id].goal, PJs[_id].amount, PJs[_id].limittime, PJs[_id].supportersArray);
  }

  function getPJFunds(uint _id, address _address) public view returns(uint256) {
    return (PJs[_id].funds[_address]);
  }

  function getPJCount() public view returns(uint256) {
    return PJs.length;
  }

}
