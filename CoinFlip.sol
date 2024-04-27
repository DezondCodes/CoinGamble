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

} 