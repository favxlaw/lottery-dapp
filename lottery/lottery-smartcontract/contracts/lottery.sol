// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

//Importing required libraries and contracts
import 'hardhat/console.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';

//Define the main contract and inheriting from VRFConsumerBase
contact LotteryGame is VRFConsumerBase{

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private lotteryId; //Counter for tracking lottery IDs
    mapping(uint256 => Lottery) private lotteries; //mapping to store lottery details
    mapping(bytes32 => uint256) private lotteryRandomnessRequest; // Mapping for storing randomness requests
    mapping(uint256 => mapping(address => uint256)) ppplayer; // Participating per player per lottery
    mapping(uint256 => uint256) playersCount; // Count of players in each lottery
    bytes32 private keyHash; // Chainlink VRF key hash
    uint256 private fee; // Chainlink VRF fee
    address private admin; //Address of the contract admin

    event RandomnessReequested(bytes32, uint256);
    event WinnerDeclared(bytes32, uint256, address);
    event PrizeIncreased (uint256, uint256);
    event LotteryCreated(uint256, uint256, uint256, uint256);

    enum LotteryState {Active, Finished}

    struct Lottery {
      uint256 lotteryId;
      address[] participants;
      uint256 ticketPrice;
      uint256 prize;
      address winner;
      LotteryState state;
      uint endDate;  
    }
    //Constructor to initialize contract variables
    constructor(address vrfCoordinator, address link, bytes32 _keyhash, uint _fee)
    VRFConsumerBase(vrfCoordinator, link)
    {
        keyHash = _keyhash;
        fee = _fee;
        admin = msg.sender; 
    }

    // Function to create a new lottery
    function createLottery(uint256 _ticketPrice, uint256 _seconds) payable public onlyAdmin {
        require(_ticketPrice > 0, 'Ticket price must be greater than 0');
        Lottery memory lottery = Lottery({
            lotteryId: lotteryId.current(),
            participants: new address[](0), // Initialize with an empty array
            prize: 0;
            ticketPrice: _ticketPrice,
            winner: address(0),
            state: LotteryState.Active,
            endDate: block.timestamp + _seconds * 1 seconds 
        });
        lotteries[lotteryId.current()] = lottery;
        lotteryId.increment();
        emit LotteryCreated(lottery.lotteryId, lottery.ticketPrice, lottery.ticketPrize, lottery.endDate);   
    }

    // Function for participants to enter the lottery 
    function participate(uint256 _lotteryId) payable public isActive(_lotteryId){
        lottery storage lottery = lotteries [_lotteryId];
         require(msg.value == 0.01 ether, "Please send exactly 0.01 ETH to participate");

        lottery.participants.push(msg.sender);
    lottery.prize = lottery.prize.add(msg.value);
    
    uint256 uniqueP = ppplayer[_lotteryId][msg.sender];
    if (uniqueP == 0) {
        playersCount[_lotteryId]++;
    }
    ppplayer[_lotteryId][msg.sender]++;
    
    emit PrizeIncreased(lottery.lotteryId, lottery.prize);
}

    // Function for participants to withdraw their winnings or remaining funds
        function withdraw(uint256 _lotteryId) external onlyInLottery(_lotteryId) onlyAfterEndTime(_lotteryId) {
            lottery storage currentLottery = lotteries[_lotteryId];
            require(currentLottery.state == LotteryState.Finished, "Lottery not finished");

            unit256 tickets = ppplayer[_lotteryId][msg.sender];
            require(tickets > 0, "No tickets to withdraw");

            uint256 share = currentLottery.prize.div(playersCount{_lotteryId}); //Calculate participant's share
            uint256 winnings = share.mul(tickets);

            //Transfer winnings to the participant
            payable(msg.sender).transfer(winnings);

            // Reset the participant's ticket count
            ppplayer[_lotteryId][msg.sender] =0;

            emit PrizeIncreased(_lotteryId, currentLottery.prize.sub(winnings));
        }

    //Function to Intiate the lotttery drawing process
    function startLottery(uint256 _lotteryId) external onlyAdmin onlyAfterEndTime(_lotteryId) {
        lottery storage currentLottery = lotteries[_lotteryId];
        require(currentLottery.state == LotteryState.Active, "Lottery not active");

        bytes32 requestId = lotteryRandomness(keyHash, fee);
        lotteryRandomnessRequest[requestId] = _lotteryId;

        emit RandomnessReequested(requestId, _lotteryId);
    }

    //function to declare Winner 
    function WinnerDeclared(uint256 _lotteryId, uint256 _randomness) external onlyAdmin{
        lottery storage currentLottery = lotteries[_lotteryId];
        require(currentLottery.state == LotteryState.Active, "Lottery not active" );
        require(block.timestamp >= currentLottery.endTime, "Lottery has not ended");

        address winner = pickWinner(_lotteryId, _randomness);

        // Distribute prize to the winner
        distributePrize(_lotteryId, winner);

        // Update lottery state
        currentLottery.state = LotteryState.Finished;

        emit WinnerDeclared(_lotteryId, winner);
    }

//Function to retrieve the list of players 
    function getPlayers(uint256 _lotteryId) external view returns (address[] memory) {
    address[] memory players = new address[](playersCount[_lotteryId]);

    uint256 index = 0;
    for (uint256 i = 0; i < playersCount[_lotteryId]; i++) {
        address player = getKeyByIndex(ppplayer[_lotteryId], i);
        players[index] = player;
        index++;
    }

    return players;
}

//Function to get Lottery Details function

    function getLotteryDetails(uint256 _lotteryId) external view returns (uint256, uint256, uint256, uint256, LotteryState) {
    lottery storage currentLottery = lotteries[_lotteryId];
    return (
        currentLottery.entryFee,
        currentLottery.duration,
        currentLottery.endTime,
        currentLottery.prize,
        currentLottery.state
    );
}


}

