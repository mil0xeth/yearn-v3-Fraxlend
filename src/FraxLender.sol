// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {BaseHealthCheck, ERC20} from "@periphery/Bases/HealthCheck/BaseHealthCheck.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IFraxLend} from "./interfaces/IFraxLend.sol";

contract FraxLender is BaseHealthCheck {
    using SafeERC20 for ERC20;

    address public immutable market;
    bool public immutable useBoolAddInterest;

    constructor(address _asset, address _market, bool _useBoolAddInterest, string memory _name) BaseHealthCheck(_asset, _name) {
        require(IFraxLend(_market).asset() == _asset, "!asset");
        market = _market;
        useBoolAddInterest = _useBoolAddInterest;
        asset.safeApprove(_market, type(uint256).max);
    }

    function _deployFunds(uint256 _amount) internal override {
        IFraxLend(market).deposit(_amount, address(this));
    }

    function _freeFunds(uint256 _amount) internal override {
        _addInterest(); // accrue any interest
        uint256 amountInShares;
        if (useBoolAddInterest) {
            amountInShares = IFraxLend(market).toAssetShares(_amount, true, false);
        } else {
            amountInShares = IFraxLend(market).toAssetShares(_amount, true);
        }
        amountInShares = _min(amountInShares, ERC20(market).balanceOf(address(this)));
        IFraxLend(market).redeem(amountInShares, address(this), address(this));
    }

    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        _addInterest(); // accrue any interest
        _totalAssets = balanceOfAsset() + balanceOfInvestment();
    }

    function _addInterest() internal {
        if (useBoolAddInterest) {
            IFraxLend(market).addInterest(false);
        } else {
            IFraxLend(market).addInterest();
        }
    }

    function balanceOfAsset() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function balanceOfInvestment() public view returns (uint256) {
        if (useBoolAddInterest) {
            return IFraxLend(market).toAssetAmount(ERC20(market).balanceOf(address(this)), false, false);
        } else {
            return IFraxLend(market).toAssetAmount(ERC20(market).balanceOf(address(this)), false);
        }
    }

    function availableWithdrawLimit(address /*_owner*/) public view override returns (uint256) {
        return balanceOfAsset() + IFraxLend(market).totalAsset() - IFraxLend(market).totalBorrow();
    }

    function _emergencyWithdraw(uint256 _amount) internal override {
        _freeFunds(_amount);
    }

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}