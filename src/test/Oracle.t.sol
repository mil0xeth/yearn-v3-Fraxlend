pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup} from "./utils/Setup.sol";

import {FraxLendAprOracle} from "../periphery/FraxLendAprOracle.sol";

contract OracleTest is Setup {
    FraxLendAprOracle public oracle;

    function setUp() public override {
        super.setUp();
        oracle = new FraxLendAprOracle();
    }

    function test_checkOracle() public {
        uint256 currentApr = oracle.aprAfterDebtChange(address(strategy), 0);
        console.log("currentApr: ", currentApr);

        currentApr = oracle.aprAfterDebtChange(address(strategy), 479463535224923186602913);
        console.log("currentApr: ", currentApr);

        currentApr = oracle.aprAfterDebtChange(address(strategy), -479463535224923186602913);
        console.log("currentApr: ", currentApr);

        // Should be greater than 0 but likely less than 100%
        assertGe(currentApr, 1 * 1e16, "Not more than 6% APR");
        assertLt(currentApr, 30 * 1e16, "Not less than 20% APR");
    
    }

}