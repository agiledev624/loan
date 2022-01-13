// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IRefinancer } from "./interfaces/IRefinancer.sol";

import { MapleLoanInternals } from "./MapleLoanInternals.sol";

/// @title Refinancer uses storage from a MapleLoan defined by MapleLoanInternals.
contract Refinancer is IRefinancer, MapleLoanInternals {

    function decreasePrincipal(uint256 amount_) external override {
        require(_drawableFunds >= amount_, "R:DP:OUTSTANDING_TOO_LARGE");

        _principal          -= amount_;
        _principalRequested -= amount_;
        _drawableFunds      -= amount_;

        require(_principal >= _endingPrincipal, "R:DP:BELOW_ENDING_PRINCIPAL");

        emit PrincipalDecreased(amount_);
    }

    function increasePrincipal(uint256 amount_) external override {
        // Cannot under-fund the principal increase, but over-funding results in additional funds left unaccounted for.
        require(_getUnaccountedAmount(_fundsAsset) >= amount_, "R:IP:INSUFFICIENT_AMOUNT");

        _principal          += amount_;
        _principalRequested += amount_;
        _drawableFunds      += amount_;

        emit PrincipalIncreased(amount_);
    }

    function setClosingRate(uint256 closingRate_) external override {
        emit ClosingRateSet(_closingRate = closingRate_);
    }

    function setCollateralRequired(uint256 collateralRequired_) external override {
        emit CollateralRequiredSet(_collateralRequired = collateralRequired_);
    }

    function setEndingPrincipal(uint256 endingPrincipal_) external override {
        require(endingPrincipal_ <= _principal, "R:DP:ABOVE_CURRENT_PRINCIPAL");
        emit EndingPrincipalSet(_endingPrincipal = endingPrincipal_);
    }

    function setGracePeriod(uint256 gracePeriod_) external override {
        emit GracePeriodSet(_gracePeriod = gracePeriod_);
    }

    function setInterestRate(uint256 interestRate_) external override {
        emit InterestRateSet(_interestRate = interestRate_);
    }

    function setPaymentInterval(uint256 paymentInterval_) external override {
        emit PaymentIntervalSet(_paymentInterval = paymentInterval_);
    }

    function setPaymentsRemaining(uint256 paymentsRemaining_) external override {
        emit PaymentsRemainingSet(_paymentsRemaining = paymentsRemaining_);
    }

}
