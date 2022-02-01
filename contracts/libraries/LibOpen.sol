// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./AppStorageOpen.sol";
import "../util/Address.sol";
import "../util/IBEP20.sol";
import "../interfaces/ITokenList.sol";
import "../interfaces/IComptroller.sol";
import "../interfaces/ILiquidator.sol";
import "../interfaces/IDeposit.sol";
import "../interfaces/IReserve.sol";
import "../interfaces/ILoan.sol";
import "../interfaces/ILoanExt.sol";
import "../interfaces/IOracleOpen.sol";
import "../interfaces/IAccessRegistry.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IAugustusSwapper.sol";
import "../interfaces/IPancakeRouter01.sol";

import "hardhat/console.sol";

library LibOpen {
	using Address for address;

	uint8 constant TOKENLIST_ID = 10;
	uint8 constant COMPTROLLER_ID = 11;
	// uint8 constant LIQUIDATOR_ID = 12;
	uint8 constant RESERVE_ID = 13;
	// uint8 constant ORACLEOPEN_ID = 14;
	uint8 constant LOAN_ID = 15;
	uint8 constant LOANEXT_ID = 16;
	uint8 constant DEPOSIT_ID = 17; 
	uint8 constant ACCESSREGISTRY_ID = 18;
	address internal constant PANCAKESWAP_ROUTER_ADDRESS = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 ; // pancakeswap bsc testnet router address

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	

    event Liquidation(
        address indexed account,
        bytes32 indexed market,
        bytes32 indexed commitment,
        uint256 amount,
        uint256 time
    );

// =========== AccessRegistry events ===============
	event AdminRoleDataGranted(
			bytes32 indexed role,
			address indexed account,
			address indexed sender
	);

	event AdminRoleDataRevoked(
			bytes32 indexed role,
			address indexed account,
			address indexed sender
	);

	event RoleGranted(
			bytes32 indexed role,
			address indexed account,
			address indexed sender
	);

	event RoleRevoked(
			bytes32 indexed role,
			address indexed account,
			address indexed sender
	);
    
	function _addFairPriceAddress(bytes32 _market, address _address) internal {
		AppStorageOpen storage ds = diamondStorage();
		ds.pairAddresses[_market] = _address;
	}

	function _getFairPriceAddress(bytes32 _market) internal view returns (address){
		AppStorageOpen storage ds = diamondStorage();
		return ds.pairAddresses[_market];
	}

    function setReserveAddress(address _reserve) internal {
        AppStorageOpen storage ds = diamondStorage();
        ds.reserveAddress = _reserve;
    }

	function diamondStorage() internal pure returns (AppStorageOpen storage ds) {
			assembly {
					ds.slot := 0
			}
	}

	function _isMarketSupported(bytes32  _market) internal view {
		AppStorageOpen storage ds = diamondStorage(); 
		require(ds.tokenSupportCheck[_market] == true, "ERROR: Unsupported market");
	}

	function _getMarketAddress(bytes32 _market) internal view returns (address) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indMarketData[_market].tokenAddress;
	}

	function _getMarketDecimal(bytes32 _market) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indMarketData[_market].decimals;
	}

    function _minAmountCheck(bytes32 _market, uint256 _amount) internal view {
        AppStorageOpen storage ds = diamondStorage();
        MarketData memory marketData = ds.indMarketData[_market];
        require(
            marketData.minAmount <= _amount,
            "ERROR: Less than minimum deposit"
        );
    }

    // function _quantifyAmount(bytes32 _market, uint _amount) internal view returns (uint amount) {
    // 	AppStorageOpen storage ds = diamondStorage();
    //     MarketData memory marketData = ds.indMarketData[_market];
    // 	amount = _amount * marketData.decimals;
    // }

	function _isMarket2Supported(bytes32  _market) internal view {
		require(diamondStorage().token2SupportCheck[_market] == true, "Secondary Token is not supported");
	}

	function _getMarket2Address(bytes32 _market) internal view returns (address) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indMarket2Data[_market].tokenAddress;
	}

	function _getMarket2Decimal(bytes32 _market) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage();
		return ds.indMarket2Data[_market].decimals;
	}

	function _connectMarket(bytes32 _market) internal view returns (address addr) {
		AppStorageOpen storage ds = diamondStorage(); 
		MarketData memory marketData = ds.indMarketData[_market];
		addr = marketData.tokenAddress;
	}
	
