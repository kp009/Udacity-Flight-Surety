var HDWalletProvider = require("@truffle/hdwallet-provider");
var mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

module.exports = {
  networks: {
    development: {
      /*provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },*/     
      host: "127.0.0.1",
      port: 8545,
      network_id: '*',     
      //gas: 9999999
      networkCheckTimeout: 1000000000,

      timeoutBlocks: 200000, 
    
      skipDryRun: true    
    
  },
},
  mocha: {
    //before_timeout: 500000 // <--- units in ms
    //enableTimeouts: false
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  },

};