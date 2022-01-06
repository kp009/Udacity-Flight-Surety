import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';

import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.appAddress);
let oracles = 20;
let registeredOracles = [];
let STATUS_CODES = [0, 10, 20, 30, 40, 50];
let statuscode = 20;


web3.eth.getAccounts((error, accounts) => {
    for(let i = 0; i < oracles; i++) {
      flightSuretyApp.methods.registerOracle()
      .send({from: accounts[i], value: web3.utils.toWei("1",'ether'), gas: 6721900}, (error, result) => {
        flightSuretyApp.methods.getMyIndexes().call({from: accounts[i]}, (error, result) => {
          let oracle = {
            address: accounts[i],
            index: result
          };
          registeredOracles.push(oracle);
          console.log("ORACLE REGISTERED: " + JSON.stringify(oracle));
        });
      });
    };
});
function simulateOracleResponse(requestedIndex, airline, flight, timestamp) {	
  web3.eth.getAccounts((error, accounts) => {
   console.log(registeredOracles.length);
   console.log(requestedIndex);
    for(let i = 0; i < registeredOracles.length; i++) {
         try {
            if(registeredOracles[i].index.includes(requestedIndex)) {	
                console.log(registeredOracles[i].index)	
					//console.log("Submitting Oracle response For Flight: " + flight + " at Index: " + registeredOracles[i].index);
					 flightSuretyApp.methods.submitOracleResponse(requestedIndex, airline, flight, timestamp, statuscode)
                     .send({ from: registeredOracles[i].address, gas: 6721900 }, (error, result) => {
                        console.log("FROM " + JSON.stringify(registeredOracles[i]) + "STATUS CODE: " + 20 );

                    });
                   
				}
			} catch (e) {
				console.log(e);
			}
		}
	
    
    });
}


flightSuretyApp.events.OracleRequest({}).on('data',  (event, error) => {
	if (!error) {
		 simulateOracleResponse(
			event.returnValues[0],
			event.returnValues[1],
			event.returnValues[2],
			event.returnValues[3] 
		);
	}
});

flightSuretyApp.events.FlightStatusInfo({}).on('data',  (event, error) => {
	console.log("event=", event);
	console.log("error=", error);
});

flightSuretyData.events.allEvents({
  fromBlock: "latest"
}, function (error, event) {
  if (error){
    console.log("error");
    console.log(error);
  }  else {
    console.log("event:");
    console.log(event);
  }
});


const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


