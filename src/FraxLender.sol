// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {BaseStrategy, ERC20} from "@tokenized-strategy/BaseStrategy.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IFraxLend} from "./interfaces/IFraxLend.sol";

contract FraxLender is BaseStrategy {
    using SafeERC20 for ERC20;

    address public immutable market;

    constructor(address _asset, address _market, string memory _name) BaseStrategy(_asset, _name) {
        market = _market;
        asset.safeApprove(_market, type(uint256).max);
    }

    function _deployFunds(uint256 _amount) internal override {
        IFraxLend(market).deposit(_amount, address(this));
    }

    function _freeFunds(uint256 _amount) internal override {
        IFraxLend(market).addInterest();
        uint256 amountInShares = IFraxLend(market).toAssetShares(_amount, false);
        amountInShares = Math.min(amountInShares, ERC20(market).balanceOf(address(this)));
        IFraxLend(market).redeem(amountInShares, address(this), address(this));
    }

    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        IFraxLend(market).addInterest();
        _totalAssets = balanceOfAsset() + balanceOfInvestment();
    }

    function balanceOfAsset() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function balanceOfInvestment() public view returns (uint256) {
        return IFraxLend(market).toAssetAmount(ERC20(market).balanceOf(address(this)), false);
    }

    function availableWithdrawLimit(address /*_owner*/) public view override returns (uint256) {
        return balanceOfAsset() + asset.balanceOf(market);
    }

    function _emergencyWithdraw(uint256 _amount) internal override {
        IFraxLend(market).addInterest();
        uint256 amountInShares = IFraxLend(market).toAssetShares(_amount, true);
        amountInShares = Math.min(amountInShares, ERC20(market).balanceOf(address(this)));
        IFraxLend(market).redeem(amountInShares, address(this), address(this));
    }
}