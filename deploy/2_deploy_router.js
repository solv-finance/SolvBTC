const transparentUpgrade = require("./utils/transparentUpgrade");
const gasTracker = require("./utils/gasTracker");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const gasPrice = await gasTracker.getGasPrice(network.name);

  const governor = deployer;
  const market = {
    localhost: "0xdbb35Ba81Dcba6AeC3a28ec127da434A0069A950",
    dev_goerli: "0xdbb35Ba81Dcba6AeC3a28ec127da434A0069A950",
    dev_sepolia: "0x109198Eb8BD3064Efa5d0711b505f59cFd77de18",
    goerli: "0x2266dc69c2FaCD493C43a52E7c2131f2dF509287",
    sepolia: "0x91967806F47e2c6603C9617efd5cc91Bc2A7473E",
    merlin_test: "0xA853A738d3D86e1cd24b79bdB16916F57e8F9886",
    ailayer_test: "0x60680f8921E50c25A8030F4175C5d12C91Ee1Fe9",

    arb: "0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8",
    mantle: "0x1210371F2E26a74827F250afDfdbE3091304a3b7",
    mainnet: "0x57bB6a8563a8e8478391C79F3F433C6BA077c567",
    merlin: "0x59Cf3db95bdF5C545877871c3863c9DBe6b0b7cf",
    bsc: "0xaE050694c137aD777611286C316E5FDda58242F3",
    ailayer: "0x59Cf3db95bdF5C545877871c3863c9DBe6b0b7cf",
    avax: "0x59Cf3db95bdF5C545877871c3863c9DBe6b0b7cf",
  };
  const factory = (await deployments.get("SftWrappedTokenFactory")).address;

  const contractName = "SftWrapRouter";
  const firstImplName = contractName + "Impl";
  const proxyName = contractName + "Proxy";

  const versions = {
    dev_sepolia: ["v1.1"],
    sepolia: ["v1.1"],
    arb: ["v1.1"],
    bsc: ["v1.1"],
    merlin: ["v1.1"],
    mainnet: [], //start with v1.1,
    ailayer: [], //start with v1.1,
  };

  const upgrades =
    versions[network.name]?.map((v) => {
      return firstImplName + "_" + v;
    }) || [];

  const { proxy, newImpl, newImplName } =
    await transparentUpgrade.deployOrUpgrade(
      firstImplName,
      proxyName,
      {
        contract: contractName,
        from: deployer,
        gasPrice: gasPrice,
        log: true,
      },
      {
        initializer: {
          method: "initialize",
          args: [governor, market[network.name], factory],
        },
        upgrades: upgrades,
      }
    );
};

module.exports.tags = ["SftWrapRouter"];
