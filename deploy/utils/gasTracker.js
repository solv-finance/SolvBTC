const request = require("request");
const { BigNumber } = require("ethers");

const get = (url) => {
  return new Promise((resolve, reject) => {
    request(url, (err, data) => {
      if (err) {
        reject(err);
      } else {
        if (data.statusCode == 200) {
          resolve(data.body);
        } else {
          reject(data.statusCode);
        }
      }
    });
  });
};
const getGasPrice = (network) => {
  const highest = process.env.gas_price_highest || 250;
  const increase = process.env.gas_price_increase || 1.1;
  const apiKey = process.env.ETHERSCAN_API_KEY;

  return new Promise(async (resolve, reject) => {
    let gasPrice;

    if (network == "mainnet") {
      const response = JSON.parse(
        await get(
          `https://api.etherscan.io/api?module=gastracker&action=gasoracle&apikey=${apiKey}`
        )
      );
      const currentGasPrice = Number(
        response["result"]["FastGasPrice"]
      ).toFixed(0);
      if (currentGasPrice > highest) {
        reject(
          `gasPrice ${currentGasPrice} gwei too high, abort, current highest ${highest} , use export gas_price_highest=xxx to set`
        );
      }
      gasPrice = (currentGasPrice * increase * 1e9).toFixed(0);
      console.log(
        "CurrentGasPrice is",
        currentGasPrice,
        "wei, increased to",
        gasPrice,
        "wei"
      );
    } else if (
      network == "dev_goerli" ||
      network == "goerli" ||
      network == "dev_sepolia" ||
      network == "sepolia"
    ) {
      const chain =
        network == "dev_goerli"
          ? "goerli"
          : "dev_sepolia"
          ? "sepolia"
          : network;
      const response = JSON.parse(
        await get(
          `https://api-${chain}.etherscan.io/api?module=proxy&action=eth_gasPrice&apikey=${apiKey}`
        )
      );
      const currentGasPrice = Number(response["result"]).toFixed(0);
      if (currentGasPrice / 1e9 > highest) {
        reject(
          `gasPrice ${gasPrice} gwei too high, abort, current highest ${highest} , use export gas_price_highest=xxx to set`
        );
      }

      if (currentGasPrice / 1e9 < 1) {
        gasPrice = (1e9 * increase).toFixed(0);
      } else {
        gasPrice = (currentGasPrice * increase).toFixed(0);
      }

      console.log(
        "CurrentGasPrice is",
        currentGasPrice,
        "wei, increased to",
        gasPrice,
        "wei"
      );
    } else {
      const defaultPrice = {
        bsc: 5e9,
        bsctest: 10e9,
        dev_mumbai: 4e9,
        mumbai: 4e9,
        polygon: 90e9,
        development: 30e9,
        testnet: 30e9,
        mantle_testnet: 1,
        ailayer_test: 0.1e9,
        ailayer: 0.06e9,
        merlin: 0.1e9,
        avax: 30e9,
      };
      if (defaultPrice[network] == undefined) {
        gasPrice = 5e9; //5 gwei
      } else {
        gasPrice = defaultPrice[network];
      }
    }
    console.log(`network ${network} gasPrice ${gasPrice}`);
    resolve(BigNumber.from("" + gasPrice));
  });
};

module.exports = {
  getGasPrice,
};
