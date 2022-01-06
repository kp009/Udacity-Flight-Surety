import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import "regenerator-runtime/runtime.js";
const regeneratorRuntime = require("regenerator-runtime");

function randomDate(start, end) {
    return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}
export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.flights = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;

            /* this.airlines =  this.flightSuretyApp.methods.getRegisteredAirlines().call({ from: self.owner});

            if (!this.airlines || !this.airlines.length) {
                alert("There is no airline available");

            }*/
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }
              /* while(this.flights.length < 5) {
                this.flights.push({
                    airline: accts[counter++],
                    flight: "Flight" + Math.floor((Math.random() * 10) + 1),
                    timestamp: randomDate(new Date(), new Date(Date.now() + 1000 * 60 * 60 * 2)),
                })
            }*/

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }
    setOperatingStatus(mode, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .setOperatingStatus(mode)
            .send({from:self.owner})
                .then(console.log);
    }
    registerAirline(airlineAddress,airlineName, callback) {
        let self = this;
        let payload = {
            account: airlineAddress,
            name: airlineName,
            
        } 
        self.flightSuretyApp.methods
            .registerAirline(payload.account,payload.name)
            .send({ from: self.owner, gas: 6721900 }, (error, result) => {
                if (error) {
                    console.log(error);
                    callback(error, payload);
                } else {
                    self.flightSuretyApp.methods.
                    isAirlineRegistered(payload.account).call({ from: self.owner,gas: 6721900}, (error, result) => {
                        if (error || result.toString() === 'false') {
                            payload.message = 'New airline needs votes to get registered.';
                            payload.registered = false;
                            callback(error, payload);
                            console.log(payload.message);
                            console.log(result);
                        } else {
                            payload.message = 'Registered ' + payload.account + ' as ' + payload.name;
                            payload.registered = true;
                            callback(error, payload);
                            console.log(payload.message);
                            console.log(result);
                        }
                    });
                }
            });
    }
    isAirlineRegistered(airline, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isAirlineRegistered(airline)
            .call({ from: self.owner }, callback);
    }
    voteAirline(airline,name, callback) {
        let self = this;
        let payload = {            
            airline: airline,
            name: name
        }
        self.flightSuretyApp.methods
            .voteAirline(payload.airline, payload.name)
            .send({ from: self.owner, gas: 6721900 }, (error, result) => {
                callback(error, payload);
            });
    }
    isAirlineFunded(airline, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isAirlineSubmittedFunding(airline)
            .call({ from: self.owner }, callback);
    }
    fund(funds,airlineAddress, callback) {
        let self = this;
        
        self.flightSuretyApp.methods
            .fund()
            .send({ from: airlineAddress, value: this.web3.utils.toWei(funds, 'ether'), gas: 6721900},  (error, result) => {
                callback(error, result);
            });
           
    }
    registerFlight(airline,flight,timestamp,departure, callback){
        let self = this;      
        self.flightSuretyApp.methods.registerFlight(airline,flight,timestamp,departure)
            .send({ from: self.owner, gas: 6721900 }, (error, result) => {
                callback(error, result);
            });
    }
    buyInsurance(airline,flight,timestamp, insuranceValue, callback) {
        let self = this;
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: timestamp
        }
        self.flightSuretyApp.methods
            .buyInsurance(payload.airline, payload.flight, payload.timestamp)
            .send({from: self.owner, value: this.web3.utils.toWei(insuranceValue, "ether"), gas: 6721900}, (error, result) => {
                callback(error, result);
            });
    }
    withdrawCredits(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .withdrawal()
            .send({ from: self.owner, gas: 6721900}, (error, result) => {
                callback(error, result);
            });
    }
    fetchFlightStatus(airline,flight,timestamp, callback) {
        let self = this;
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: timestamp
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
          
    }
}