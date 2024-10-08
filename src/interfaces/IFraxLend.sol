// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

interface IFraxLend {
    function deposit(uint256 _amount, address _receiver) external;

    function redeem(uint256 _amount, address _owner, address _receiver) external;

    function addInterest() external;

    function addInterest(bool) external;

    function toAssetAmount(uint256 _shares, bool _roundUp) external view returns (uint256);
    function toAssetAmount(uint256 _shares, bool _roundUp, bool _previewInterest) external view returns (uint256);

    function toAssetShares(uint256 _amount, bool _roundUp) external view returns (uint256);
    function toAssetShares(uint256 _amount, bool _roundUp, bool _previewInterest) external view returns (uint256);

    function asset() external view returns (address);

    function totalAsset() external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    function currentRateInfo() external view returns (uint64 lastBlock, uint64 feeToProtocolRate, uint64 lastTimestamp, uint64 ratePerSec);

    function getPairAccounting() external view returns (uint128 _totalAssetAmount, uint128 _totalAssetShares, uint128 _totalBorrowAmount, uint128 _totalBorrowShares, uint256 _totalCollateral);
}