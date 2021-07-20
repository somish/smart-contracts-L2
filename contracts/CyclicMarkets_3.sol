/* Copyright (C) 2021 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;

import "./CyclicMarkets_2.sol";
import "./interfaces/IOptionPricing.sol";

contract CyclicMarkets_3 is CyclicMarkets_2 {

    mapping(uint => address) public optionPricingContracts;
    mapping(uint => uint) public marketTypeOptionPricing;
    mapping(uint => uint32) public marketTypeSettlementTime;
    mapping(uint => uint) public marketOptionPricing;

    /**
    * @dev Set the option pricing contract for the market types which are already defined
    * Should be allowed to call only once by authorized address
    * @param _optionLengths Option lengths array
    * @param _optionPricingContracts Address of the contracts that holds the formulae of option pricing, respectively to the `_optionLengths` array 
    */
    function setOptionPricingContract(uint[] memory _optionLengths, address[] memory _optionPricingContracts) public onlyAuthorized {
      require(_optionPricingContracts.length == _optionLengths.length);
      for(uint i = 0;i<_optionLengths.length; i++) {
        require(_optionPricingContracts[i] != address(0));
        optionPricingContracts[_optionLengths[i]] = _optionPricingContracts[i];
      }
    }

    function addMarketType(uint32 _predictionTime, uint32 _optionRangePerc, uint32 _marketStartTime, uint32 _marketCooldownTime, uint32 _minTimePassed, uint64 _initialLiquidity) external onlyAuthorized {
      revert("Deprecated");
    }

    /**
    * @dev Add market type.
    * @param _optionLength Option length to be used for this markettype
    * @param _predictionTime The time duration of market.
    * @param _optionRangePerc Option range percent of neutral min, max options (raised by 2 decimals)
    * @param _marketStartTime Start time of first market to be created in this type
    * @param _marketCooldownTime Cool down time of the market after market is settled
    * @param _minTimePassed Minimum amount of time to be passed for the time factor to be kicked in while calculating option price
    * @param _initialLiquidity Initial liquidity to be provided by the market creator for the market.
    */
    function newMarketType(uint _optionLength, uint32 _predictionTime, uint32 _optionRangePerc, uint32 _marketStartTime, uint32 _marketSettleTime, uint32 _marketCooldownTime, uint32 _minTimePassed, uint64 _initialLiquidity) external onlyAuthorized {
      require(marketTypeArray[marketType[_predictionTime]].predictionTime != _predictionTime);
      require(_predictionTime > 0);
      require(_optionRangePerc > 0);
      require(_marketCooldownTime > 0);
      require(_marketSettleTime > 0);
      require(_minTimePassed > 0);
      require(optionPricingContracts[_optionLength] != address(0));
      uint32 index = _addMarketType(_predictionTime, _optionRangePerc, _marketCooldownTime, _minTimePassed, _initialLiquidity);
      marketTypeOptionPricing[index] = _optionLength;
      marketTypeSettlementTime[index] = _marketSettleTime;
      for(uint32 i = 0;i < marketCurrencies.length; i++) {
          marketCreationData[index][i].initialStartTime = _marketStartTime;
      }
    }

    function updateMarketType(uint32 _marketType, uint32 _optionRangePerc, uint32 _marketCooldownTime, uint32 _minTimePassed, uint64 _initialLiquidity) external onlyAuthorized {
      revert("Deperecated");
    }

    /**
    * @dev Update market type.
    * @param _marketType Index of the updating market type.
    * @param _optionLength Option length to be used for this markettype
    * @param _optionRangePerc Option range percent of neutral min, max options (raised by 2 decimals)
    * @param _marketCooldownTime Cool down time of the market after market is settled
    * @param _minTimePassed Minimum amount of time to be passed for the time factor to be kicked in while calculating option price
    * @param _initialLiquidity Initial liquidity to be provided by the market creator for the market.
    */
    function alterMarketType(uint32 _marketType, uint _optionLength, uint32 _optionRangePerc, uint32 _marketSettleTime, uint32 _marketCooldownTime, uint32 _minTimePassed, uint64 _initialLiquidity) external onlyAuthorized {
      require(_optionRangePerc > 0);
      require(_marketCooldownTime > 0);
      require(_marketSettleTime > 0);
      require(_minTimePassed > 0);
      require(optionPricingContracts[_optionLength] != address(0));
      MarketTypeData storage _marketTypeArray = marketTypeArray[_marketType];
      marketTypeOptionPricing[_marketType] = _optionLength;
      marketTypeSettlementTime[_marketType] = _marketSettleTime;
      require(_marketTypeArray.predictionTime != 0);
      _marketTypeArray.optionRangePerc = _optionRangePerc;
      _marketTypeArray.cooldownTime = _marketCooldownTime;
      _marketTypeArray.minTimePassed = _minTimePassed;
      _marketTypeArray.initialLiquidity = _initialLiquidity;
      emit MarketTypes(_marketType, _marketTypeArray.predictionTime, _marketCooldownTime, _optionRangePerc, true, _minTimePassed, _initialLiquidity);
    }

    /**
    * @dev Create the market.
    * @param _marketCurrencyIndex The index of market currency feed
    * @param _marketTypeIndex The time duration of market.
    * @param _roundId Round Id to settle previous market (If applicable, else pass 0)
    */
    function createMarket(uint32 _marketCurrencyIndex,uint32 _marketTypeIndex, uint80 _roundId) public {
      address _msgSenderAddress = _msgSender();
      require(isAuthorizedCreator[_msgSenderAddress], "Not authorized");
      MarketTypeData storage _marketType = marketTypeArray[_marketTypeIndex];
      MarketCurrency storage _marketCurrency = marketCurrencies[_marketCurrencyIndex];
      MarketCreationData storage _marketCreationData = marketCreationData[_marketTypeIndex][_marketCurrencyIndex];
      require(!_marketType.paused && !_marketCreationData.paused);
      _closePreviousMarketWithRoundId( _marketTypeIndex, _marketCurrencyIndex, _roundId);
      uint32 _startTime = calculateStartTimeForMarket(_marketCurrencyIndex, _marketTypeIndex);
      uint32[] memory _marketTimes = new uint32[](4);
      uint64[] memory _optionRanges = new uint64[](2);
      uint64 _marketIndex = allMarkets.getTotalMarketsLength();
      marketOptionPricing[_marketIndex] = marketTypeOptionPricing[_marketTypeIndex];
      _optionRanges = _calculateOptionRanges(marketOptionPricing[_marketIndex], _marketType.optionRangePerc, _marketCurrency.decimals, _marketCurrency.roundOfToNearest, _marketCurrency.marketFeed);
      _marketTimes[0] = _startTime; 
      _marketTimes[1] = _marketType.predictionTime;
      _marketTimes[2] = marketTypeSettlementTime[_marketTypeIndex];
      _marketTimes[3] = _marketType.cooldownTime;
      marketPricingData[_marketIndex] = PricingData(stakingFactorMinStake, stakingFactorWeightage, currentPriceWeightage, _marketType.minTimePassed);
      marketData[_marketIndex] = MarketData(_marketTypeIndex, _marketCurrencyIndex, _msgSenderAddress);
      allMarkets.createMarket(_marketTimes, _optionRanges, _msgSenderAddress, _marketType.initialLiquidity);
      
      (_marketCreationData.penultimateMarket, _marketCreationData.latestMarket) =
       (_marketCreationData.latestMarket, _marketIndex);
      
      emit MarketParams(_marketIndex, _msgSenderAddress, _marketTypeIndex, _marketCurrency.currencyName, stakingFactorMinStake,stakingFactorWeightage,currentPriceWeightage,_marketType.minTimePassed);      
    }

    /**
     * @dev Internal function to calculate option ranges for the market
     * @param _optionRangePerc Defined Option percent
     * @param _decimals Decimals of the given feed address
     * @param _roundOfToNearest Round of the option range to the nearest multiple
     * @param _marketFeed Market Feed address
     */
    function _calculateOptionRanges(uint _optionLength, uint _optionRangePerc, uint64 _decimals, uint8 _roundOfToNearest, address _marketFeed) internal view returns(uint64[] memory _optionRanges) {
      uint currentPrice = IOracle(_marketFeed).getLatestPrice();
      _optionRanges = IOptionPricing(optionPricingContracts[_optionLength]).calculateOptionRanges(currentPrice, _optionRangePerc, _decimals, _roundOfToNearest);
    }

    /**
     * @dev Gets price for given market and option
     * @param _marketId  Market ID
     * @param _prediction  prediction option
     * @return  option price
     **/
    function getOptionPrice(uint _marketId, uint256 _prediction) public view returns(uint64) {
      uint _marketCurr = marketData[_marketId].marketCurrencyIndex;

      uint[] memory _marketPricingDataArray = new uint[](4);
      PricingData storage _marketPricingData = marketPricingData[_marketId];
      _marketPricingDataArray[0] = _marketPricingData.stakingFactorMinStake;
      _marketPricingDataArray[1] = _marketPricingData.stakingFactorWeightage;
      _marketPricingDataArray[2] = _marketPricingData.currentPriceWeightage;
      _marketPricingDataArray[3] = _marketPricingData.minTimePassed;

      // Fetching current price
      uint currentPrice = IOracle(marketCurrencies[_marketCurr].marketFeed).getLatestPrice();

      return IOptionPricing(optionPricingContracts[marketOptionPricing[_marketId]]).getOptionPrice(_marketId, currentPrice, _prediction, _marketPricingDataArray, address(allMarkets));

    }

    /**
     * @dev Gets price for all the options in a market
     * @param _marketId  Market ID
     * @return _optionPrices array consisting of prices for all available options
     **/
    function getAllOptionPrices(uint _marketId) external view returns(uint64[] memory _optionPrices) {
      _optionPrices = new uint64[](marketOptionPricing[_marketId]);
      for(uint i=0; i< marketOptionPricing[_marketId]; i++) {
        _optionPrices[i] = getOptionPrice(_marketId,i+1);
      }

    }

}
