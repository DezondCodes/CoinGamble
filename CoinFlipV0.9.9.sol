pragma solidity ^0.8.7;

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract coinFlip is VRFConsumerBaseV2Plus {

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event CoinFlip(address player, string isHead, uint256 amount);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
        uint256 betAmount;
    }
    mapping(uint256 => RequestStatus) public s_requests;
    mapping(uint256 => address) public m_player;

    IVRFCoordinatorV2Plus COORDINATOR;
    uint256 s_subscriptionId;
    bytes32 keyHash = 0x8596b430971ac45bdf6088665b9ad8e8630c9d5049ab54b14dff711bee7c0e26;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint256 public totalFeesCollected;

constructor (uint256 subscriptionId) VRFConsumerBaseV2Plus(0xDA3b641D438362C440Ac5458c57e00a712b66700) payable {

    COORDINATOR = IVRFCoordinatorV2Plus(0xDA3b641D438362C440Ac5458c57e00a712b66700);
        s_subscriptionId = subscriptionId;
}
    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {

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
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            betAmount: 0
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
        fulfillGamble(_requestId, s_requests[_requestId].betAmount);   
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }


    function gamble(
        uint256 _amount
    ) public payable returns (uint256) {

        require(msg.value == _amount, "invalid amount");
        require(_amount > 0, "amount should be more than 0");

        uint256 requestId = COORDINATOR.requestRandomWords(
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
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            betAmount: _amount
        });
        requestIds.push(requestId);
        emit RequestSent(requestId, numWords);
        return requestId;



}
    function fulfillGamble (uint256 _requestId, uint256 _amount) internal  {

        RequestStatus memory requestStatus = s_requests[_requestId];
        uint256 randomNumber = requestStatus.randomWords[0] % 2;
        bool isHead = randomNumber == 0; 
        uint256 feeAmount = _amount * 5 / 100;
        uint256 betAmount = _amount - feeAmount;
        totalFeesCollected += feeAmount;
        delete s_requests[_requestId];

        if ( 
        isHead == true
        ) {
        payable(msg.sender).transfer(betAmount * 2);
        emit CoinFlip(msg.sender, "Heads you won", msg.value);
        }
        else {
        emit CoinFlip(msg.sender , "Tails you lost", msg.value);
        }

    }

    function fund() payable external {
    
    }

    function withdrawFunds(uint256 _amount) public {
    require(address(this).balance >= _amount, "insufficent funds");
    payable(msg.sender).transfer(_amount);
}





}