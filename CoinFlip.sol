pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract CoinFlip is VRFConsumerBaseV2 {

//ChainLink VRF
VRFCoordinatorV2Interface COORDINATOR;
bytes32 KEYHASH;
uint64 public FEE;

//Game Variables
mapping (uint256 => address payable ) public pendingGames;
mapping (uint256 => uint256) public bets;

constructor(address payable _coordinator, bytes32 _keyHash, uint64 _fee) VRFConsumerBaseV2(_coordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
    KEYHASH = _keyHash;
    FEE = _fee;
}

function flipCoin(address payable _player, uint256 _betAmount) payable public {
    require(_betAmount > 0, "Bet amount should be more than 0");
    (bool success, ) = payable(address(this)).call{value: _betAmount}("");
    require(success, "Tranfer Failed");
    uint256 requestId = COORDINATOR.requestRandomWords(KEYHASH, FEE, 1, 1, 1);
    pendingGames[requestId] = _player;
    bets[requestId] = _betAmount;
}

function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override  {
    address playerAddress = pendingGames[requestId];
    uint256 betAmount = bets[requestId];

    uint256 randomNumber = randomWords[0] % 2;
    bool isHead = randomNumber == 0; 

    ditributeRewards(isHead ? playerAddress : address(this), betAmount);

    delete pendingGames[requestId];
}

function ditributeRewards(address winner, uint256 betAmount) internal {
    payable(winner).transfer(betAmount * 2);
}
} 