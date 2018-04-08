module.exports = {
  networks: {
    ganache: {
      host: "localhost",
      port: 7545,
      network_id: "5777",
      gas: 6721975
    },
    ganache_cli: {
      host: "localhost",
      port: 8545,
      network_id: "*",
      gasPrice: 1,
      gas: 4700000000000000
    }
  }
};