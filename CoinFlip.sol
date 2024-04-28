pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract CoinFlip is VRFConsumerBaseV2 {

//ChainLink VRF
VRFCoordinatorV2Interface COORDINATOR;
bytes32 KEYHASH;
uint256 public FEE;

//Game Variables
mapping (uint256 => address payable ) public players;
mapping (uint256 => uint256) public bets;

constructor(address payable _coordinator, bytes32 _keyHash, uint256 _fee) VRFConsumerBaseV2(_coordinator) public  {
    COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
    KEYHASH = _keyHash;
    FEE = _fee;
}

function flipCoin(address payable _player, uint256 _betAmount) payable public {
    require(_betAmount > 0, "Bet amount should be more than 0");
    (bool success, ) = payable(address(this)).call{value: _betAmount}("");
    require(success, "Tranfer Failed");
}
} 