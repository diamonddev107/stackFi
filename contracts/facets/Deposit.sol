// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "../libraries/LibOpen.sol";
import {YieldLedger} from "../libraries/AppStorageOpen.sol";

contract Deposit is Pausable, IDeposit {
    constructor() {
        // AppStorage storage ds = LibOpen.diamondStorage();
        // ds.adminDepositAddress = msg.sender;
        // ds.deposit = IDeposit(msg.sender);
    }

    // receive() external payable {
    // 	AppStorage storage ds = LibOpen.diamondStorage();
    // 	payable(ds.superAdminAddress).transfer(_msgValue());
    // }

    // fallback() external payable {
    // 	AppStorage storage ds = LibOpen.diamondStorage();
    // 	payable(ds.superAdminAddress).transfer(_msgValue());
    // }

	function savingsBalance(bytes32 _market, bytes32 _commitment) external override returns (uint) {
		return LibOpen._accountBalance(msg.sender, _market, _commitment, SAVINGSTYPE.BOTH);
	}

    function savingsBalance(bytes32 _market, bytes32 _commitment)
        external
        view
        override
        returns (uint256)
    {
        return
            LibOpen._accountBalance(
                msg.sender,
                _market,
                _commitment,
                SAVINGSTYPE.BOTH
            );
    }

    function convertYield(bytes32 _market, bytes32 _commitment)
        external
        override
        nonReentrant
        returns (bool)
    {
        uint256 _amount;
        LibOpen._convertYield(msg.sender, _market, _commitment, _amount);
        return true;
    }

    function hasYield(bytes32 _market, bytes32 _commitment)
        external
        view
        override
        returns (bool)
    {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        YieldLedger storage yield = ds.indYieldRecord[msg.sender][_market][
            _commitment
        ];
        LibOpen._hasYield(yield);
        return true;
    }

    function avblReservesDeposit(bytes32 _market)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._avblReservesDeposit(_market);
    }

    function utilisedReservesDeposit(bytes32 _market)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._utilisedReservesDeposit(_market);
    }

    function _updateUtilisation(
        bytes32 _market,
        uint256 _amount,
        uint256 _num
    ) private {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        if (_num == 0) {
            ds.marketUtilisationDeposit[_market] += _amount;
        } else if (_num == 1) {
            ds.marketUtilisationDeposit[_market] -= _amount;
        }
    }

	function withdrawDeposit (
		bytes32 _market, 
		bytes32 _commitment,
		uint _amount,
		SAVINGSTYPE _request
	) external override nonReentrant() returns (bool) 
	{
		LibOpen._withdrawDeposit(msg.sender, _market, _commitment, _amount, _request);
		return true;	
	}

    // function createDeposit(
    // 	bytes32 _market,
    // 	bytes32 _commitment,
    // 	uint256 _amount
    // ) external override nonReentrant() returns (bool) {

	function pauseDeposit() external override authDeposit() nonReentrant() {
		_pause();
	}
	
	function unpauseDeposit() external override authDeposit() nonReentrant() {
		_unpause();   
	}

    function addToDeposit(
        bytes32 _market,
        bytes32 _commitment,
        uint256 _amount
    ) external override nonReentrant returns (bool) {
        LibOpen._addToDeposit(msg.sender, _market, _commitment, _amount);
        return true;
    }

	//For upgradibility test
	function upgradeTestAccount(address _account) external view returns (bool success) {
    	LibOpen._hasAccount(_account);
		LibOpen._hasLoanAccount(_account);
		success = true;
	}

    modifier authDeposit() {
        AppStorageOpen storage ds = LibOpen.diamondStorage();

		require(LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress) || LibOpen._hasAdminRole(ds.adminDeposit, ds.adminDepositAddress), "Admin role does not exist.");
		_;
	}
}
