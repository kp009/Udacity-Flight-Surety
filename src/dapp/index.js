
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);        
           
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
        //Register Airline
        
        DOM.elid('register-airline').addEventListener('click', () => {           
            let airlineAddress = DOM.elid('airline-address').value;
            let airlineName = DOM.elid('airline-name').value;
            contract.registerAirline(airlineAddress, airlineName, (error, result) => {
                alert("Airline was successfully registered.");
                console.log(result);
               // displayTx('display-wrapper-register', [{ label: 'Airline registered', error: error, value: result }]);
                display('Airlines', 'Register Airlines', [{ label: 'Airline registered', error: error, value: result.message}]);                
                DOM.elid('airline-address').value = "";          
                DOM.elid('airline-name').value = "";     
                //displayListAirline(airline, DOM.elid("airline-address"));  
            });
        })
        DOM.elid('isAirlineRegistered').addEventListener('click', () => {
            let airlineAddress = DOM.elid('airline-address').value;
            contract.isAirlineRegistered(airlineAddress, (error, result) => {
                displayTx('display-wrapper-register', [{ label: 'Is Airline registered', error: error, value: result }]);
                DOM.elid('airline-fund-address').value = "";
            });
        })
        DOM.elid('vote-airline').addEventListener('click', () => {
            let airlineAddress = DOM.elid('airline-address').value;
            let airlineName = DOM.elid('airline-name').value;
            contract.voteAirline(airlineAddress,airlineName, (error, result) => {
               // displayTx('display-wrapper-register', [{ label: 'Airline voted Tx', error: error, value: result }]);
                display('', 'Voted airline address: ', [ { label: 'Voted Airline', error: error, value: result.airline } ]);
                DOM.elid('airline-address').value = "";
            });
        })
       
        DOM.elid('fund-airline').addEventListener('click', () => {
            let funds = DOM.elid('airline-funds').value;
            let airlineAddress = DOM.elid('airline-fund-address').value;
            // Write transaction
            contract.fund(funds,airlineAddress, (error, result) => {
                alert("Airline was successfully funded.");
                console.log(result);
                displayTx('display-wrapper-register', [{ label: 'Airline funded', error: error, value: result }]);
                display('Airline', 'funds', [ { label: ' Added Funds', error: error, value: result + '.' } ]);
            });            
        })
        DOM.elid('isAirlineFunded').addEventListener('click', () => {
            let airlineAddress = DOM.elid('airline-fund-address').value;
            contract.isAirlineFunded(airlineAddress, (error, result) => {
                displayTx('display-wrapper-register', [{ label: 'Is Airline funded', error: error, value: result }]);
                DOM.elid('airline-fund-address').value = "";
            });
        })
        DOM.elid('register-flight').addEventListener('click', () => {
            let flight = DOM.elid('flight').value;
            let airline =  DOM.elid('airline').value;
            let timestamp = DOM.elid('timestamp').value;
            let departure = DOM.elid('departure').value;
            contract.registerFlight(airline,flight,timestamp,departure, (error, result) => {
                displayTx('display-wrapper-register', [{ label: 'Flight registered Tx', error: error, value: result}]);
                //display('', 'New flight number : ', [ { label: 'Register Airline', error: error, value: result.flight + ' ' + result.airline } ]);
                //DOM.elid('airline-fund-address').value = "";
            });
        })
    
        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight').value;
            let airline =  DOM.elid('airline').value;
            let timestamp = DOM.elid('timestamp').value;           
            // Write transaction
            contract.fetchFlightStatus(airline,flight,timestamp, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });            
        })
        DOM.elid('buy-insurance').addEventListener('click', () => {
           // let flightSelection = document.getElementById("flight");
           // let flight = flightSelection.options[flightSelection.selectedIndex].value;
           let flight =  DOM.elid('flight').value;
            let insuranceValue = DOM.elid('insurance').value;
            let airline =  DOM.elid('airline').value;
            let timestamp = DOM.elid('timestamp').value;   
            contract.buyInsurance(airline,flight,timestamp, insuranceValue, (error, result) => {
                alert("flight was successfully insured.");
                console.log(result);
                display('Passenger', 'Buy insurance', [ { label: 'Paid Insurance', error: error, value: result} ]);
            });
        })
        DOM.elid('withdraw-credits').addEventListener('click', () => {
            contract.withdrawCredits((error, result) => {
                console.log(result);
                display('Passenger', 'Withdraw credits', [ { label: 'Credited', error: error, value: result} ]);
            });
        })
        /*DOM.elid('List').addEventListener('Flight()', () => {
            // let flightSelection = document.getElementById("flight");
            // let flight = flightSelection.options[flightSelection.selectedIndex].value;
            var list = document.getElementById("List");
            document.getElementById("flight").value = list.options[list.selectedIndex].text;
        });*/


    
    });
    

})();

function displayTx(id, results) {
    let displayDiv = DOM.elid(id);
    results.map((result) => {
        let row = displayDiv.appendChild(DOM.div({ className: 'row' }));
        row.appendChild(DOM.div({ className: 'col-sm-3 field' }, result.error ? result.label + " Error" : result.label));
        row.appendChild(DOM.div({ className: 'col-sm-9 field-value' }, result.error ? String(result.error) : String(result.value)));
        displayDiv.appendChild(row);
    })
}
function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







