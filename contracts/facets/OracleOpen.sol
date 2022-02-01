// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";

contract OracleOpen is Pausable, IOracleOpen {
    constructor() {
        // AppStorage storage ds = LibOpen.diamondStorage();
        // ds.adminOpenOracleAddress = msg.sender;
        // ds.oracle = IOracleOpen(msg.sender);
    }

    function getLatestPrice(bytes32 _market)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._getLatestPrice(_market);
    }

    function getFairPrice(uint256 _requestId)
        external
        view
        override
        returns (uint256)
    {
        return LibOpen._getFairPrice(_requestId);
    }

    function setFairPrice(
        uint256 _requestId,
        uint256 _fPrice,
        bytes32 _market,
        uint256 _amount
    ) external {
        LibOpen._fairPrice(_requestId, _fPrice, _market, _amount);
    }

<<<<<<< HEAD
    function liquidationTrigger(address account, uint256 loanId)
        external
        override
        onlyAdmin
        nonReentrant
        returns (bool)
    {
        LibOpen._liquidation(account, loanId);
        return true;
    }
=======
    // function liquidationTrigger(address account, uint loanId) external override onlyAdmin() nonReentrant() returns(bool) {
    //     LibOpen._liquidation(account, loanId);
    //     return true;
    // }
>>>>>>> dinh-diamond2

    function pauseOracle() external override onlyAdmin nonReentrant {
        _pause();
    }

    function unpauseOracle() external override onlyAdmin nonReentrant {
        _unpause();
    }

    function isPausedOracle() external view virtual override returns (bool) {
        return _paused();
    }

    modifier onlyAdmin() {
<<<<<<< HEAD
        AppStorageOpen storage ds = LibOpen.diamondStorage();
        require(
            LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress) ||
                LibOpen._hasAdminRole(
                    ds.adminOpenOracle,
                    ds.adminOpenOracleAddress
                ),
            "ERROR: Not an admin"
        );
=======
    	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
<<<<<<< HEAD
        require(LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress) || LibOpen._hasAdminRole(ds.adminOpenOracle, ds.adminOpenOracleAddress), "Admin role does not exist.");
>>>>>>> parent of be434cc (update auth<contractName>() ERROR, deposit contract visibility)
=======
        require(LibOpen._hasAdminRole(ds.superAdmin, ds.superAdminAddress) || LibOpen._hasAdminRole(ds.adminOpenOracle, ds.adminOpenOracleAddress), "ERROR: Not an admin");
>>>>>>> dinh-diamond2

        _;
    }
}
