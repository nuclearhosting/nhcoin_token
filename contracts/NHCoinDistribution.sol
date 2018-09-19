pragma solidity ^0.4.24;

import './interfaces/IERC20.sol';
import './NHCoin.sol';
import './SafeMath.sol';
import './Ownable.sol';

contract NHCoinDistribution is Ownable {
  using SafeMath for uint256;

  NHCoin public NHC;

  uint256 private constant decimalFactor = 10**uint256(18);
  enum AllocationType { AIRDROP, ICO1, ICO2, FOUNDER, ADVISOR, BOUNTY, LEGAL, RESERVE, BONUS1, BONUS2 }
  
  uint256 public constant INITIAL_SUPPLY   = 420000000 * decimalFactor;
  uint256 public AVAILABLE_TOTAL_SUPPLY    = 420000000 * decimalFactor;
  uint256 public AVAILABLE_AIRDROP_SUPPLY  = 420000 * decimalFactor; // 100% Released at TD
  uint256 public AVAILABLE_ICO1_SUPPLY  =  42000000 * decimalFactor; // 100% Released at Token Distribution (TD)
  uint256 public AVAILABLE_ICO2_SUPPLY  =  126000000 * decimalFactor; // 100% Released at TD + 8 months
  uint256 public AVAILABLE_FOUNDER_SUPPLY  = 70980000 * decimalFactor; // 33% Released at TD + 1 year -> 100% at TD +3 years  
  uint256 public AVAILABLE_ADVISOR_SUPPLY  = 8400000 * decimalFactor; // 33% Released at TD +8 months  -> 100% at TD +2 years  
  uint256 public AVAILABLE_BOUNTY_SUPPLY  =  50400000 * decimalFactor; // 40% Released at TD +10 months -> 100% at TD +3 years
  uint256 public AVAILABLE_LEGAL_SUPPLY  =  25200000 * decimalFactor; // 20% Released at TD +8 months -> 100% at TD +2 years
  uint256 public AVAILABLE_RESERVE_SUPPLY  =  63000000 * decimalFactor; // 6.8% Released at TD +100 days -> 100% at TD +4 years
  // ICO1
  uint256 public AVAILABLE_BONUS1_SUPPLY  =    21000000 * decimalFactor; // 100% Released at Token Distribution (TD)
  // ICO2
  uint256 public AVAILABLE_BONUS2_SUPPLY  =    12600000 * decimalFactor; // 100% Released at TD +8months

  uint256 public grandTotalClaimed = 0;
  uint256 public startTime;

  // Allocation with vesting information
  struct Allocation {
    uint8 AllocationSupply; // Type of allocation
    uint256 endCliff;       // Tokens are locked until
    uint256 endVesting;     // This is when the tokens are fully unvested
    uint256 totalAllocated; // Total tokens allocated
    uint256 amountClaimed;  // Total tokens claimed
  }
  mapping (address => Allocation) public allocations;

  // List of admins
  mapping (address => bool) public airdropAdmins;

  // Keeps track of whether or not a 250 NHC airdrop has been made to a particular address
  mapping (address => bool) public airdrops;

  modifier onlyOwnerOrAdmin() {
    require(msg.sender == owner || airdropAdmins[msg.sender]);
    _;
  }

  event LogNewAllocation(address indexed _recipient, AllocationType indexed _fromSupply, uint256 _totalAllocated, uint256 _grandTotalAllocated);
  event LogNhcClaimed(address indexed _recipient, uint8 indexed _fromSupply, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);

  /**
    * @dev Constructor function - Set the nhc token address
    * @param _startTime The time when NHCoinDistribution goes live
    */
  function NHCDistribution(uint256 _startTime) public {
    require(_startTime >= now);
    require(INITIAL_SUPPLY == AVAILABLE_AIRDROP_SUPPLY.add(AVAILABLE_ICO1_SUPPLY).add(AVAILABLE_ICO2_SUPPLY).add(AVAILABLE_FOUNDER_SUPPLY).add(AVAILABLE_ADVISOR_SUPPLY).add(AVAILABLE_BONUS1_SUPPLY).add(AVAILABLE_BONUS2_SUPPLY).add(AVAILABLE_RESERVE_SUPPLY).add(AVAILABLE_BOUNTY_SUPPLY).add(AVAILABLE_LEGAL_SUPPLY));
    startTime = _startTime;
    NHC = new NHCoin(this);
  }

  /**
    * @dev Allow the owner of the contract to assign a new allocation
    * @param _recipient The recipient of the allocation
    * @param _totalAllocated The total amount of NHC available to the receipient (after vesting)
    * @param _supply The NHC supply the allocation will be taken from
    */
  function setAllocation (address _recipient, uint256 _totalAllocated, AllocationType _supply) onlyOwner public {
    require(allocations[_recipient].totalAllocated == 0 && _totalAllocated > 0);

    require(_recipient != address(0));
    
    if(_supply == AllocationType.ICO1) {
      AVAILABLE_ICO1_SUPPLY = AVAILABLE_ICO1_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.ICO1), 0, 0, _totalAllocated, 0);
    } else if (_supply == AllocationType.ICO2) {
      AVAILABLE_ICO2_SUPPLY = AVAILABLE_ICO2_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.ICO2), startTime + 32 weeks, startTime + 32 weeks, _totalAllocated, 0);
    } else if (_supply == AllocationType.FOUNDER) {
      AVAILABLE_FOUNDER_SUPPLY = AVAILABLE_FOUNDER_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.FOUNDER), startTime + 1 years, startTime + 3 years, _totalAllocated, 0);
    } else if (_supply == AllocationType.ADVISOR) {
      AVAILABLE_ADVISOR_SUPPLY = AVAILABLE_ADVISOR_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.ADVISOR), startTime + 32 weeks, startTime + 2 years, _totalAllocated, 0);
    } else if (_supply == AllocationType.BOUNTY) {
      AVAILABLE_BOUNTY_SUPPLY = AVAILABLE_BOUNTY_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.BOUNTY), startTime + 40 weeks, startTime + 3 years, _totalAllocated, 0);
    } else if (_supply == AllocationType.LEGAL) {
      AVAILABLE_LEGAL_SUPPLY = AVAILABLE_LEGAL_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.LEGAL), startTime + 32 weeks, startTime + 2 years, _totalAllocated, 0);
    } else if (_supply == AllocationType.RESERVE) {
      AVAILABLE_RESERVE_SUPPLY = AVAILABLE_RESERVE_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.RESERVE), startTime + 100 days, startTime + 4 years, _totalAllocated, 0);
    } else if (_supply == AllocationType.BONUS1) {
      AVAILABLE_BONUS1_SUPPLY = AVAILABLE_BONUS1_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.BONUS1), 0, 0, _totalAllocated, 0);
    } else if (_supply == AllocationType.BONUS2) {
      AVAILABLE_BONUS2_SUPPLY = AVAILABLE_BONUS2_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.BONUS2), startTime + 32 weeks, startTime + 32 weeks, _totalAllocated, 0);
    }
    // sem doplnit to co sa neminie v bonus1m bonus2 a ico a airdrop previest na reservu

    AVAILABLE_TOTAL_SUPPLY = AVAILABLE_TOTAL_SUPPLY.sub(_totalAllocated);
    LogNewAllocation(_recipient, _supply, _totalAllocated, grandTotalAllocated());
  }

  /**
    * @dev Add an airdrop admin
    */
  function setAirdropAdmin(address _admin, bool _isAdmin) public onlyOwner {
    airdropAdmins[_admin] = _isAdmin;
  }

  /**
    * @dev perform a transfer of allocations
    * @param _recipient is a list of recipients
    */
  function airdropTokens(address[] _recipient) public onlyOwnerOrAdmin {
    require(now >= startTime);
    uint airdropped;
    for(uint256 i = 0; i< _recipient.length; i++)
    {
        if (!airdrops[_recipient[i]]) {
          airdrops[_recipient[i]] = true;
          require(NHC.transfer(_recipient[i], 250 * decimalFactor));
          airdropped = airdropped.add(250 * decimalFactor);
        }
    }
    AVAILABLE_AIRDROP_SUPPLY = AVAILABLE_AIRDROP_SUPPLY.sub(airdropped);
    AVAILABLE_TOTAL_SUPPLY = AVAILABLE_TOTAL_SUPPLY.sub(airdropped);
    grandTotalClaimed = grandTotalClaimed.add(airdropped);
  }

  /**
    * @dev Transfer a recipients available allocation to their address
    * @param _recipient The address to withdraw tokens for
    */
  function transferTokens (address _recipient) public {
    require(allocations[_recipient].amountClaimed < allocations[_recipient].totalAllocated);
    require(now >= allocations[_recipient].endCliff);
    require(now >= startTime);
    uint256 newAmountClaimed;
    if (allocations[_recipient].endVesting > now) {
      // Transfer available amount based on vesting schedule and allocation
      newAmountClaimed = allocations[_recipient].totalAllocated.mul(now.sub(startTime)).div(allocations[_recipient].endVesting.sub(startTime));
    } else {
      // Transfer total allocated (minus previously claimed tokens)
      newAmountClaimed = allocations[_recipient].totalAllocated;
    }
    uint256 tokensToTransfer = newAmountClaimed.sub(allocations[_recipient].amountClaimed);
    allocations[_recipient].amountClaimed = newAmountClaimed;
    require(NHC.transfer(_recipient, tokensToTransfer));
    grandTotalClaimed = grandTotalClaimed.add(tokensToTransfer);
    LogNhcClaimed(_recipient, allocations[_recipient].AllocationSupply, tokensToTransfer, newAmountClaimed, grandTotalClaimed);
  }

  // Returns the amount of NHC allocated
  function grandTotalAllocated() public view returns (uint256) {
    return INITIAL_SUPPLY - AVAILABLE_TOTAL_SUPPLY;
  }

  // Allow transfer of accidentally sent ERC20 tokens
  function refundTokens(address _recipient, address _token) public onlyOwner {
    require(_token != address(NHC));
    IERC20 token = IERC20(_token);
    uint256 balance = token.balanceOf(this);
    require(token.transfer(_recipient, balance));
  }

    function () public payable {
        //if ether is sent to this address, send it back.
        throw;
    }
}