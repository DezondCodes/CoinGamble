// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract coinFlip is VRFConsumerBaseV2Plus {

    event BetPlaced(address indexed  player, uint256 betAmount, uint256 requestId);
    event CoinFlipped(address indexed player, string outcome, uint256 amountWon);

    struct Bet {
        uint256 amount;
        bool isHead;
    }

    mapping (uint256 => Bet) public bets;
    mapping (uint256 => address) public requestIdToPlayer;

    IVRFCoordinatorV2Plus COORDINATOR;
    uint256 s_subscriptionId;
    bytes32 keyHash = 0x8596b430971ac45bdf6088665b9ad8e8630c9d5049ab54b14dff711bee7c0e26;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint256 public totalFeesCollected;

constructor (uint256 subscriptionId) VRFConsumerBaseV2Plus(0xDA3b641D438362C440Ac5458c57e00a712b66700) payable {
    COORDINATOR = IVRFCoordinatorV2Plus(0xDA3b641D438362C440Ac5458c57e00a712b66700);
    s_subscriptionId = subscriptionId;
}

    function placeBet(bool _isHead) external payable {
        require(msg.value > 0, "Amount should be more than 0");

        uint256 requestId = requestRandomWords();
        bets[requestId] = Bet(msg.value, _isHead);
        requestIdToPlayer[requestId] = msg.sender;
    
        emit BetPlaced(msg.sender, msg.value, requestId);
    }

    function requestRandomWords() internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(bets[_requestId].amount > 0, "Bet not found");
        Bet memory bet = bets[_requestId];
        delete bets[_requestId];

        uint256 randomNumber = _randomWords[0] % 2;
        bool isHead = randomNumber == 0;
        uint256 feeAmount = bet.amount * 5 / 100;
        totalFeesCollected += feeAmount;

        if (isHead == bet.isHead) {
            uint256 winnings = bet.amount * 2;
            payable(requestIdToPlayer[_requestId]).transfer(winnings);
            emit CoinFlipped(requestIdToPlayer[_requestId], "You Won!", winnings);
        } else {
            emit CoinFlipped(requestIdToPlayer[_requestId], "You Lost!", bet.amount);
        }
    }

    function fund() payable external {
    }

    function withdrawFunds(uint256 _amount) public {
    require(address(this).balance >= _amount, "insufficent funds");
    payable(msg.sender).transfer(_amount);
}





}