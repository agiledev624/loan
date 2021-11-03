// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import { IERC20 }             from "../modules/erc20/src/interfaces/IERC20.sol";
import { IMapleProxyFactory } from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";

import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { ILenderLike } from "./interfaces/Interfaces.sol";
import { IMapleLoan }  from "./interfaces/IMapleLoan.sol";

import { MapleLoanInternals } from "./MapleLoanInternals.sol";

/// @title MapleLoan implements a primitive loan with additional functionality, and is intended to be proxied.
contract MapleLoan is IMapleLoan, MapleLoanInternals {

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

        IMapleProxyFactory(_factory()).upgradeInstance(toVersion_, arguments_);

        emit Upgraded(toVersion_, arguments_);
    }

    /************************/
    /*** Borrow Functions ***/
    /************************/

    function closeLoan(uint256 amount_) external override returns (uint256 principal_, uint256 interest_) {
        if (amount_ > uint256(0)) ERC20Helper.transferFrom(_fundsAsset, msg.sender, address(this), amount_);

        ( principal_, interest_ ) = _closeLoan();

        // TODO discuss events with offchain team
        emit PaymentMade(principal_, interest_);
    }

    function drawdownFunds(uint256 amount_, address destination_) external override returns (uint256 collateralPosted_) {
        require(msg.sender == _borrower, "ML:DF:NOT_BORROWER");

        if (amount_ == uint256(0)) return uint256(0);

        // Post additional collateral required to facilitate this drawdown, if needed.
        postCollateral(collateralPosted_ = getAdditionalCollateralRequiredFor(amount_));

        _drawdownFunds(amount_, destination_);

        emit FundsDrawnDown(amount_, destination_);
    }

    function makePayment(uint256 amount_) external override returns (uint256 principal_,uint256 interest_) {
        if (amount_ > uint256(0)) ERC20Helper.transferFrom(_fundsAsset, msg.sender, address(this), amount_);

        ( principal_, interest_ ) = _makePayment();

        emit PaymentMade(principal_, interest_);
    }

    function postCollateral(uint256 amount_) public override returns (uint256 collateralPosted_) {
        if (amount_ > uint256(0)) ERC20Helper.transferFrom(_collateralAsset, msg.sender, address(this), amount_);

        emit CollateralPosted(collateralPosted_ = _postCollateral());
    }

    function proposeNewTerms(address refinancer_, bytes[] calldata calls_) external override {
        require(msg.sender == _borrower, "ML:PNT:NOT_BORROWER");

        emit NewTermsProposed(_proposeNewTerms(refinancer_, calls_), refinancer_, calls_);
    }

    function removeCollateral(uint256 amount_, address destination_) external override {
        require(msg.sender == _borrower, "ML:RC:NOT_BORROWER");

        if (amount_ == uint256(0)) return;

        _removeCollateral(amount_, destination_);

        emit CollateralRemoved(amount_, destination_);
    }

    function returnFunds(uint256 amount_) public override returns (uint256 fundsReturned_) {
        if (amount_ > uint256(0)) ERC20Helper.transferFrom(_fundsAsset, msg.sender, address(this), amount_);

        emit FundsReturned(fundsReturned_ = _returnFunds());
    }

    function setBorrower(address borrower_) external override {
        require(msg.sender == _borrower, "ML:TB:NOT_BORROWER");

        emit BorrowerSet(_borrower = borrower_);
    }

    /**********************/
    /*** Lend Functions ***/
    /**********************/

    function acceptNewTerms(address refinancer_, bytes[] calldata calls_, uint256 amount_) external override {
        require(msg.sender == _lender, "ML:ANT:NOT_LENDER");

        if (amount_ > uint256(0)) ERC20Helper.transferFrom(_fundsAsset, msg.sender, address(this), amount_);

        emit NewTermsAccepted(_acceptNewTerms(refinancer_, calls_), refinancer_, calls_);
    }

    function claimFunds(uint256 amount_, address destination_) external override {
        require(msg.sender == _lender, "ML:CF:NOT_LENDER");

        if (amount_ == uint256(0)) return;

        _claimFunds(amount_, destination_);

        emit FundsClaimed(amount_, destination_);
    }

    function fundLoan(address lender_, uint256 amount_) external override returns (uint256 fundsLent_) {
        if (amount_ > uint256(0)) ERC20Helper.transferFrom(_fundsAsset, msg.sender, address(this), amount_);

        if (_nextPaymentDueDate > 0) {
            // If the loan is active, send any unaccounted amount of funds asset toi the internally saved lender.
            ERC20Helper.transfer(_fundsAsset, _lender, fundsLent_ = _getUnaccountedAmount(_fundsAsset));

            emit FundsRedirected(fundsLent_, _lender);

            return fundsLent_;
        }

        emit Funded(lender_, fundsLent_ = _fundLoan(lender_), _nextPaymentDueDate);
    }

    function repossess(address destination_) external override returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_) {
        require(msg.sender == _lender, "ML:R:NOT_LENDER");

        ( collateralRepossessed_, fundsRepossessed_ ) = _repossess(destination_);

        emit Repossessed(collateralRepossessed_, fundsRepossessed_, destination_);
    }

    function setLender(address lender_) external override {
        require(msg.sender == _lender, "ML:TL:NOT_LENDER");

        emit LenderSet(_lender = lender_);
    }

    /*******************************/
    /*** Miscellaneous Functions ***/
    /*******************************/

    function skim(address token_, address destination_) external override returns (uint256 skimmed_) {
        require((msg.sender == _borrower) || (msg.sender == _lender),                                           "L:S:NO_AUTH");
        require((token_ != _fundsAsset) && (token_ != _collateralAsset),                                        "L:S:INVALID_TOKEN");
        require(ERC20Helper.transfer(token_, destination_, skimmed_ = IERC20(token_).balanceOf(address(this))), "L:S:TRANSFER_FAILED");

        emit Skimmed(token_, skimmed_, destination_);
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function factory() external view override returns (address factory_) {
        return _factory();
    }

    function excessCollateral() external view override returns (uint256 excessCollateral_) {
        uint256 collateralNeeded = _getCollateralRequiredFor(_principal, _drawableFunds, _principalRequested, _collateralRequired);

        return _collateral > collateralNeeded ? _collateral - collateralNeeded : uint256(0);
    }

    function getAdditionalCollateralRequiredFor(uint256 drawdown_) public view override returns (uint256 collateral_) {
        uint256 collateralNeeded = _getCollateralRequiredFor(_principal, _drawableFunds - drawdown_, _principalRequested, _collateralRequired);

        return collateralNeeded > _collateral ? collateralNeeded - _collateral : uint256(0);
    }

    function getEarlyPaymentBreakdown() external view override returns (uint256 principal_, uint256 interest_) {
        ( principal_, interest_ ) = _getEarlyPaymentBreakdown();
    }

    function getNextPaymentBreakdown() external view override returns (uint256 principal_, uint256 interest_) {
        ( principal_, interest_ ) = _getNextPaymentBreakdown();
    }

    function implementation() external view override returns (address implementation_) {
        return _implementation();
    }

    /*************************************/
    /*** State Variable View Functions ***/
    /*************************************/

    function borrower() external view override returns (address borrower_) {
        return _borrower;
    }

    function claimableFunds() external view override returns (uint256 claimableFunds_) {
        return _claimableFunds;
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

    function earlyFeeRate() external view override returns (uint256 earlyFeeRate_) {
        return _earlyFeeRate;
    }

    function endingPrincipal() external view override returns (uint256 endingPrincipal_) {
        return _endingPrincipal;
    }

    function fundsAsset() external view override returns (address fundsAsset_) {
        return _fundsAsset;
    }

    function gracePeriod() external view override returns (uint256 gracePeriod_) {
        return _gracePeriod;
    }

    function interestRate() external view override returns (uint256 interestRate_) {
        return _interestRate;
    }

    function lateFeeRate() external view override returns (uint256 lateFeeRate_) {
        return _lateFeeRate;
    }

    function lateInterestPremium() external view override returns (uint256 lateInterestPremium_) {
        return _lateInterestPremium;
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

    // Needed for `fundLoan` call from PoolV1
    function superFactory() external view override returns (address superFactory_) {
        return _factory();
    }

}
