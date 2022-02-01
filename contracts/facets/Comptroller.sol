// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "../util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "../libraries/LibOpen.sol";
import "../libraries/AppStorageOpen.sol";

contract Comptroller is Pausable, IComptroller {
    // using Address for address;

	event APRupdated(address indexed admin, uint indexed newAPR, uint indexed timestamp);
	event APYupdated(address indexed admin, uint indexed newAPY, uint indexed timestamp);
	
	event ReserveFactorUpdated(address indexed admin, uint oldReserveFactor, uint indexed newReserveFactor, uint indexed timestamp);
	event LoanIssuanceFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event LoanClosureFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event LoanPreClosureFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event DepositPreClosureFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event DepositWithdrawalFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event CollateralReleaseFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event YieldConversionFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event MarketSwapFeesUpdated(address indexed admin, uint oldFees, uint indexed newFees, uint indexed timestamp);
	event MaxWithdrawalUpdated(address indexed admin, uint indexed newFactor, uint indexed newBlockLimit, uint oldFactor, uint oldBlockLimit, uint timestamp);

    event ReserveFactorUpdated(
        address indexed admin,
        uint256 oldReserveFactor,
        uint256 indexed newReserveFactor,
        uint256 indexed timestamp
    );
    event LoanIssuanceFeesUpdated(
        address indexed admin,
        uint256 oldFees,
        uint256 indexed newFees,
        uint256 indexed timestamp
    );
    event LoanClosureFeesUpdated(
        address indexed admin,
        uint256 oldFees,
        uint256 indexed newFees,
        uint256 indexed timestamp
    );
    event LoanPreClosureFeesUpdated(
        address indexed admin,
        uint256 oldFees,
        uint256 indexed newFees,
        uint256 indexed timestamp
    );
    event DepositPreClosureFeesUpdated(
        address indexed admin,
        uint256 oldFees,
        uint256 indexed newFees,
        uint256 indexed timestamp
    );
    event DepositWithdrawalFeesUpdated(
        address indexed admin,
        uint256 oldFees,
        uint256 indexed newFees,
        uint256 indexed timestamp
    );
    event CollateralReleaseFeesUpdated(
        address indexed admin,
        uint256 oldFees,
        uint256 indexed newFees,
        uint256 indexed timestamp
    );
    event YieldConversionFeesUpdated(
        address indexed admin,
        uint256 oldFees,
        uint256 indexed newFees,
        uint256 indexed timestamp
    );
    event MarketSwapFeesUpdated(
        address indexed admin,
        uint256 oldFees,
        uint256 indexed newFees,
        uint256 indexed timestamp
    );
    event MaxWithdrawalUpdated(
        address indexed admin,
        uint256 indexed newFactor,
        uint256 indexed newBlockLimit,
        uint256 oldFactor,
        uint256 oldBlockLimit,
        uint256 timestamp
    );

    constructor() {
        // 	AppStorageOpen storage ds = LibOpen.diamondStorage();
        // 	ds.comptroller = IComptroller(msg.sender);
    }

    // receive() external payable {
    // 	AppStorageOpen storage ds = LibOpen.diamondStorage();
    // 	 payable(ds.superAdminAddress).transfer(_msgValue());
    // }

    // fallback() external payable {
    // 	AppStorageOpen storage ds = LibOpen.diamondStorage();
    // 	payable(ds.superAdminAddress).transfer(_msgValue());
    // }

    function getAPR(bytes32 _commitment)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._getAPR(_commitment);
    }

    function getAPRInd(bytes32 _commitment, uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._getAPRInd(_commitment, _index);
    }

    function getAPY(bytes32 _commitment)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._getAPY(_commitment);
    }

    function getAPYInd(bytes32 _commitment, uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._getAPYInd(_commitment, _index);
    }

    function getApytime(bytes32 _commitment, uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._getApytime(_commitment, _index);
    }

    function getAprtime(bytes32 _commitment, uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._getAprtime(_commitment, _index);
    }

    function getApyLastTime(bytes32 _commitment)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._getApyLastTime(_commitment);
    }

    function getAprLastTime(bytes32 _commitment)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._getAprLastTime(_commitment);
    }

	// SETTERS
	function updateAPY(bytes32 _commitment, uint _apy) external override authComptroller() nonReentrant() returns (bool) {
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		APY storage apyUpdate = ds.indAPYRecords[_commitment];

		// if(apyUpdate.time.length != apyUpdate.apyChanges.length) return false;
		apyUpdate.commitment = _commitment;
		apyUpdate.time.push(block.timestamp);
		apyUpdate.apyChanges.push(_apy);
		emit APYupdated(msg.sender, _apy, block.timestamp);
		return true;
	}

	function updateAPR(bytes32 _commitment, uint _apr) external override authComptroller() nonReentrant() returns (bool ) {
		AppStorageOpen storage ds = LibOpen.diamondStorage();
		APR storage aprUpdate = ds.indAPRRecords[_commitment];

		if(aprUpdate.time.length != aprUpdate.aprChanges.length) return false;

		aprUpdate.commitment = _commitment;
		aprUpdate.time.push(block.timestamp);
		aprUpdate.aprChanges.push(_apr);
		emit APRupdated(msg.sender, _apr, block.timestamp);
		return true;
	}

    function getCommitment(uint256 _index)
        external
        view
        override
        returns (bytes32)
    {
        return LibOpen._getCommitment(_index);
    }

    function setCommitment(bytes32 _commitment)
        external
        override
        authComptroller
    {
        LibOpen._setCommitment(_commitment);
    }

    function liquidationTrigger(uint256 loanID) external override {}

    // SETTERS
    function updateAPY(bytes32 _commitment, uint256 _apy)
        external
        override
        authComptroller
        nonReentrant
        returns (bool)
    {
        return LibOpen._updateApy(_commitment, _apy);
    }

    function updateAPR(bytes32 _commitment, uint256 _apr)
        external
        override
        authComptroller
        nonReentrant
        returns (bool)
    {
        return LibOpen._updateApr(_commitment, _apr);
    }

    function calcAPR(
        bytes32 _commitment,
        uint256 oldLengthAccruedInterest,
        uint256 oldTime,
        uint256 aggregateInterest
    )
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return
            LibOpen._calcAPR(
                _commitment,
                oldLengthAccruedInterest,
                oldTime,
                aggregateInterest
            );
    }

    function calcAPY(
        bytes32 _commitment,
        uint256 oldLengthAccruedYield,
        uint256 oldTime,
        uint256 aggregateYield
    )
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return
            LibOpen._calcAPY(
                _commitment,
                oldLengthAccruedYield,
                oldTime,
                aggregateYield
            );
    }

    function updateLoanIssuanceFees(uint256 fees)
        external
        override
        authComptroller
        returns (bool)
    {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        uint256 oldFees = ds.loanIssuanceFees;
        ds.loanIssuanceFees = fees;

        emit LoanIssuanceFeesUpdated(
            msg.sender,
            oldFees,
            ds.loanIssuanceFees,
            block.timestamp
        );
        return true;
    }

    function updateLoanClosureFees(uint256 fees)
        external
        override
        authComptroller
        returns (bool)
    {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        uint256 oldFees = ds.loanClosureFees;
        ds.loanClosureFees = fees;

        emit LoanClosureFeesUpdated(
            msg.sender,
            oldFees,
            ds.loanClosureFees,
            block.timestamp
        );
        return true;
    }

    function updateLoanPreClosureFees(uint256 fees)
        external
        override
        authComptroller
        returns (bool)
    {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        uint256 oldFees = ds.loanPreClosureFees;
        ds.loanPreClosureFees = fees;

        emit LoanPreClosureFeesUpdated(
            msg.sender,
            oldFees,
            ds.loanPreClosureFees,
            block.timestamp
        );
        return true;
    }

    function depositPreClosureFees() external view override returns (uint256) {
        return LibOpen.diamondStorage().depositPreClosureFees;
    }

    function updateDepositPreclosureFees(uint256 fees)
        external
        override
        authComptroller
        returns (bool)
    {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        uint256 oldFees = ds.depositPreClosureFees;
        ds.depositPreClosureFees = fees;

        emit DepositPreClosureFeesUpdated(
            msg.sender,
            oldFees,
            ds.depositPreClosureFees,
            block.timestamp
        );
        return true;
    }

    function depositWithdrawalFees() external view override returns (uint256) {
        return LibOpen.diamondStorage().depositWithdrawalFees;
    }

    function updateWithdrawalFees(uint256 fees)
        external
        override
        authComptroller
        returns (bool)
    {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        uint256 oldFees = ds.depositWithdrawalFees;
        ds.depositWithdrawalFees = fees;

        emit DepositWithdrawalFeesUpdated(
            msg.sender,
            oldFees,
            ds.depositWithdrawalFees,
            block.timestamp
        );
        return true;
    }

    function collateralReleaseFees() external view override returns (uint256) {
        return LibOpen.diamondStorage().collateralReleaseFees;
    }

    function updateCollateralReleaseFees(uint256 fees)
        external
        override
        authComptroller
        returns (bool)
    {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        uint256 oldFees = ds.collateralReleaseFees;
        ds.collateralReleaseFees = fees;

        emit CollateralReleaseFeesUpdated(
            msg.sender,
            oldFees,
            ds.collateralReleaseFees,
            block.timestamp
        );
        return true;
    }

    function updateYieldConversion(uint256 fees)
        external
        override
        authComptroller
        returns (bool)
    {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        uint256 oldFees = ds.yieldConversionFees;
        ds.yieldConversionFees = fees;

        emit YieldConversionFeesUpdated(
            msg.sender,
            oldFees,
            ds.yieldConversionFees,
            block.timestamp
        );
        return true;
    }

    function updateMarketSwapFees(uint256 fees)
        external
        override
        authComptroller
        returns (bool)
    {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        uint256 oldFees = ds.marketSwapFees;
        ds.marketSwapFees = fees;

	modifier authComptroller() {
    	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		require(LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress) || LibOpen._hasAdminRole(ds.adminComptroller, ds.adminComptrollerAddress), "ERROR: Not an admin");
		_;
	}

    function updateReserveFactor(uint256 _reserveFactor)
        external
        override
        authComptroller
        returns (bool)
    {
        // implementing the barebones version for testnet.
        //  if cdr >= reserveFactor, 1:3 possible, else 1:2 possible.
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        uint256 oldReserveFactor = ds.reserveFactor;
        ds.reserveFactor = _reserveFactor;

        emit ReserveFactorUpdated(
            msg.sender,
            oldReserveFactor,
            ds.reserveFactor,
            block.timestamp
        );
        return true;
    }

    // this function sets a maximum permissible amount that can be moved in a single transaction without the admin permissions.
    function updateMaxWithdrawal(uint256 factor, uint256 blockLimit)
        external
        override
        authComptroller
        returns (bool)
    {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        uint256 oldFactor = ds.maxWithdrawalFactor;
        uint256 oldBlockLimit = blockLimit;

        ds.maxWithdrawalFactor = factor;
        ds.maxWithdrawalBlockLimit = blockLimit;

        emit MaxWithdrawalUpdated(
            msg.sender,
            ds.maxWithdrawalFactor,
            ds.maxWithdrawalBlockLimit,
            oldFactor,
            oldBlockLimit,
            block.timestamp
        );
        return true;
    }

    function getReserveFactor() external view override returns (uint256) {
        return LibOpen._getReserveFactor();
    }

    modifier authComptroller() {
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        require(
            LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress) ||
                LibOpen._hasAdminRole(
                    ds.adminComptroller,
                    ds.adminComptrollerAddress
                ),
            "ERROR: Not an admin"
        );
        _;
    }

    function pauseComptroller() external override authComptroller nonReentrant {
        _pause();
    }

    function unpauseComptroller()
        external
        override
        authComptroller
        nonReentrant
    {
        _unpause();
    }

    function isPausedComptroller()
        external
        view
        virtual
        override
        returns (bool)
    {
        return _paused();
    }
}
