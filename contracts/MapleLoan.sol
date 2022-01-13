// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IERC20 }             from "../modules/erc20/src/interfaces/IERC20.sol";
import { ERC20Helper }        from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory } from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";

import { IMapleGlobalsLike } from "./interfaces/Interfaces.sol";
import { IMapleLoan }        from "./interfaces/IMapleLoan.sol";

import { MapleLoanInternals } from "./MapleLoanInternals.sol";

/// @title MapleLoan implements a primitive loan with additional functionality, and is intended to be proxied.
contract MapleLoan is IMapleLoan, MapleLoanInternals {

    modifier whenProtocolNotPaused() {
        require(!isProtocolPaused(), "ML:PROTOCOL_PAUSED");
        _;
    }

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function migrate(address migrator_, bytes calldata arguments_) external override {
        require(msg.sender == _factory(),        "ML:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "ML:M:FAILED");
    }

    function setImplementation(address newImplementation_) external override {
        require(msg.sender == _factory(),               "ML:SI:NOT_FACTORY");
        require(_setImplementation(newImplementation_), "ML:SI:FAILED");
    }

    function upgrade(uint256 toVersion_, bytes calldata arguments_) external override {
        require(msg.sender == _borrower, "ML:U:NOT_BORROWER");

        emit Upgraded(toVersion_, arguments_);

        IMapleProxyFactory(_factory()).upgradeInstance(toVersion_, arguments_);
    }

    /************************/
    /*** Borrow Functions ***/
    /************************/

    function closeLoan() external override returns (uint256 principal_, uint256 interest_) {
        emit LoanClosed(principal_, interest_);

        uint256 drawableFundsBeforePayment = _drawableFunds;

        ( principal_, interest_ ) = _closeLoan();

        // Either the caller is the borrower or `_drawableFunds` has not decreased.
        require(msg.sender == _borrower || _drawableFunds >= drawableFundsBeforePayment, "ML:CL:CANNOT_USE_DRAWABLE");
    }

    function drawdownFunds(uint256 amount_, address destination_) external override whenProtocolNotPaused returns (uint256 collateralPosted_) {
        require(msg.sender == _borrower, "ML:DF:NOT_BORROWER");

        collateralPosted_ = _postCollateral();

        if (collateralPosted_ != uint256(0)) emit CollateralPosted(collateralPosted_);

        emit FundsDrawnDown(amount_, destination_);

        _drawdownFunds(amount_, destination_);
    }

    function makePayment() external override returns (uint256 principal_, uint256 interest_) {
        emit PaymentMade(principal_, interest_);

        uint256 drawableFundsBeforePayment = _drawableFunds;

        ( principal_, interest_ ) = _makePayment();

        // Either the caller is the borrower or `_drawableFunds` has not decreased.
        require(msg.sender == _borrower || _drawableFunds >= drawableFundsBeforePayment, "ML:MP:CANNOT_USE_DRAWABLE");
    }

    function postCollateral() external override whenProtocolNotPaused returns (uint256 collateralPosted_) {
        emit CollateralPosted(collateralPosted_ = _postCollateral());
    }

    function proposeNewTerms(address refinancer_, bytes[] calldata calls_) external override {
        require(msg.sender == _borrower, "ML:PNT:NOT_BORROWER");

        emit NewTermsProposed(_proposeNewTerms(refinancer_, calls_), refinancer_, calls_);
    }

    function removeCollateral(uint256 amount_, address destination_) external override whenProtocolNotPaused {
        require(msg.sender == _borrower, "ML:RC:NOT_BORROWER");

        emit CollateralRemoved(amount_, destination_);

        _removeCollateral(amount_, destination_);
    }

    function returnFunds() external override whenProtocolNotPaused returns (uint256 fundsReturned_) {
        emit FundsReturned(fundsReturned_ = _returnFunds());
    }

    function setBorrower(address newBorrower_) external override {
        require(msg.sender == _borrower, "ML:SB:NOT_BORROWER");

        emit BorrowerSet(_borrower = newBorrower_);
    }

    /**********************/
    /*** Lend Functions ***/
    /**********************/

    function acceptNewTerms(address refinancer_, bytes[] calldata calls_) external override whenProtocolNotPaused {
        require(msg.sender == _lender, "ML:ANT:NOT_LENDER");

        emit NewTermsAccepted(_acceptNewTerms(refinancer_, calls_), refinancer_, calls_);
    }

    function claimFunds(uint256 amount_, address destination_) external override whenProtocolNotPaused {
        require(msg.sender == _lender, "ML:CF:NOT_LENDER");

        emit FundsClaimed(amount_, destination_);

        _claimFunds(amount_, destination_);
    }

    function fundLoan(address lender_) external override whenProtocolNotPaused returns (uint256 fundsLent_) {
        emit Funded(lender_, fundsLent_ = _fundLoan(lender_), _nextPaymentDueDate);
    }

    function repossess(address destination_) external override whenProtocolNotPaused returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_) {
        require(msg.sender == _lender, "ML:R:NOT_LENDER");

        ( collateralRepossessed_, fundsRepossessed_ ) = _repossess(destination_);

        emit Repossessed(collateralRepossessed_, fundsRepossessed_, destination_);
    }

    function setLender(address lender_) external override {
        require(msg.sender == _lender, "ML:SPL:NOT_LENDER");

        emit LenderSet(_lender = lender_);
    }

    /*******************************/
    /*** Miscellaneous Functions ***/
    /*******************************/

    function skim(address token_, address destination_) external override whenProtocolNotPaused returns (uint256 skimmed_) {
        emit Skimmed(token_, skimmed_ = _getUnaccountedAmount(token_), destination_);

        require(ERC20Helper.transfer(token_, destination_, skimmed_), "L:S:TRANSFER_FAILED");
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function getAdditionalCollateralRequiredFor(uint256 drawdown_) public view override returns (uint256 collateral_) {
        // Determine the collateral needed in the contract for a reduced drawable funds amount.
        uint256 collateralNeeded  = _getCollateralRequiredFor(_principal, _drawableFunds - drawdown_, _principalRequested, _collateralRequired);
        uint256 currentCollateral = _collateral;

        return collateralNeeded > currentCollateral ? collateralNeeded - currentCollateral : uint256(0);
    }

    function getClosingPaymentBreakdown() external view override returns (uint256 principal_, uint256 interest_) {
        ( principal_, interest_ ) = _getClosingPaymentBreakdown();
    }

    function getNextPaymentBreakdown() external view override returns (uint256 principal_, uint256 interest_) {
        ( principal_, interest_ ) = _getNextPaymentBreakdown();
    }

    function isProtocolPaused() public view override returns (bool paused_) {
        return IMapleGlobalsLike(IMapleProxyFactory(_factory()).mapleGlobals()).protocolPaused();
    }

    /****************************/
    /*** State View Functions ***/
    /****************************/

    function borrower() external view override returns (address borrower_) {
        return _borrower;
    }

    function claimableFunds() external view override returns (uint256 claimableFunds_) {
        return _claimableFunds;
    }

    function closingRate() external view override returns (uint256 closingRate_) {
        return _closingRate;
    }

    function collateral() external view override returns (uint256 collateral_) {
        return _collateral;
    }

    function collateralAsset() external view override returns (address collateralAsset_) {
        return _collateralAsset;
    }

    function collateralRequired() external view override returns (uint256 collateralRequired_) {
        return _collateralRequired;
    }

    function drawableFunds() external view override returns (uint256 drawableFunds_) {
        return _drawableFunds;
    }

    function endingPrincipal() external view override returns (uint256 endingPrincipal_) {
        return _endingPrincipal;
    }

    function excessCollateral() external view override returns (uint256 excessCollateral_) {
        uint256 collateralNeeded  = _getCollateralRequiredFor(_principal, _drawableFunds, _principalRequested, _collateralRequired);
        uint256 currentCollateral = _collateral;

        return currentCollateral > collateralNeeded ? currentCollateral - collateralNeeded : uint256(0);
    }

    function factory() external view override returns (address factory_) {
        return _factory();
    }

    function fundsAsset() external view override returns (address fundsAsset_) {
        return _fundsAsset;
    }

    function gracePeriod() external view override returns (uint256 gracePeriod_) {
        return _gracePeriod;
    }

    function implementation() external view override returns (address implementation_) {
        return _implementation();
    }

    function interestRate() external view override returns (uint256 interestRate_) {
        return _interestRate;
    }

    function lender() external view override returns (address lender_) {
        return _lender;
    }

    function nextPaymentDueDate() external view override returns (uint256 nextPaymentDueDate_) {
        return _nextPaymentDueDate;
    }

    function paymentInterval() external view override returns (uint256 paymentInterval_) {
        return _paymentInterval;
    }

    function paymentsRemaining() external view override returns (uint256 paymentsRemaining_) {
        return _paymentsRemaining;
    }

    function principalRequested() external view override returns (uint256 principalRequested_) {
        return _principalRequested;
    }

    function principal() external view override returns (uint256 principal_) {
        return _principal;
    }

}
