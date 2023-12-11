const { ethers } = require('hardhat');
const { expect } = require('chai');

const UpgradeableBeaconBin = require('@openzeppelin/contracts/build/contracts/UpgradeableBeacon.json');

async function deploySftWrappedTokenFactory(deployer) {
  const swtFactoryFactory = await ethers.getContractFactory('SftWrappedTokenFactory', deployer);
  const swtFactory = await swtFactoryFactory.deploy();
  await swtFactory.deployed();
  return swtFactory;
}

async function loadUpgradeableBeacon(beaconAddress, deployer) {
  const beaconFactory = ethers.ContractFactory.fromSolidity(UpgradeableBeaconBin, deployer);
  return beaconFactory.attach(beaconAddress);
}

async function deploySftWrapperToken(deployer) {
  const swtFactory = await ethers.getContractFactory('SftWrappedToken', deployer);
  const swt = await swtFactory.deploy();
  await swt.deployed();
  return swt;
}

async function loadSftWrapperToken(tokenAddress, deployer) {
  const swtFactory = await ethers.getContractFactory('SftWrappedToken', deployer);
  return swtFactory.attach(tokenAddress);
}

describe('SftWrappedTokenFactory Test', () => {
  beforeEach(async function () {
    [ this.admin, this.governor, this.others ] = await ethers.getSigners();
    this.swtFactory = await deploySftWrappedTokenFactory(this.admin);
    await this.swtFactory.connect(this.admin).initialize(this.governor.address);
    this.swtImpl = await deploySftWrapperToken(this.admin);

    this.productType = 'Open-end Fund Share SFT Wrapped Token';
    this.productName = 'SWT GMX-USDT';
    this.productInfo = {
      tokenName: 'Wrapped SFT GMX-USDT',
      tokenSymbol: 'wsGMX-USDT',
      wrappedSft: '0x6089795791F539d664F403c4eFF099F48cE17C75',
      wrappedSlot: '74478457607957908294428532600056162401632272384233981914702302257179967829289',
      navOracle: '0x18937025Dffe1b5e9523aa35dEa0EE55dae9D675'
    }
  })

  it('test deploying new product', async function () {
    await this.swtFactory.connect(this.admin).setImplementation(this.productType, this.swtImpl.address);
    expect(await this.swtFactory.getImplementation(this.productType)).to.be.equal(this.swtImpl.address);

    await this.swtFactory.connect(this.admin).deployBeacon(this.productType);
    const beaconAddress = await this.swtFactory.getBeacon(this.productType);
    const beacon = await loadUpgradeableBeacon(beaconAddress, this.admin);
    expect(await beacon.implementation()).to.be.equal(this.swtImpl.address);

    await this.swtFactory.connect(this.governor).deployProductProxy(this.productType, this.productName, this.productInfo.tokenName, this.productInfo.tokenSymbol, this.productInfo.wrappedSft, this.productInfo.wrappedSlot, this.productInfo.navOracle);
    const proxyAddress = await this.swtFactory.getProxy(this.productType, this.productName);
    expect(await this.swtFactory.sftWrappedTokens(this.productInfo.wrappedSft, this.productInfo.wrappedSlot)).to.be.equal(proxyAddress);
    const sftWrappedTokenInfo = await this.swtFactory.sftWrappedTokenInfos(proxyAddress);
    expect(sftWrappedTokenInfo.name).to.be.equal(this.productInfo.tokenName);
    expect(sftWrappedTokenInfo.symbol).to.be.equal(this.productInfo.tokenSymbol);
    expect(sftWrappedTokenInfo.wrappedSft).to.be.equal(this.productInfo.wrappedSft);
    expect(sftWrappedTokenInfo.wrappedSftSlot).to.be.equal(this.productInfo.wrappedSlot);
    expect(sftWrappedTokenInfo.navOracle).to.be.equal(this.productInfo.navOracle);

    const swt = await loadSftWrapperToken(proxyAddress, this.governor);
    expect(await swt.name()).to.be.equal(this.productInfo.tokenName);
    expect(await swt.symbol()).to.be.equal(this.productInfo.tokenSymbol);
    expect(await swt.wrappedSftAddress()).to.be.equal(this.productInfo.wrappedSft);
    expect(await swt.wrappedSftSlot()).to.be.equal(this.productInfo.wrappedSlot);
    expect(await swt.navOracle()).to.be.equal(this.productInfo.navOracle);
  });

  it('test upgrading product', async function () {
    await this.swtFactory.connect(this.admin).setImplementation(this.productType, this.swtImpl.address);
    await this.swtFactory.connect(this.admin).deployBeacon(this.productType);
    const beaconAddress = await this.swtFactory.getBeacon(this.productType);
    const beacon = await loadUpgradeableBeacon(beaconAddress, this.admin);
    expect(await beacon.implementation()).to.be.equal(this.swtImpl.address);

    await this.swtFactory.connect(this.governor).deployProductProxy(this.productType, this.productName, this.productInfo.tokenName, this.productInfo.tokenSymbol, this.productInfo.wrappedSft, this.productInfo.wrappedSlot, this.productInfo.navOracle);
    const proxyAddress = await this.swtFactory.getProxy(this.productType, this.productName);
    
    const newSwtImpl = await deploySftWrapperToken(this.admin);
    await this.swtFactory.connect(this.admin).setImplementation(this.productType, newSwtImpl.address);
    await this.swtFactory.connect(this.admin).upgradeBeacon(this.productType);
    expect(await beacon.implementation()).to.be.equal(newSwtImpl.address);

    const swt = await loadSftWrapperToken(proxyAddress, this.governor);
    expect(await swt.name()).to.be.equal(this.productInfo.tokenName);
    expect(await swt.symbol()).to.be.equal(this.productInfo.tokenSymbol);
    expect(await swt.wrappedSftAddress()).to.be.equal(this.productInfo.wrappedSft);
    expect(await swt.wrappedSftSlot()).to.be.equal(this.productInfo.wrappedSlot);
    expect(await swt.navOracle()).to.be.equal(this.productInfo.navOracle);
  });

  it('test transferring beacon ownership', async function () {
    await this.swtFactory.connect(this.admin).setImplementation(this.productType, this.swtImpl.address);
    await this.swtFactory.connect(this.admin).deployBeacon(this.productType);
    const beaconAddress = await this.swtFactory.getBeacon(this.productType);
    const beacon = await loadUpgradeableBeacon(beaconAddress, this.admin);
    expect(await beacon.owner()).to.be.equal(this.swtFactory.address);

    await this.swtFactory.connect(this.admin).transferBeaconOwnership(this.productType, this.others.address);
    expect(await beacon.owner()).to.be.equal(this.others.address);

    await beacon.connect(this.others).transferOwnership(this.swtFactory.address);
    expect(await beacon.owner()).to.be.equal(this.swtFactory.address);
  });
})