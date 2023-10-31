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

    //
}

