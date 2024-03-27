// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

interface IFraxLend {
    function deposit(uint256 _amount, address _receiver) external;

    function redeem(uint256 _amount, address _owner, address _receiver) external;

    function addInterest() external;

    function toAssetAmount(uint256 _shares, bool _roundUp) external view returns (uint256);

    function toAssetShares(uint256 _amount, bool _roundUp) external view returns (uint256);

    function asset() external view returns (address);
}