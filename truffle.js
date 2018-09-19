module.exports = {
  networks: {
   development: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
      from: "0x8FffE46f1879CBB4ee6708f064c15E51AdD27135",
      gas: 3500000,
    }, 
   ropsten: {
      host: 'localhost',
      port: 8545,
      network_id: '3', // Match any network id
      from: "0x6cd2a3e36f922dbd1001ae9db78fc43e32a97806",
      gas: 4712000,
    },
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
