const Market  = artifacts.require('Market');
const web3 = Market.web3
const market = artifacts.require('Market');
const utils = require('./utils')
const BN = web3.utils.BN;
const { ether, toHex, toWei } = require('./utils/ethTools');
const { assertRevert } =  require('./utils/assertRevert')

// const deployPlotusToken = (owners,  tokenPrice,  supply ,names , symbols , decimals) => {
//     return PlotusToken.new(owners,  tokenPrice,  supply ,names , symbols , decimals)
// }
const deployMarket = (owners,uintparams, feedsource, stockName,addressParams) => {
    return Market.new(owners,uintparams, feedsource, stockName,addressParams)
}
// const BN = web3.utils.BN;
// const utils = require('./utils')
const ONE_DAY = 24*3600

contract('Market', function([
  user1,
  user2,
  user3,
  user4,
  user5,
  user6,
  user7,
  user8,
  user9,
  operator2,
  operator
]) {
  let MarketInstance 
    let nowTime = new Date()/1000;
    nowTime = parseInt(nowTime);
    let thenTime = new BN(((nowTime/1+(3600)).toString()));
    const uintparams = [nowTime,thenTime,1,2,1,7,1000000000000000,10000,2,2,100]
    const feedsource  = "jonas"
    const stockName = "0x47"
    const addressParams = ["0x81A69EE30637601356ff15d6c4a905079b53FCE1","0x81A69EE30637601356ff15d6c4a905079b53FCE1"]
    beforeEach(async () => {
        marketInstance = await Market.deployed()
        // console.log(marketInstance.address)
        assert.ok(marketInstance)
    })

    it('set price of option',async function() {

      await marketInstance.setPrice(1,10);
      const getPrice = await marketInstance.getPrice(1);
      assert.equal(getPrice/1,10);
      await marketInstance.setPrice(2,20);
      const getPrice1 = await marketInstance.getPrice(2);
      assert.equal(getPrice1/1,20);
      await marketInstance.setPrice(3,30);
      const getPrice2 = await marketInstance.getPrice(3);
      assert.equal(getPrice2/1,30);
      await marketInstance.setPrice(4,40);
      const getPrice3 = await marketInstance.getPrice(4);
      assert.equal(getPrice3/1,40);
      await marketInstance.setPrice(1,50);
      const getPrice4 = await marketInstance.getPrice(1);
      assert.equal(getPrice4/1,50);
      await marketInstance.setPrice(2,20);
      const getPrice5 = await marketInstance.getPrice(2);
      assert.equal(getPrice5/1,20);
      await marketInstance.setPrice(5,30);
      const getPrice6 = await marketInstance.getPrice(5);
      assert.equal(getPrice6/1,30);
      await marketInstance.setPrice(6,20);
      const getPrice7 = await marketInstance.getPrice(6);
      assert.equal(getPrice7/1,20);
      await marketInstance.setPrice(7,50);
      const getPrice8= await marketInstance.getPrice(7);
      assert.equal(getPrice8/1,50);
      })

    it('user bet points',async function() {
      // await marketInstance.setPrice(7,10);
      // const getPrice = await marketInstance.getPrice(7);
      await marketInstance.placeBet(1,{value: 4,from: user1});
      await marketInstance.placeBet(2,{value: 6,from: user2});
      await marketInstance.placeBet(3,{value: 2,from: user3});
      await marketInstance.placeBet(4,{value: 4,from: user4});
      await marketInstance.placeBet(1,{value: 3,from: user5});
      await marketInstance.placeBet(2,{value: 2,from: user6});
      await marketInstance.placeBet(5,{value: 5,from: user7});
      await marketInstance.placeBet(6,{value: 5,from: user8});
      await marketInstance.placeBet(7,{value: 7,from: user9});
      const getbrttingpoint  = await marketInstance.userBettingPoints(user1,1);
      const getbrttingpoint1 = await marketInstance.userBettingPoints(user2,2);
      const getbrttingpoint2 = await marketInstance.userBettingPoints(user3,3);
      const getbrttingpoint3 = await marketInstance.userBettingPoints(user4,4);
      const getbrttingpoint4 = await marketInstance.userBettingPoints(user5,1);
      const getbrttingpoint5 = await marketInstance.userBettingPoints(user6,2);
      const getbrttingpoint6 = await marketInstance.userBettingPoints(user7,5);
      const getbrttingpoint7 = await marketInstance.userBettingPoints(user8,6);
      const getbrttingpoint8 = await marketInstance.userBettingPoints(user9,7);
      console.log("user1",getbrttingpoint/1)
      assert.equal(getbrttingpoint/1,400);
      console.log("user2",getbrttingpoint1/1)
      assert.equal(getbrttingpoint1/1,300);
      console.log("user3",getbrttingpoint2/1)
      assert.equal(getbrttingpoint2/1,66.66);
      console.log("user4",getbrttingpoint3/1)
      assert.equal(getbrttingpoint3/1,100);
      console.log("user5",getbrttingpoint4/1)
      assert.equal(getbrttingpoint4/1,60);
      console.log("user6",getbrttingpoint5/1)
      assert.equal(getbrttingpoint5/1,100);
      console.log("user7",getbrttingpoint6/1)
      assert.equal(getbrttingpoint6/1,166.666);
      console.log("user8",getbrttingpoint7/1)
      assert.equal(getbrttingpoint7/1,250);
      console.log("user9",getbrttingpoint8/1)
      assert.equal(getbrttingpoint8/1,140);
    }) 
     
})