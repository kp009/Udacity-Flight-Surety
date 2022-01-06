pragma solidity >=0.4.25 <0.9.0;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
      
    struct Airline {
        bool isRegistered;        
        string name;
        bool issubmittedFunding;
        uint256 votes;
        address airline;
    }
    address[] private RegisteredAirlines; 
    
    mapping(address => Airline) airlines;   // Mapping for storing registered airlines
    mapping(address => Airline) private pendingAirlines;
    mapping(address => uint256) private authorizedContracts;

     struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
        string flight;
        string departure;
    }
    mapping(bytes32 => Flight) private flights;
     uint8 private constant STATUS_CODE_UNKNOWN = 0;
     bytes32[] public RegisteredFlights; 
    

    struct Insurance{
       address passenger;     
       uint256 amount;
    }     
    mapping(bytes32 => Insurance[]) private insurances;
    mapping(address => uint256) private credits;
   
    uint256 private constant CREDIT_MULTIPLIER = 15;
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event AirlineRegistered(address airline);
    event AirlineFunded(address airline);
    event FlightRegistered(bytes32 flightkey);
    event BoughtInsurance( bytes32 flightkey, address passenger, uint256 amount);
    event PassengerCredited(bytes32 flightkey, address passenger, uint256 amount);
    event PassengerPaid(address passenger, uint256 bal);
    
    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        
        airlines[msg.sender] = Airline({
                                                isRegistered: true,                                       
                                                name: "UdacityAirlines",                        
                                                issubmittedFunding: false,                                               
                                                votes: 1 ,
                                                airline: msg.sender                                              
                                            });
        RegisteredAirlines.push(msg.sender);         
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
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
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
    /**
    * @dev Modifier that requires the calling App contract has been authorized
    */
    modifier requireIsCallerAuthorized()
    {
        require(authorizedContracts[msg.sender] == 1, "Caller is not an authorized contract");
        _;
    }
     modifier requireAirlineRegistration(address airline)
    {        
        require(airlines[airline].isRegistered, "Airline is not registered.");

        _;
    }
    
  
     modifier requireAirlineSubmissionOfFunds(address airline)
    {        
        require(airlines[airline].issubmittedFunding, "Airline not submitted funding.");

        _;
    }
    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view                                                        
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner
    {
        operational = mode;
       
    }
    

    /**
    * @dev Check if an Airline is registered
    *
    * @return A bool that indicates if the Airline is registered
    */   
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
        return airlines[airline].isRegistered;
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
        return (airlines[airline].issubmittedFunding);
        
    }
    function isAirlinePending
                            (
                                address airline
                            )
                            external
                            view
                            returns(bool)
    {
        return pendingAirlines[airline].airline != address(0);
    }
    
    function authorizeCaller
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
    {
        authorizedContracts[contractAddress] = 1;
    }

    function deauthorizeCaller
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
    {
        delete authorizedContracts[contractAddress];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (  
                                address airline,                                
                                string  name
                            )
                            public
                            requireIsOperational
                            returns (bool)
    {
        require(airline != address(0), "'account' must be a valid address.");
        require(!airlines[airline].isRegistered, "Airline is already registered.");       

        airlines[airline] = Airline({
                                                isRegistered: true,                                       
                                                name: name,                                      
                                                issubmittedFunding: false,                                                
                                                votes: 1,
                                                airline: airline                                               
                                            });
        RegisteredAirlines.push(airline);   
        emit AirlineRegistered(airline);     
        return true;
    }
     function pendingAirline
                            ( 
                              
                               address airline,
                               string name
                            )
                                public
                                requireIsOperational
                               
    {
        pendingAirlines[airline] = Airline({
                                                isRegistered: false,                                       
                                                name: name,                                      
                                                issubmittedFunding: false,                                                
                                                votes: 1,
                                                airline: airline                                               
                                            });
    }
     function getVoted(address airline, string name) public requireIsOperational returns (uint256){       
        pendingAirlines[airline].votes = pendingAirlines[airline].votes.add(1);
        if (pendingAirlines[airline].votes >= getRegisteredAirlineCount().div((2))) {                   
            registerAirline(airline, name); 
            delete pendingAirlines[airline];
        }
        else {
            getVoted(airline, name);
        }
          
        return pendingAirlines[airline].votes;
    }   

     
    function getRegisteredAirlineCount() public view returns(uint256) {
        return RegisteredAirlines.length;
    }
        function getRegisteredAirlines() requireIsOperational public view returns(address[]){
        return RegisteredAirlines;
    }
      
   /**
    * @dev Add a future flight for insuring.
    *
    */  
    function registerFlight
                                (
                                    bytes32 flightkey,
                                    address airline,
                                    string  flight,
                                    uint256 timestamp,
                                    string departure
                                    
                                )
                                external
                                requireIsOperational
                                
    {
        require(airlines[airline].issubmittedFunding, "Airline is funded");       
        flights[flightkey] = Flight({isRegistered: true, statusCode: STATUS_CODE_UNKNOWN, updatedTimestamp: timestamp, airline: airline, flight: flight , departure: departure});                
        RegisteredFlights.push(flightkey);    
        emit FlightRegistered(flightkey);         
    }
     function getRegisteredFlightCount() public view returns(uint256) {
        return RegisteredFlights.length;
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (   
                                bytes32 flightKey,
                                address passenger,                                
                                uint256 amount
                            )
                            external
                            payable
                            requireIsOperational                            
                            

    {
    
        insurances[flightKey].push(
            Insurance({
                passenger: passenger,
                amount: amount
            })
        );
        emit BoughtInsurance(flightKey, passenger, amount);
       

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (   
                                    bytes32 flightKey                             
                                )
                                external
                                requireIsOperational
                                payable                               
    {        
        Insurance[] memory insuranceCredit = insurances[flightKey];
      
        for (uint i = 0; i < insuranceCredit.length; i++) {                                  
            // Calculate payout with multiplier and add to existing credits
            uint256 payout = (insuranceCredit[i].amount.mul(CREDIT_MULTIPLIER).div(10));
            credits[insuranceCredit[i].passenger] = credits[insuranceCredit[i].passenger].add(payout);
            emit PassengerCredited(flightKey, insuranceCredit[i].passenger, payout);
        }
        
        delete insurances[flightKey];
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address passenger
                            )
                            external
                             requireIsOperational
                             payable
                                                     
    {
       uint256 bal = credits[passenger];
        require(address(this).balance >= bal, "Contract has insufficient funds");
        require(bal > 0, "There are no funds for withdrawl");
        credits[passenger] = 0;
        address(passenger).transfer(bal);
        emit PassengerPaid(passenger, bal);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (  
                                address airline
                                
                            )
                            external 
                            payable                          
                            requireIsOperational
                                                      
    {   
        require(airlines[airline].isRegistered, "Airline is already registered.");             
        require(!airlines[airline].issubmittedFunding, "Airline is not funded");             
        airlines[airline].issubmittedFunding = true;        
        emit AirlineFunded(airline);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function () 
                            external 
                            payable 
    {
        //fund();
    }


}

