// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";

import { IMapleLoanEvents } from "./IMapleLoanEvents.sol";

/// @title MapleLoan implements a primitive loan with additional functionality, and is intended to be proxied.
interface IMapleLoan is IMapleProxied, IMapleLoanEvents {

    /***********************/
    /*** State Variables ***/
    /***********************/

    /**
     *  @dev The borrower of the loan, responsible for repayments.
     */
    function borrower() external view returns (address borrower_);

    /**
     *  @dev The amount of funds that have yet to be claimed by the lender.
     */
    function claimableFunds() external view returns (uint256 claimableFunds_);

    /**
     *  @dev The annualized closing rate (APR), in units of 1e18, (i.e. 1% is 0.01e18).
     */
    function closingRate() external view returns (uint256 closingRate_);

    /**
     *  @dev The amount of collateral posted against outstanding (drawn down) principal.
     */
    function collateral() external view returns (uint256 collateral_);

    /**
     *  @dev The address of the asset deposited by the borrower as collateral, if needed.
     */
    function collateralAsset() external view returns (address collateralAsset_);

    /**
     *  @dev The amount of collateral required if all of the principal required is drawn down.
     */
    function collateralRequired() external view returns (uint256 collateralRequired_);

    /**
     *  @dev The amount of funds that have yet to be drawn down by the borrower.
     */
    function drawableFunds() external view returns (uint256 drawableFunds_);

    /**
     *  @dev The portion of principal to not be paid down as part of payment installments, which would need to be paid back upon final payment.
     *       If endingPrincipal = principal, loan is interest-only.
     */
    function endingPrincipal() external view returns (uint256 endingPrincipal_);

    /**
     *  @dev The asset deposited by the lender to fund the loan.
     */
    function fundsAsset() external view returns (address fundsAsset_);

    /**
     *  @dev The amount of time the borrower has, after a payment is due, to make a payment before being in default.
     */
    function gracePeriod() external view returns (uint256 gracePeriod_);

    /**
     *  @dev The annualized interest rate (APR), in units of 1e18, (i.e. 1% is 0.01e18).
     */
    function interestRate() external view returns (uint256 interestRate_);

    /**
     *  @dev The lender of the Loan.
     */
    function lender() external view returns (address lender_);

    /**
     *  @dev The timestamp due date of the next payment.
     */
    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    /**
     *  @dev The specified time between loan payments.
     */
    function paymentInterval() external view returns (uint256 paymentInterval_);

    /**
     *  @dev The number of payment installments remaining for the loan.
     */
    function paymentsRemaining() external view returns (uint256 paymentsRemaining_);

    /**
     *  @dev The amount of principal owed (initially, the requested amount), which needs to be paid back.
     */
    function principal() external view returns (uint256 principal_);

    /**
     *  @dev The initial principal amount requested by the borrower.
     */
    function principalRequested() external view returns (uint256 principalRequested_);

    /********************************/
    /*** State Changing Functions ***/
    /********************************/

    /**
     *  @dev   Accept the proposed terms ans trigger refinance execution
     *  @param refinancer_ The address of the refinancer contract.
     *  @param calls_      The encoded arguments to be passed to refinancer.
     */
    function acceptNewTerms(address refinancer_, bytes[] calldata calls_) external;

    /**
     *  @dev   Claim funds that have been paid (principal, interest, and late fees).
     *  @param amount_      The amount to be claimed.
     *  @param destination_ The address to send the funds.
     */
    function claimFunds(uint256 amount_, address destination_) external;

    /**
     *  @dev    Repay all principal and fees and close a loan.
     *  @return principal_ The portion of the amount paid paying back principal.
     *  @return interest_  The portion of the amount paid paying interest fees.
     */
    function closeLoan() external returns (uint256 principal_, uint256 interest_);

