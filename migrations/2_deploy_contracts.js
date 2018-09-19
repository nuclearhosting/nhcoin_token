var NHCoin = artifacts.require('./NHCoin.sol');
var NHCoinDistribution = artifacts.require('./NHCoinDistribution.sol');

module.exports = async (deployer, network) => {
  let _now = Date.now();
  let _fromNow = 60 * 5 * 1000; // Start distribution in 1 hour
  let _startTime = (_now + _fromNow) / 1000;
  await deployer.deploy(NHCoinDistribution, _startTime);
  console.log(`
    ---------------------------------------------------------------
    --------- NHCOIN (NHC) TOKEN SUCCESSFULLY DEPLOYED ---------
    ---------------------------------------------------------------
    - Contract address: ${NHCoinDistribution.address}
    - Distribution starts in: ${_fromNow/1000/60} minutes
    - Local Time: ${new Date(_now + _fromNow)}
    ---------------------------------------------------------------
  `);
};