// =========== Comptroller Functions ===========

	function _getAPR(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPRRecords[_commitment].aprChanges[ds.indAPRRecords[_commitment].aprChanges.length - 1];
	}

	function _getAPRInd(bytes32 _commitment, uint _index) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPRRecords[_commitment].aprChanges[_index];
	}

	function _getAPY(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPYRecords[_commitment].apyChanges[ds.indAPYRecords[_commitment].apyChanges.length - 1];
	}

	function _getAPYInd(bytes32 _commitment, uint _index) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPYRecords[_commitment].apyChanges[_index];
	}

	function _getApytime(bytes32 _commitment, uint _index) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPYRecords[_commitment].time[_index];
	}

	function _getAprtime(bytes32 _commitment, uint _index) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPRRecords[_commitment].time[_index];
	}

	function _getApyLastTime(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPYRecords[_commitment].time[ds.indAPYRecords[_commitment].time.length - 1];
	}

	function _getAprLastTime(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPRRecords[_commitment].time[ds.indAPRRecords[_commitment].time.length - 1];
	}

	function _getApyTimeLength(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPYRecords[_commitment].time.length;
	}

	function _getAprTimeLength(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPRRecords[_commitment].time.length;
	}

	function _getCommitment(uint _index) internal view returns (bytes32) {
		AppStorageOpen storage ds = diamondStorage(); 
		require(_index < ds.commitment.length, "Commitment Index out of range");
		return ds.commitment[_index];
	}

	function _setCommitment(bytes32 _commitment) internal authContract(COMPTROLLER_ID) {
		AppStorageOpen storage ds = diamondStorage();
		ds.commitment.push(_commitment);
	}

    function _getAPR(bytes32 _commitment) internal view returns (uint256) {
        AppStorageOpen storage ds = diamondStorage();
        return
            ds.indAPRRecords[_commitment].aprChanges[
                ds.indAPRRecords[_commitment].aprChanges.length - 1
            ];
    }

    function _getAPRInd(bytes32 _commitment, uint256 _index)
        internal
        view
        returns (uint256)
    {
        AppStorageOpen storage ds = diamondStorage();
        return ds.indAPRRecords[_commitment].aprChanges[_index];
    }

    function _getAPY(bytes32 _commitment) internal view returns (uint256) {
        AppStorageOpen storage ds = diamondStorage();
        return
            ds.indAPYRecords[_commitment].apyChanges[
                ds.indAPYRecords[_commitment].apyChanges.length - 1
            ];
    }

    function _getAPYInd(bytes32 _commitment, uint256 _index)
        internal
        view
        returns (uint256)
    {
        AppStorageOpen storage ds = diamondStorage();
        return ds.indAPYRecords[_commitment].apyChanges[_index];
    }

    function _getApytime(bytes32 _commitment, uint256 _index)
        internal
        view
        returns (uint256)
    {
        AppStorageOpen storage ds = diamondStorage();
        return ds.indAPYRecords[_commitment].time[_index];
    }

    function _getAprtime(bytes32 _commitment, uint256 _index)
        internal
        view
        returns (uint256)
    {
        AppStorageOpen storage ds = diamondStorage();
        return ds.indAPRRecords[_commitment].time[_index];
    }

    function _getApyLastTime(bytes32 _commitment)
        internal
        view
        returns (uint256)
    {
        AppStorageOpen storage ds = diamondStorage();
        return
            ds.indAPYRecords[_commitment].time[
                ds.indAPYRecords[_commitment].time.length - 1
            ];
    }

    function _getAprLastTime(bytes32 _commitment)
        internal
        view
        returns (uint256)
    {
        AppStorageOpen storage ds = diamondStorage();
        return
            ds.indAPRRecords[_commitment].time[
                ds.indAPRRecords[_commitment].time.length - 1
            ];
    }

    function _getApyTimeLength(bytes32 _commitment)
        internal
        view
        returns (uint256)
    {
        AppStorageOpen storage ds = diamondStorage();
        return ds.indAPYRecords[_commitment].time.length;
    }

    function _getAprTimeLength(bytes32 _commitment)
        internal
        view
        returns (uint256)
    {
        AppStorageOpen storage ds = diamondStorage();
        return ds.indAPRRecords[_commitment].time.length;
    }

	function _getReserveFactor() internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.reserveFactor;
	}
