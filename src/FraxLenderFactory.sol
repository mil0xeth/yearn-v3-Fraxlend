// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {FraxLender} from "./FraxLender.sol";
import {IStrategyInterface} from "./interfaces/IStrategyInterface.sol";

contract FraxLenderFactory {
    /// @notice Revert message for when a strategy has already been deployed.
    error AlreadyDeployed(address _strategy);

    event NewFraxLender(address indexed strategy, address indexed asset);

    address public management;
    address public performanceFeeRecipient;
    address public keeper;
    address public emergencyAdmin;

    /// @notice Track the deployments. market => strategy
    mapping(address => address) public deployments;

    constructor(
        address _management,
        address _performanceFeeRecipient,
        address _keeper,
        address _emergencyAdmin
    ) {
        require(_management != address(0), "ZERO ADDRESS");
        management = _management;
        performanceFeeRecipient = _performanceFeeRecipient;
        keeper = _keeper;
        emergencyAdmin = _emergencyAdmin;
    }

    /**
     * @notice Deploy a new Compound V3 Lender.
     * @dev This will set the msg.sender to all of the permissioned roles.
     * @param _asset The underlying asset for the lender to use.
     * @param _name The name for the lender to use.
     * @return . The address of the new lender.
     */
    function newFraxLender(
        address _asset,
        address _market,
        bool _useBoolAddInterest,
        string memory _name
    ) external returns (address) {
        if (deployments[_market] != address(0))
            revert AlreadyDeployed(deployments[_market]);
        // We need to use the custom interface with the
        // tokenized strategies available setters.
        IStrategyInterface newStrategy = IStrategyInterface(
            address(
                new FraxLender(
                    _asset,
                    _market,
                    _useBoolAddInterest,
                    _name
                )
            )
        );

        newStrategy.setPerformanceFeeRecipient(performanceFeeRecipient);

        newStrategy.setKeeper(keeper);

        newStrategy.setEmergencyAdmin(emergencyAdmin);

        newStrategy.setPendingManagement(management);

        emit NewFraxLender(address(newStrategy), _asset);

        deployments[_market] = address(newStrategy);
        return address(newStrategy);
    }

    function setAddresses(
        address _management,
        address _performanceFeeRecipient,
        address _keeper,
        address _emergencyAdmin
    ) external {
        require(msg.sender == management, "!management");
        management = _management;
        performanceFeeRecipient = _performanceFeeRecipient;
        keeper = _keeper;
        emergencyAdmin = _emergencyAdmin;
    }

    function isDeployedStrategy(
        address _strategy
    ) external view returns (bool) {
        address _market = IStrategyInterface(_strategy).market();
        return deployments[_market] == _strategy;
    }
}
