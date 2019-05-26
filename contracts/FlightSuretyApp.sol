pragma solidity ^0.5.0;

/*
Requirement 1: Separation of concerns
[TODO] FlightSuretyData contract for data persistence
[TODO] FlightSuretyApp contract for app logic and oracles code
[TODO] DApp client for triggering contract calls
[TODO] Server app for simulating oracles

Requirement 2: Airlines
[DONE] Register first airline when contract is deployed
[TODO] Only existing airline may register a new airline until there are at least four airlines registered
[TODO] Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines
[TODO] Airline can be registered, but does not participate in contract until it submits funding of 10 ether

Requirement 3: Passengers
[TODO] Passengers may pay upto 1 ether for purchasing flight insurance
[TODO] Flight numbers and timestamps are fixed for the purpose of the project and can be defined in the DApp client
[TODO] If the flight is delayed due to airline fault, passenger receives credit of 1.5x the amount they paid
[TODO] Funds are transfered from contract to the passenger wallet only when they initiate a withdrawal

Requirement 4: Oracles
[TODO] Oracles are implemented as a server app
[TODO] Upon startup, 20+ oracles are registered and their assigned indexes are persisted in memory
[TODO] Client DApp is used to trigger request to update flight status generating OracleRequest event that is captured by server
[TODO] Server will loop through all registered oracles, identify those oracles for which the request applies, and respond by calling into app logic contract with the ropriate status code

Requirement 5: General
[TODO] Contracts must have operational status control
[TODO] Functions must fail fast - use require() at the start of functions
[TODO] Scaffolding code is provided but you are free to replace it with your own code

Separation of Concerns, Operational Control and “Fail Fast”
[TODO] Smart Contract Seperation: Smart Contract code is separated into multiple contracts: 1) FlightSuretyData.sol for data persistence, 2) FlightSuretyApp.sol for  logic and oracles code
[TODO] Dapp Created and Used for Contract Calls: A Dapp client has been created and is used for triggering contract calls. Client can be launched with “npm run dapp”  is available at http://localhost:8000. Specific contract calls: 1) Passenger can purchase insurance for flight, 2) Trigger contract to request flight status update
[TODO] Oracle Server Application: A server app has been created for simulating oracle behavior. Server can be launched with “npm run server”
[TODO] Operational status control is implemented in contracts: Students has implemented operational status control.
[TODO] Fail Fast Contract: Contract functions “fail fast” by having a majority of “require()” calls at the beginning of function body

Airlines
[DONE] Airline Contract Initialization: First airline is registered when contract is deployed.
[TODO] Multiparty Consensus: Only existing airline may register a new airline until there are at least four airlines registered (demonstrated either with Truffle test by making call from client Dapp)
[TODO] Multiparty Consensus: Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines (demonstrated either with ffle test or by making call from client Dapp)
[TODO] Airline Ante: Airline can be registered, but does not participate in contract until it submits funding of 10 ether  (demonstrated either with Truffle test or by [ng call from client Dapp)

Passengers
[TODO] Passenger Airline Choice: Passengers can choose from a fixed list of flight numbers and departure that are defined in the Dapp client
[TODO] Passenger Payment: Passengers may pay up to 1 ether for purchasing flight insurance.
[TODO] Passenger Repayment: If flight is delayed due to airline fault, passenger receives credit of 1.5X the amount they paid
[TODO] Passenger Withdraw: Passenger can withdraw any funds owed to them as a result of receiving credit for insurance payout
[TODO] Insurance Payouts: Insurance payouts are not sent directly to passenger’s wallet

Oracles (Server App)
[TODO] Functioning Oracle: Oracle functionality is implemented in the server app.
[TODO] Oracle Initialization: Upon startup, 20+ oracles are registered and their assigned indexes are persisted in memory
[TODO] Oracle Updates: Update flight status requests from client Dapp result in OracleRequest event emitted by Smart Contract that is captured by server (displays on [ole and handled in code)
[TODO] Oracle Functionality: Server will loop through all registered oracles, identify those oracles for which the OracleRequest event applies, and respond by calling into FlightSuretyApp contract with random status code of Unknown (0), On Time (10) or Late Airline (20), Late Weather (30), Late Technical (40), or Late Other (50)
*/

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
  using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

  /********************************************************************************************/
  /*                                       DATA VARIABLES                                     */
  /********************************************************************************************/

  // FlightSurety data contract
  FlightSuretyData flightSuretyData;

  // Flight status codees
  uint8 private constant STATUS_CODE_UNKNOWN = 0;
  uint8 private constant STATUS_CODE_ON_TIME = 10;
  uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
  uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
  uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
  uint8 private constant STATUS_CODE_LATE_OTHER = 50;

  address private contractOwner;          // Account used to deploy contract

  struct Flight {
    bool isRegistered;
    uint8 statusCode;
    uint256 updatedTimestamp;        
    address airline;
  }
  mapping(bytes32 => Flight) private flights;

  /********************************************************************************************/
  /*                                       CONSTRUCTOR                                        */
  /********************************************************************************************/

  /**
  * @dev Contract constructor
  *
  */
  constructor (address dataContract, address firstAirline) public {
    contractOwner = msg.sender;
    flightSuretyData = FlightSuretyData(dataContract);

    // Airline Contract Initialization: First airline is registered when contract is deployed
    registerAirline(firstAirline);
  }

  /********************************************************************************************/
  /*                                       FUNCTION MODIFIERS                                 */
  /********************************************************************************************/

  // Modifiers help avoid duplication of code. They are typically used to validate something
  // before a function is allowed to be executed.

  /**
  * @dev Modifier that requires the "operational" boolean variable to be "true"
  *      This is used on all state changing functions to pause the contract in 
  *      the event there is an issue that needs to be fixed
  */
  modifier requireIsOperational() {
    // Modify to call data contract's status
    require(flightSuretyData.isOperational(), "Contract is currently not operational");  
    _;  // All modifiers require an "_" which indicates where the function body will be added
  }

  /**
  * @dev Modifier that requires the "ContractOwner" account to be the function caller
  */
  modifier requireContractOwner()
  {
    require(msg.sender == contractOwner, "Caller is not contract owner");
    _;
  }

  /********************************************************************************************/
  /*                                       EVENT DEFINITIONS                                  */
  /********************************************************************************************/

  //TBD

  /********************************************************************************************/
  /*                                       UTILITY FUNCTIONS                                  */
  /********************************************************************************************/

  function isOperational() external view returns(bool) {
    return flightSuretyData.isOperational();
  }

  /********************************************************************************************/
  /*                                     SMART CONTRACT FUNCTIONS                             */
  /********************************************************************************************/

  /**
  * @dev Add an airline to the registration queue
  *
  */   
  function registerAirline(address airlineAddress) public requireIsOperational returns(bool success, uint256 votes) {
    return (success, 0);
  }


  /**
  * @dev Register a future flight for insuring.
  *
  */  
  function registerFlight() external requireIsOperational {

  }
  
  /**
  * @dev Called after oracle has updated flight status
  *
  */  
  function processFlightStatus(address airline, string memory flight, uint256 timestamp, uint8 statusCode) internal requireIsOperational {

  }

  // Generate a request for oracles to fetch flight information
  function fetchFlightStatus(address airline, string calldata flight, uint256 timestamp) external {
    uint8 index = getRandomIndex(msg.sender);

    // Generate a unique key for storing the request
    bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
    oracleResponses[key] = ResponseInfo({requester: msg.sender, isOpen: true});

    emit OracleRequest(index, airline, flight, timestamp);
  } 

  /********************************************************************************************/
  /*                                     ORACLE MANAGEMENT                                    */
  /********************************************************************************************/

  // Incremented to add pseudo-randomness at various points
  uint8 private nonce = 0;    

  // Fee to be paid when registering oracle
  uint256 public constant REGISTRATION_FEE = 1 ether;

  // Number of oracles that must respond for valid status
  uint256 private constant MIN_RESPONSES = 3;

  struct Oracle {
    bool isRegistered;
    uint8[3] indexes;        
  }

  // Track all registered oracles
  mapping(address => Oracle) private oracles;

  // Model for responses from oracles
  struct ResponseInfo {
    address requester;                              // Account that requested status
    bool isOpen;                                    // If open, oracle responses are accepted
    mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                    // This lets us group responses and identify
                                                    // the response that majority of the oracles
  }

  // Track all oracle responses
  // Key = hash(index, flight, timestamp)
  mapping(bytes32 => ResponseInfo) private oracleResponses;

  // Event fired each time an oracle submits a response
  event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

  event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

  // Event fired when flight status request is submitted
  // Oracles track this and if they have a matching index
  // they fetch data and submit a response
  event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

  // Register an oracle with the contract
  function registerOracle() external payable requireIsOperational {
    // Require registration fee
    require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

    uint8[3] memory indexes = generateIndexes(msg.sender);

    oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
  }

  function getMyIndexes() view external requireIsOperational returns(uint8[3] memory) {
    require(oracles[msg.sender].isRegistered, "Not registered as an oracle");
    return oracles[msg.sender].indexes;
  }

  // Called by oracle when a response is available to an outstanding request
  // For the response to be accepted, there must be a pending request that is open
  // and matches one of the three Indexes randomly assigned to the oracle at the
  // time of registration (i.e. uninvited oracles are not welcome)
  function submitOracleResponse(uint8 index, address airline, string calldata flight, uint256 timestamp, uint8 statusCode) external requireIsOperational {
    require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");

    bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
    require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

    oracleResponses[key].responses[statusCode].push(msg.sender);

    // Information isn't considered verified until at least MIN_RESPONSES
    // oracles respond with the *** same *** information
    emit OracleReport(airline, flight, timestamp, statusCode);
    if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {
      emit FlightStatusInfo(airline, flight, timestamp, statusCode);

      // Handle flight status as appropriate
      processFlightStatus(airline, flight, timestamp, statusCode);
    }
  }

  function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
    return keccak256(abi.encodePacked(airline, flight, timestamp));
  }

  // Returns array of three non-duplicating integers from 0-9
  function generateIndexes(address account) internal returns(uint8[3] memory) {
    uint8[3] memory indexes;
    indexes[0] = getRandomIndex(account);
    
    indexes[1] = indexes[0];
    while(indexes[1] == indexes[0]) {
      indexes[1] = getRandomIndex(account);
    }

    indexes[2] = indexes[1];
    while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
      indexes[2] = getRandomIndex(account);
    }

    return indexes;
  }

  // Returns array of three non-duplicating integers from 0-9
  function getRandomIndex(address account) internal returns (uint8) {
    uint8 maxValue = 10;

    // Pseudo random number...the incrementing nonce adds variation
    uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

    if (nonce > 250) {
      nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
    }

    return random;
  }
}   

// FlightSurety data contract interface
contract FlightSuretyData {
  function isOperational() external view returns(bool);

  // Airlines
  function registerAirline(address registeringAirline, address newAirline) external;
  function isAirline(address airline) external view returns(bool); 
}