// =========== Liquidator Functions ===========
	function _swap(bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 _mode) internal returns (uint256 receivedAmount) {
		address addrFromMarket;
		address addrToMarket;

		if(_mode == 0){
				addrFromMarket = _getMarketAddress(_fromMarket);
				addrToMarket = _getMarket2Address(_toMarket);
		} else if(_mode == 1) {
				addrFromMarket = _getMarket2Address(_fromMarket);
				addrToMarket = _getMarketAddress(_toMarket);
		} else if(_mode == 2) {
				addrFromMarket = _getMarketAddress(_toMarket);
				addrToMarket = _getMarketAddress(_fromMarket);
		}

        //paraswap
        // address[] memory callee = new address[](2);
        // if(_fromMarket == MARKET_WBNB) callee[0] = WBNB;
        // if(_toMarket == MARKET_WBNB) callee[1] = WBNB;
        // IBEP20(addrFromMarket).approve(0xDb28dc14E5Eb60559844F6f900d23Dce35FcaE33, _fromAmount);
        // receivedAmount = IAugustusSwapper(0x3D0Fc2b7A17d61915bcCA984B9eAA087C5486d18).swapOnUniswap(
        // 	_fromAmount, 1,
        // 	callee,
        // 	1
        // );

		//PancakeSwap
		IBEP20(addrFromMarket).approveFrom(msg.sender, address(this), _fromAmount);
		IBEP20(addrFromMarket).transferFrom(msg.sender, address(this), _fromAmount);
		IBEP20(addrFromMarket).approve(PANCAKESWAP_ROUTER_ADDRESS, _fromAmount);

		//WBNB as other test tokens
		address[] memory path;
		// if (addrFromMarket == WBNB || addrToMarket == WBNB) {
			path = new address[](2);
			path[0] = addrFromMarket;
			path[1] = addrToMarket;
		// } else {
		//     path = new address[](3);
		//     path[0] = addrFromMarket;
		//     path[1] = WBNB;
		//     path[2] = addrToMarket;
		// }

		IPancakeRouter01(PANCAKESWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
				_fromAmount,
				_getAmountOutMin(addrFromMarket, addrToMarket, _fromAmount),
				path,
				address(this),
				block.timestamp
		);
		return receivedAmount;
	}

	function _getAmountOutMin(
		address _tokenIn,
		address _tokenOut,
		uint _amountIn
	) private view returns (uint) {
		address[] memory path;
		//if (_tokenIn == WBNB || _tokenOut == WBNB) {
			path = new address[](2);
			path[0] = _tokenIn;
			path[1] = _tokenOut;
	// } else {
	//     path = new address[](3);
	//     path[0] = _tokenIn;
	//     path[1] = WBNB;
	//     path[2] = _tokenOut;
	// }

	// same length as path
		uint[] memory amountOutMins = IPancakeRouter01(PANCAKESWAP_ROUTER_ADDRESS).getAmountsOut(
				_amountIn,
				path
		);	

		return amountOutMins[path.length - 1];
  }

