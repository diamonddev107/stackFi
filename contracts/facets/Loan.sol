// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";

contract Loan is Pausable, ILoan {

	event AddCollateral(
		address indexed account,
		uint256 indexed id,
		uint256 amount,
		uint256 timestamp
	);
	
	event WithdrawPartialLoan(
		address indexed account,
		uint256 indexed id,
		uint256 indexed amount,
		bytes32 market,
		uint256 timestamp
	);
	constructor() {
    	// AppStorage storage ds = LibOpen.diamondStorage(); 
		// ds.adminLoanAddress = msg.sender;
		// ds.loan = ILoan(msg.sender);
	}

	receive() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}
	
	fallback() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}

	/// Swap loan to a secondary market.
	function swapLoan(
		bytes32 _loanMarket,
		bytes32 _commitment,
		bytes32 _swapMarket
	) external override nonReentrant() returns (bool) {
		LibOpen._swapLoan(msg.sender, _loanMarket, _commitment, _swapMarket);
		return true;
	}

/// SwapToLoan
	function swapToLoan(
		bytes32 _swapMarket,
		bytes32 _commitment,
		bytes32 _loanMarket
	) external override nonReentrant() returns (bool) {
		LibOpen._swapToLoan(msg.sender, _swapMarket, _commitment, _loanMarket);
		return true;
	}

	function withdrawCollateral(bytes32 _market, bytes32 _commitment) external override returns (bool) {
		LibOpen._withdrawCollateral(msg.sender, _market, _commitment);
		return true;
	}

	

	// function getFairPriceLoan(uint _requestId) external view override returns (uint){
	// 	return LibOpen._getFairPrice(_requestId);
	// }

	// function collateralPointer(address _account, bytes32 _loanMarket, bytes32 _commitment) external view override returns (bool) {
    // 	LibOpen._collateralPointer(_account, _loanMarket, _commitment);
	// 	return true;
	// }

	function preAddCollateralProcess(
		bytes32 _collateralMarket,
		uint256 _collateralAmount,
		// LoanAccount storage loanAccount,
		LoanRecords storage loan,
		LoanState storage loanState,
		CollateralRecords storage collateral
	) private view {
		// require(loanAccount.accOpenTime != 0, "ERROR: No Loan account"); // redundant
		require(loan.id != 0, "ERROR: No loan");
		require(loanState.state == uint(STATE.ACTIVE), "ERROR: Inactive loan");
		require(collateral.market == _collateralMarket, "ERROR: Mismatch collateral market");

		LibOpen._isMarketSupported(_collateralMarket);
		LibOpen._minAmountCheck(_collateralMarket, _collateralAmount);
	}

	function addCollateral(      
		bytes32 _loanMarket,
		bytes32 _commitment,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) external override returns (bool) {
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
    	LoanAccount storage loanAccount = ds.loanPassbook[msg.sender];
		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[msg.sender][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[msg.sender][_loanMarket][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[msg.sender][_loanMarket][_commitment];

		preAddCollateralProcess(_collateralMarket, _collateralAmount /* loanAccount */, loan,loanState, collateral);

		ds.collateralToken = IBEP20(LibOpen._connectMarket(_collateralMarket));
		// _quantifyAmount(_collateralMarket, _collateralAmount);
		ds.collateralToken.transferFrom(msg.sender, address(this), _collateralAmount);
		LibOpen._updateReservesLoan(_collateralMarket, _collateralAmount, 0);
		
		updateCollateral(loanAccount, collateral, _collateralAmount, loan.id-1);
		LibOpen._accruedInterest(msg.sender, _loanMarket, _commitment);

		if (collateral.isCollateralisedDeposit) LibOpen._accruedYield(loanAccount, collateral, cYield);

		emit AddCollateral(msg.sender, loan.id, _collateralAmount, block.timestamp);
		return true;
	}

	function updateCollateral(
		LoanAccount storage loanAccount,
		CollateralRecords storage collateral,
		uint256 _collateralAmount,
		uint256 num
	) private {
		collateral.amount += _collateralAmount;
		loanAccount.collaterals[num].amount = _collateralAmount;
	}

		
	function withdrawPartialLoan(bytes32 _loanMarket,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount) external returns (bool) {
    
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		LibOpen._hasLoanAccount(msg.sender);

		LoanRecords storage loan = ds.indLoanRecords[msg.sender][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[msg.sender][_loanMarket][_commitment];
		
		checkPermissibleWithdrawal(msg.sender, _loanMarket, _commitment, _collateralMarket, _amount);
		
		ds.withdrawToken = IBEP20(LibOpen._connectMarket(loanState.currentMarket));
		ds.withdrawToken.transfer(msg.sender,_amount);

		emit WithdrawPartialLoan(msg.sender, loan.id, _amount, loanState.currentMarket, block.timestamp);
		return true;
  }
  
	function checkPermissibleWithdrawal(address _sender,bytes32 _loanMarket,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount) private /*authContract(LOAN_ID)*/ {
		
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		// LoanRecords storage loan = ds.indLoanRecords[_sender][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[_sender][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_loanMarket][_commitment];
		// DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_sender][_loanMarket][_commitment];
		// emit FairPriceCall(ds.requestEventId++, _collateralMarket, _amount);
		// emit FairPriceCall(ds.requestEventId++, _loanMarket, _amount);
		// emit FairPriceCall(ds.requestEventId++, loanState.currentMarket, loanState.currentAmount);		
		// _quantifyAmount(loanState.currentMarket, _amount);
		require(_amount <= loanState.currentAmount, "ERROR: Exceeds available loan");
		
		LibOpen._accruedInterest(_sender, _loanMarket, _commitment);
		uint256 collateralAvbl = collateral.amount - ds.indAccruedAPR[_sender][_loanMarket][_commitment].accruedInterest;

		// fetch usdPrices
		uint256 usdCollateral = LibOpen._getLatestPrice(_collateralMarket);
		uint256 usdLoan = LibOpen._getLatestPrice(_loanMarket);
		uint256 usdLoanCurrent = LibOpen._getLatestPrice(loanState.currentMarket);

		// Quantification of the assets
		// uint256 cAmount = usdCollateral*collateral.amount;
		// uint256 cAmountAvbl = usdCollateral*collateralAvbl;

		// uint256 lAmountCurrent = usdLoanCurrent*loanState.currentAmount;
		uint256 permissibleAmount = ((usdCollateral*collateralAvbl - (30*usdCollateral*collateral.amount/100))/usdLoanCurrent);

		require(permissibleAmount > 0, "ERROR: Can not withdraw zero funds");
		require(permissibleAmount > (_amount), "ERROR:Request exceeds funds");
		
		// calcualted in usdterms
		require(((usdCollateral*collateralAvbl) + (usdLoanCurrent*loanState.currentAmount) - (_amount*usdLoanCurrent)) >= (11*(usdLoan*ds.indLoanRecords[_sender][_loanMarket][_commitment].amount)/10), "ERROR: Liquidation risk");
	}
	

	function pauseLoan() external override authLoan() nonReentrant() {
		_pause();
	}
	
	function unpauseLoan() external override authLoan() nonReentrant() {
		_unpause();   
	}

	function isPausedLoan() external view virtual override returns (bool) {
		return _paused();
	}

	modifier authLoan() {
    	AppStorageOpen storage ds = LibOpen.diamondStorage();
		require(IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.superAdmin, msg.sender) || IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.adminLoan, msg.sender), "ERROR: Not an admin");
		_;
	}
}