    /**
     *  @dev    Draw down funds from the loan.
     *  @param  amount_           The amount to draw down.
     *  @param  destination_      The address to send the funds.
     *  @return collateralPosted_ The amount of additional collateral posted, if any.
     */
    function drawdownFunds(uint256 amount_, address destination_) external returns (uint256 collateralPosted_);

    /**
     *  @dev    Lend funds to the loan/borrower.
     *  @param  lender_    The address to be registered as the lender.
     *  @return fundsLent_ The amount funded.
     */
    function fundLoan(address lender_) external returns (uint256 fundsLent_);

    /**
     *  @dev    Make a payment to the loan.
     *  @return principal_ The portion of the amount paid paying back principal.
     *  @return interest_  The portion of the amount paid paying interest fees.
     */
    function makePayment() external returns (uint256 principal_, uint256 interest_);

    /**
     *  @dev    Post collateral to the loan.
     *  @return collateralPosted_ The amount posted.
     */
    function postCollateral() external returns (uint256 collateralPosted_);

    /**
     *  @dev   Propose new terms for refinance
     *  @param refinancer_ The address of the refinancer contract.
     *  @param calls_      The encoded arguments to be passed to refinancer.
     */
    function proposeNewTerms(address refinancer_, bytes[] calldata calls_) external;

    /**
     *  @dev   Remove collateral from the loan (opposite of posting collateral).
     *  @param amount_      The amount removed.
     *  @param destination_ The destination to send the removed collateral.
     */
    function removeCollateral(uint256 amount_, address destination_) external;

    /**
     *  @dev    Return funds to the loan (opposite of drawing down).
     *  @return fundsReturned_ The amount returned.
     */
    function returnFunds() external returns (uint256 fundsReturned_);

    /**
     *  @dev    Repossess collateral, and any funds, for a loan in default.
     *  @param  destination_           The address where the collateral and funds asset is to be sent, if any.
     *  @return collateralRepossessed_ The amount of collateral asset repossessed.
     *  @return fundsRepossessed_      The amount of funds asset repossessed.
     */
    function repossess(address destination_) external returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_);

    /**
     *  @dev   Set the borrower to a new account.
     *  @param borrower_ The address of the new borrower.
     */
    function setBorrower(address borrower_) external;

    /**
     *  @dev   Set the lender to a new account.
     *  @param lender_ The address of the new lender.
     */
    function setLender(address lender_) external;

    /**
     *  @dev    Remove some token (neither fundsAsset nor collateralAsset) from the loan.
     *  @param  token_       The address of the token contract.
     *  @param  destination_ The recipient of the token.
     *  @return skimmed_     The amount of token removed from the loan.
     */
    function skim(address token_, address destination_) external returns (uint256 skimmed_);

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @dev    Returns the excess collateral that can be removed.
     *  @return excessCollateral_ The excess collateral that can be removed, if any.
     */
    function excessCollateral() external view returns (uint256 excessCollateral_);

    /**
     *  @dev    Get the additional collateral to be posted to drawdown some amount.
     *  @param  drawdown_             The amount desired to be drawn down.
     *  @return additionalCollateral_ The additional collateral that must be posted, if any.
     */
    function getAdditionalCollateralRequiredFor(uint256 drawdown_) external view returns (uint256 additionalCollateral_);

    /**
     *  @dev    Get the breakdown of the total payment needed to satisfy closing the loan.
     *  @return principal_ The portion of the total amount that will go towards principal.
     *  @return interest_  The portion of the total amount that will go towards interest fees.
     */
    function getClosingPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_);

    /**
     *  @dev    Get the breakdown of the total payment needed to satisfy `numberOfPayments` payment installments.
     *  @return principal_ The portion of the total amount that will go towards principal.
     *  @return interest_  The portion of the total amount that will go towards interest fees.
     */
    function getNextPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_);

    /**
     *  @dev    Returns whether the protocol is paused.
     *  @return paused_ A boolean indicating if protocol is paused.
     */
    function isProtocolPaused() external view returns (bool paused_);

}
