// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {AprOracleBase} from "@periphery/AprOracle/AprOracleBase.sol";

import {IFraxLend} from "../interfaces/IFraxLend.sol";
import {IStrategyInterface} from "../interfaces/IStrategyInterface.sol";

contract FraxLendAprOracle is AprOracleBase {
    constructor() AprOracleBase("yearn-v3-FraxLend", msg.sender) {}
    uint256 internal constant WAD = 1e18;
    uint256 internal constant secondsPerYear = 31536000;

    function aprAfterDebtChange(
        address _strategy,
        int256 _delta
    ) external view override returns (uint256) {
        address market = IStrategyInterface(_strategy).market();
        (, , , uint64 ratePerSec) = IFraxLend(market).currentRateInfo();
        uint256 borrowRate = uint256(ratePerSec); 
        borrowRate = borrowRate * secondsPerYear;
        (uint128 totalAssetAmount, , uint128 totalBorrowAmount, , ) = IFraxLend(market).getPairAccounting();
        uint256 newSupply = uint256(int256(uint256(totalAssetAmount)) + _delta);
        uint256 utilization = uint256(totalBorrowAmount) * WAD / newSupply;
        return borrowRate * utilization / WAD;
    }
}