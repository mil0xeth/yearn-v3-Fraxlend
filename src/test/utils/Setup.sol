// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {ExtendedTest} from "./ExtendedTest.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {FraxLenderFactory, FraxLender} from "../../FraxLenderFactory.sol";
import {IStrategyInterface} from "../../interfaces/IStrategyInterface.sol";

// Inherit the events so they can be checked if desired.
import {IEvents} from "@tokenized-strategy/interfaces/IEvents.sol";

interface IFactory {
    function governance() external view returns (address);

    function set_protocol_fee_bps(uint16) external;

    function set_protocol_fee_recipient(address) external;
}

contract Setup is ExtendedTest, IEvents {
    // Contract instancees that we will use repeatedly.
    ERC20 public asset;
    address public market;
    IStrategyInterface public strategy;

    FraxLenderFactory public lenderFactory;

    mapping(string => address) public tokenAddrs;

    // Addresses for different roles we will use repeatedly.
    address public user = address(10);
    address public keeper = address(4);
    address public management = address(1);
    address public performanceFeeRecipient = address(3);
    address public emergencyAdmin = address(6);

    // Address of the real deployed Factory
    address public factory;

    // Integer variables that will be used repeatedly.
    uint256 public decimals;
    uint256 public MAX_BPS = 10_000;

    uint256 public maxFuzzAmount = 1e11;
    uint256 public minFuzzAmount = 100_000;

    // Default prfot max unlock time is set for 10 days
    uint256 public profitMaxUnlockTime = 10 days;

    bool public useBoolAddInterest;

    function setUp() public virtual {
        //------------------MAINNET:
        asset = ERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e); //FRAX on Mainnet

        useBoolAddInterest = false;
        market = 0x794F6B13FBd7EB7ef10d1ED205c9a416910207Ff; //WETH/FRAX market on Mainnet
        //market = 0x32467a5fc2d72D21E8DCe990906547A2b012f382; //WBTC/FRAX MAINNET
        //market = 0xDbe88DBAc39263c47629ebbA02b3eF4cf0752A72; //FXS FRAX
        //market = 0x74F82Bd9D0390A4180DaaEc92D64cf0708751759; //FPI FRAX
        //market = 0xa1D100a5bf6BFd2736837c97248853D989a9ED84; //CVX
        //market = 0x3835a58CA93Cdb5f912519ad366826aC9a752510; //CRV/FRAX market on Mainnet
        //market = 0x66bf36dBa79d4606039f04b32946A260BCd3FF52; //gOHM
        
        //useBoolAddInterest = true;
        //market = 0x78bB3aEC3d855431bd9289fD98dA13F9ebB7ef15; //sfrxETH/FRAX MAINNET
        //market = 0x281E6CB341a552E4faCCc6b4eEF1A6fCC523682d; //frxETH/ETH Curve LP FRAX
        //market = 0x1Fff4a418471a7b44EFa023320e02DCDB486ED77; //FRAX/USDC Curve LP FRAX
        //market = 0x82Ec28636B77661a95f021090F6bE0C8d379DD5D; //MKR
        //market = 0xc6CadA314389430d396C7b0C70c6281e99ca7fe8; //UNI
        //market = 0xc779fEE076EB04b9F8EA424ec19DE27Efd17A68d; //AAVE
        //market = 0x7093F6141293F7C4F67E5efD922aC934402E452d; //LINK
        //market = 0xb5a46f712F03808aE5c4B885C6F598fA06442684; //WSTETH
        //market = 0x0601B72bEF2b3F09E9f48B7d60a8d7D2D3800C6e; //LDO
        //market = 0xa4Ddd4770588EF97A3a03E4B7E3885d824159bAA; //rETH

        //Not interesting (near zero lend apy):
        //market = 0x3a25B9aB8c07FfEFEe614531C75905E810d8A239; //APE FRAX
        //market = 0x35E08B28d5b01D058cbB1c39dA9188CC521a79aF; //FXB_1_JUN302024
        //market = 0xd1887398f3bbdC9d10D0d5616AD83506DdF5057a; //FXB_2_DEC312024
        //market = 0x1c0C222989a37247D974937782cebc8bF4f25733; //FXB_4_DEC312026 

        //USDC MARKET:
        //useBoolAddInterest = true;
        //asset = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //USDC on Mainnet
        //market = 0xeE847a804b67f4887c9E8fe559A2dA4278deFB52; //USDC-sfrxETH


        //----------- ARBITRUM:
        //useBoolAddInterest = true;
        //asset = ERC20(0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F); //FRAX on ARBITRUM
        //market = 0x9168AC3a83A31bd85c93F4429a84c05db2CaEF08; //WBTC
        //market = 0x6076ebDFE17555ed3E6869CF9C373Bbd9aD55d38; //GMX
        //market = 0x2D0483FefAbA4325c7521539a3DFaCf94A19C472; //ARB




        lenderFactory = new FraxLenderFactory(
            management,
            performanceFeeRecipient,
            keeper,
            emergencyAdmin
        );

        // Set decimals
        decimals = asset.decimals();

        // Deploy strategy and set variables
        strategy = IStrategyInterface(setUpStrategy());

        factory = strategy.FACTORY();

        // label all the used addresses for traces
        vm.label(keeper, "keeper");
        vm.label(factory, "factory");
        vm.label(address(asset), "asset");
        vm.label(management, "management");
        vm.label(address(strategy), "strategy");
        vm.label(performanceFeeRecipient, "performanceFeeRecipient");
    }

    function setUpStrategy() public returns (address) {
        // we save the strategy as a IStrategyInterface to give it the needed interface
        IStrategyInterface _strategy = IStrategyInterface(
            address(
                lenderFactory.newFraxLender(
                    address(asset),
                    market,
                    useBoolAddInterest,
                    "Tokenized Strategy"
                )
            )
        );

        vm.prank(management);
        _strategy.acceptManagement();

        vm.prank(management);
        _strategy.setProfitLimitRatio(60535);
        //vm.prank(management);
        //strategy.setDoHealthCheck(false);

        return address(_strategy);
    }

    function depositIntoStrategy(
        IStrategyInterface _strategy,
        address _user,
        uint256 _amount
    ) public {
        vm.prank(_user);
        asset.approve(address(_strategy), _amount);

        vm.prank(_user);
        _strategy.deposit(_amount, _user);
    }

    function mintAndDepositIntoStrategy(
        IStrategyInterface _strategy,
        address _user,
        uint256 _amount
    ) public {
        airdrop(asset, _user, _amount);
        depositIntoStrategy(_strategy, _user, _amount);
    }

    // For checking the amounts in the strategy
    function checkStrategyTotals(
        IStrategyInterface _strategy,
        uint256 _totalAssets,
        uint256 _totalDebt,
        uint256 _totalIdle
    ) public {
        uint256 _assets = _strategy.totalAssets();
        uint256 _balance = ERC20(_strategy.asset()).balanceOf(
            address(_strategy)
        );
        uint256 _idle = _balance > _assets ? _assets : _balance;
        uint256 _debt = _assets - _idle;
        assertEq(_assets, _totalAssets, "!totalAssets");
        assertEq(_debt, _totalDebt, "!totalDebt");
        assertEq(_idle, _totalIdle, "!totalIdle");
        assertEq(_totalAssets, _totalDebt + _totalIdle, "!Added");
    }

    function airdrop(ERC20 _asset, address _to, uint256 _amount) public {
        uint256 balanceBefore = _asset.balanceOf(_to);
        deal(address(_asset), _to, balanceBefore + _amount);
    }

    function getExpectedProtocolFee(
        uint256 _amount,
        uint16 _fee
    ) public view returns (uint256) {
        uint256 timePassed = block.timestamp - strategy.lastReport();

        return (_amount * _fee * timePassed) / MAX_BPS / 31_556_952;
    }

    function setFees(uint16 _protocolFee, uint16 _performanceFee) public {
        address gov = IFactory(factory).governance();

        // Need to make sure there is a protocol fee recipient to set the fee.
        vm.prank(gov);
        IFactory(factory).set_protocol_fee_recipient(gov);

        vm.prank(gov);
        IFactory(factory).set_protocol_fee_bps(_protocolFee);

        vm.prank(management);
        strategy.setPerformanceFee(_performanceFee);
    }

}