// =========== Deposit Functions ===========
	function _hasDeposit(address _account, bytes32 _market, bytes32 _commitment) internal view returns(bool ret) {
		AppStorageOpen storage ds = diamondStorage();
		ret = ds.indDepositRecord[_account][_market][_commitment].id != 0;
		// require (ds.indDepositRecord[_account][_market][_commitment].id != 0, "ERROR: No deposit");
		// return true;
	}

	function _avblReservesDeposit(bytes32 _market) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.marketReservesDeposit[_market];
	}

	function _utilisedReservesDeposit(bytes32 _market) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.marketUtilisationDeposit[_market];
	}

	function _hasAccount(address _account) internal view {
		AppStorageOpen storage ds = diamondStorage(); 
		require(ds.savingsPassbook[_account].accOpenTime!=0, "ERROR: No savings account");
	}

	function _hasYield(YieldLedger memory yield) internal pure {
		require(yield.id !=0, "ERROR: No Yield");
	}

	function _updateReservesDeposit(bytes32 _market, uint _amount, uint _num) internal authContract(DEPOSIT_ID) {
		AppStorageOpen storage ds = diamondStorage();
		if (_num == 0)	{
			ds.marketReservesDeposit[_market] += _amount;
		} else if (_num == 1)	{
			ds.marketReservesDeposit[_market] -= _amount;
		}
	}

	function _ensureSavingsAccount(address _account, SavingsAccount storage savingsAccount) internal {

        _updateReservesDeposit(_market, _amount, 1);
        emit Withdrawal(
            _account,
            _market,
            _amount,
            _commitment,
            block.timestamp
        );
    }

    function _accruedYield(
        address _account,
        bytes32 _market,
        bytes32 _commitment
    ) internal authContract(DEPOSIT_ID) {
        AppStorageOpen storage ds = diamondStorage();

// =========== Loan Functions ===========
	
	function _avblReservesLoan(bytes32 _market) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.marketReservesLoan[_market];
	}

	function _utilisedReservesLoan(bytes32 _market) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.marketUtilisationLoan[_market];
	}

	function _updateReservesLoan(bytes32 _market, uint256 _amount, uint256 _num) internal {
		AppStorageOpen storage ds = diamondStorage(); 
		if (_num == 0) {
			ds.marketReservesLoan[_market] += _amount;
		} else if (_num == 1) {
			ds.marketReservesLoan[_market] -= _amount;
		}
	}

	function _updateUtilisationLoan(bytes32 _market, uint256 _amount, uint256 _num) internal {
		AppStorageOpen storage ds = diamondStorage(); 
		if (_num == 0)	{
			ds.marketUtilisationLoan[_market] += _amount;
		} else if (_num == 1)	{
			ds.marketUtilisationLoan[_market] -= _amount;
		}
	}

	function _collateralPointer(address _account, bytes32 _market, bytes32 _commitment) internal view returns (bytes32 collateralMarket, uint collateralAmount) {
		AppStorageOpen storage ds = diamondStorage(); 
		
		_hasLoanAccount(_account);

        _hasLoanAccount(_account);

        // LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
        LoanState storage loanState = ds.indLoanState[_account][_market][
            _commitment
        ];
        CollateralRecords storage collateral = ds.indCollateralRecords[
            _account
        ][_market][_commitment];

	function _accruedYield(LoanAccount storage loanAccount, CollateralRecords storage collateral, CollateralYield storage cYield) internal {
		bytes32 _commitment = cYield.commitment;
		uint256 aggregateYield;
		uint256 num = collateral.id-1;
		
		(cYield.oldLengthAccruedYield, cYield.oldTime, aggregateYield) = _calcAPY(_commitment, cYield.oldLengthAccruedYield, cYield.oldTime, aggregateYield);

    function _accruedYield(
        LoanAccount storage loanAccount,
        CollateralRecords storage collateral,
        CollateralYield storage cYield
    ) private {
        bytes32 _commitment = cYield.commitment;
        uint256 aggregateYield;
        uint256 num = collateral.id - 1;

        (
            cYield.oldLengthAccruedYield,
            cYield.oldTime,
            aggregateYield
        ) = _calcAPY(
            _commitment,
            cYield.oldLengthAccruedYield,
            cYield.oldTime,
            aggregateYield
        );

	function _accruedInterest(address _account, bytes32 _loanMarket, bytes32 _commitment) internal /*authContract(LOAN_ID)*/ {
        AppStorageOpen storage ds = diamondStorage(); 

        loanAccount.loanState[num].currentMarket = _market;
        loanAccount.loanState[num].currentAmount = 0;
        loanAccount.loanState[num].actualLoanAmount = 0;
        loanAccount.loanState[num].state = ILoan.STATE.REPAID;

        loanAccount.collaterals[num].isCollateralisedDeposit = false;
        loanAccount.collaterals[num].isTimelockActivated = true;
        loanAccount.collaterals[num].activationTime = block.timestamp;

        delete loanAccount.accruedAPY[num];
        delete loanAccount.accruedAPR[num];
    }

    function _accruedInterest(
        address _account,
        bytes32 _loanMarket,
        bytes32 _commitment /*authContract(LOAN_ID)*/
    ) private {
        AppStorageOpen storage ds = diamondStorage();

        // emit FairPriceCall(ds.requestEventId++, _loanMarket, ds.indLoanRecords[_account][_loanMarket][_commitment].amount);
        // emit FairPriceCall(ds.requestEventId++, ds.indCollateralRecords[_account][_loanMarket][_commitment].market, ds.indCollateralRecords[_account][_loanMarket][_commitment].amount);

        // LoanAccount storage loanAccount = ds.loanPassbook[_account];
        // LoanRecords storage loan = ds.indLoanRecords[_account][_loanMarket][_commitment];
        // DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_account][_loanMarket][_commitment];

        require(
            ds.indLoanState[_account][_loanMarket][_commitment].state ==
                ILoan.STATE.ACTIVE,
            "ERROR: INACTIVE LOAN"
        );
        require(
            ds.indAccruedAPR[_account][_loanMarket][_commitment].id != 0,
            "ERROR: APR does not exist"
        );

  function _hasLoanAccount(address _account) internal view returns (bool) {
    AppStorageOpen storage ds = diamondStorage(); 
    require(ds.loanPassbook[_account].accOpenTime !=0, "ERROR: No Loan Account");
		return true;
  }

// =========== Reserve Functions =====================

	function _transferAnyBEP20(address _token, address _sender, address _recipient, uint256 _value) internal authContract(RESERVE_ID) {
		IBEP20(_token).approveFrom(_sender, address(this), _value);
    IBEP20(_token).transferFrom(_sender, _recipient, _value);
	}

	function _avblMarketReserves(bytes32 _market) internal view returns (uint) {
		require((_marketReserves(_market) - _marketUtilisation(_market)) >=0, "Mathematical error");
		return _marketReserves(_market) - _marketUtilisation(_market);
  }

	function _marketReserves(bytes32 _market) internal view returns (uint) {
		return _avblReservesDeposit(_market) + _avblReservesLoan(_market);
	}

    function _marketUtilisation(bytes32 _market)
        internal
        view
        returns (uint256)
    {
        return
            _utilisedReservesDeposit(_market) + _utilisedReservesLoan(_market);
    }

// =========== OracleOpen Functions =================
	function _getLatestPrice(bytes32 _market) internal view returns (uint) {
		// AppStorageOpen storage ds = diamondStorage();
		// require(ds.pairAddresses[_market] != address(0), "Invalid pair address given");
		// ( , int price, , , ) = AggregatorV3Interface(ds.pairAddresses[_market]).latestRoundData();
		// return uint256(price);
		return 1;
	}

    function _getFairPrice(uint256 _requestId)
        internal
        view
        returns (uint256 retPrice)
    {
        AppStorageOpen storage ds = diamondStorage();
        require(ds.priceData[_requestId].price != 0, "No fetched price");
        retPrice = ds.priceData[_requestId].price;
    }

    function _fairPrice(
        uint256 _requestId,
        uint256 _fPrice,
        bytes32 _market,
        uint256 _amount
    ) internal {
        AppStorageOpen storage ds = diamondStorage();
        PriceData storage newPrice = ds.priceData[_requestId];
        newPrice.market = _market;
        newPrice.amount = _amount;
        newPrice.price = _fPrice;
    }

// =========== AccessRegistry Functions =================
	function _hasRole(bytes32 role, address account) internal view returns (bool) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds._roles[role]._members[account];
	}

	function _addRole(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
		AppStorageOpen storage ds = diamondStorage(); 
		ds._roles[role]._members[account] = true;
		emit RoleGranted(role, account, msg.sender);
	}

	function _revokeRole(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
		AppStorageOpen storage ds = diamondStorage(); 
		ds._roles[role]._members[account] = false;
		emit RoleRevoked(role, account, msg.sender);
	}

	function _hasAdminRole(bytes32 role, address account) internal view returns (bool) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds._adminRoles[role]._adminMembers[account];
	}

	function _addAdminRole(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
		AppStorageOpen storage ds = diamondStorage(); 
		ds._adminRoles[role]._adminMembers[account] = true;
		emit AdminRoleDataGranted(role, account, msg.sender);
	}

	function _revokeAdmin(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
		AppStorageOpen storage ds = diamondStorage(); 
		ds._adminRoles[role]._adminMembers[account] = false;
		emit AdminRoleDataRevoked(role, account, msg.sender);
	}

	modifier authContract(uint _facetId) {
		require(_facetId == diamondStorage().facetIndex[msg.sig] || 
			diamondStorage().facetIndex[msg.sig] == 0, "Not permitted function call");
		_;
	}
}