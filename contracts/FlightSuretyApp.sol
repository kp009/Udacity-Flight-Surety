// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../contracts/FlightSuretyData.sol";
/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    
    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
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
        string flight;
        string departure;
    }
    mapping(bytes32 => Flight) private flights;
    uint8 private constant Registered_Airlines_Threshhold = 4;
    uint256 private constant REGISTRATION_FEES = 10 ether;
    uint256 private constant MAX_INSURANCE = 1 ether;
    address[] multicalls = new address[](0);  
    
    // Contract Operational
    bool private operational = true;
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
    modifier requireIsOperational() 
    {
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
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address dataContract
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
       // registerAirline(contractOwner, "UdacityAirlines");
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() 
                            public 
                            view                            
                            returns(bool) 
    {        
        return operational;  
          // Modify to call data contract's status
    }
     function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    /*function setOperatingStatus
                            (
                                address dataContract
                            ) 
                            external
                            requireContractOwner
    {
        flightSuretyData = FlightSuretyData(dataContract);
       
    }*/
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/
    
    function isAirlineRegistered
                            (
                                address airline
                            )
                            public
                            view
                            requireIsOperational
                            returns(bool)
    {
        require(airline != address(0), "'airline' must be a valid address.");
        return flightSuretyData.isAirlineRegistered(airline);
    }
   function isAirlineSubmittedFunding
                            (
                                address airline
                            )
                            public
                            view
                            requireIsOperational
                            returns(bool)
    {
        require(airline != address(0), "'airline' must be a valid address.");          
        return flightSuretyData.isAirlineSubmittedFunding(airline);
    }
    function isAirlinePending
                            (
                                address airline
                            )
                            view
                            external
                            requireIsOperational
                            returns(bool)
    {
        return flightSuretyData.isAirlinePending(airline);
    }
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline
                            (  
                                address airline,
                                string  name
                            )
                            external
                            requireIsOperational
                            returns(bool success, uint256 votes)
    {
        require(airline != address(0), "'airline' must be a valid address.");        
        require(!flightSuretyData.isAirlineRegistered(airline), "Airline is  registered");
        require(flightSuretyData.isAirlineRegistered(msg.sender), "Airline is not registered");       
        require(flightSuretyData.isAirlineSubmittedFunding(msg.sender), "To vote airline should submit funds");

        //uint256 votes_required = flightSuretyData.getRegisteredAirlineCount().div(2);
        
        if (flightSuretyData.getRegisteredAirlineCount() <= Registered_Airlines_Threshhold)
        {
            success = flightSuretyData.registerAirline(airline, name);   
                  
        }
        else{
            
            flightSuretyData.pendingAirline(airline,name);
            //require(flightSuretyData.isAirlinePending(airline), "Airline is not pending. Voting is not required");
            ///votes = flightSuretyData.getVoted(airline,name);   
            success = false;         
       
        } 
           
        return (success, votes);
    }
      function voteAirline
                            (
                                address airline,
                                string name
                            )
                            external
                            requireIsOperational
                            returns(uint256)
    {
        require(flightSuretyData.isAirlineRegistered(msg.sender), "Sender is not an registered airline");
        require(flightSuretyData.isAirlineSubmittedFunding(msg.sender), "It is not possible to vote, the sender is not funded");
        require(flightSuretyData.isAirlinePending(airline), "Airline is not pending. Voting is not required");
        uint256 votes = flightSuretyData.getVoted(airline, name);
        return (votes);
    }
   function fund
                            (  
                                
                            )
                            external                            
                            requireIsOperational
                            payable                            
    {
        require(flightSuretyData.isAirlineRegistered(msg.sender), "Airline is not  registered");
        require(!flightSuretyData.isAirlineSubmittedFunding(msg.sender), "Airline is not funded");
        require(msg.value >= REGISTRATION_FEES, "Registration fee for airline is 10 ether ");       
        
        address(uint256(address(flightSuretyData))).transfer(REGISTRATION_FEES);
        flightSuretyData.fund(msg.sender);
    }
     function getRegisteredAirlineCount() public view returns(uint256) {
        return flightSuretyData.getRegisteredAirlineCount();
     }
     function getRegisteredAirlines() external view returns(address[]){
        return flightSuretyData.getRegisteredAirlines();
    }

   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight
                                (
                                    address airline,
                                    string  flight,
                                    uint256 timestamp,
                                    string departure
                                    
                                )
                                external
                               requireIsOperational
                                
    {
        bytes32 key = getFlightKey(airline, flight, timestamp);
        require(!flights[key].isRegistered, "flight is already registered" );
        require(flightSuretyData.isAirlineSubmittedFunding(airline), "Airline is funded");
        flightSuretyData.registerFlight(key,airline, flight, timestamp, departure);                   
    }
    function buyInsurance
    (
        address airline,
        string flight,
        uint256 timestamp
    )
        public
        payable
        requireIsOperational
        {
             bytes32 key = getFlightKey(airline, flight, timestamp);           
            require(msg.value < MAX_INSURANCE,"To insure a flight amount less than 1 ether is sufficient");           
            address(uint256(address(flightSuretyData))).transfer(msg.value);
           flightSuretyData.buy(key, msg.sender, msg.value);
        }
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                             requireIsOperational
    {  
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);     
      
         if(statusCode == STATUS_CODE_LATE_AIRLINE) {           
           flights[flightKey].statusCode = statusCode;           
            flightSuretyData.creditInsurees(flightKey);
        }

    }
    function withdrawal(
    )
        external
        requireIsOperational
    {
        flightSuretyData.pay(msg.sender);
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp                            
                        )
                        external
                        requireIsOperational
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    } 


// region ORACLE MANAGEMENT

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
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
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


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3])
    {
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
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}   


