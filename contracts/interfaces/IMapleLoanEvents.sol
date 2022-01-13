// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

/// @title IMapleLoanEvents defines the events for a MapleLoan.
interface IMapleLoanEvents {

    /**
     *  @dev   Borrower was set.
     *  @param borrower_ Address that is now the borrower.
     */
    event BorrowerSet(address borrower_);

    /**
     *  @dev   Collateral was posted.
     *  @param amount_ The amount of collateral posted.
     */
    event CollateralPosted(uint256 amount_);

    /**
     *  @dev   Collateral was removed.
     *  @param amount_      The amount of collateral removed.
     *  @param destination_ The recipient of the collateral removed.
     */
    event CollateralRemoved(uint256 amount_, address indexed destination_);

    /**
     *  @dev   The loan was funded.
     *  @param lender_             The address of the lender.
     *  @param amount_             The amount funded.
     *  @param nextPaymentDueDate_ The due date of the next payment.
     */
    event Funded(address indexed lender_, uint256 amount_, uint256 nextPaymentDueDate_);

    /**
     *  @dev   Funds were claimed.
     *  @param amount_      The amount of funds claimed.
     *  @param destination_ The recipient of the funds claimed.
     */
    event FundsClaimed(uint256 amount_, address indexed destination_);

    /**
     *  @dev   Funds were drawn.
     *  @param amount_      The amount of funds drawn.
     *  @param destination_ The recipient of the funds drawn down.
     */
    event FundsDrawnDown(uint256 amount_, address indexed destination_);

    /**
     *  @dev   Funds were redirected on an additional `fundLoan` call.
     *  @param amount_      The amount of funds redirected.
     *  @param destination_ The recipient of the redirected funds.
     */
    event FundsRedirected(uint256 amount_, address indexed destination_);

    /**
     *  @dev   Funds were returned.
     *  @param amount_ The amount of funds returned.
     */
    event FundsReturned(uint256 amount_);

    /**
     *  @dev   The loan was initialized.
     *  @param borrower_    The address of the borrower.
     *  @param assets_      Array of asset addresses.
     *                          [0]: collateralAsset,
     *                          [1]: fundsAsset.
     *  @param termDetails_ Array of loan parameters:
     *                          [0]: gracePeriod,
     *                          [1]: paymentInterval,
     *                          [2]: payments,
     *  @param amounts_     Requested amounts:
     *                          [0]: collateralRequired,
     *                          [1]: endingPrincipal,
     *                          [2]: principalRequested.
     *  @param rates_       Fee parameters:
     *                          [0]: closingRate,
     *                          [1]: interestRate.
     */
    event Initialized(address indexed borrower_, address[2] assets_, uint256[3] termDetails_, uint256[3] amounts_, uint256[2] rates_);

    /**
     *  @dev   Lender was set.
     *  @param lender_ Address that is now the lender.
     */
    event LenderSet(address lender_);

    /**
     *  @dev   Loan was repaid early and closed.
     *  @param principalPaid_ The portion of the total amount that went towards principal.
     *  @param interestPaid_  The portion of the total amount that went towards interest fees.
     */
    event LoanClosed(uint256 principalPaid_, uint256 interestPaid_);

    /**
     *  @dev   A refinance was proposed.
     *  @param refinanceCommitment_ The hash of the refinancer and calls proposed.
     *  @param refinancer_          The address that will execute the refinance.
     *  @param calls_               The individual calls for the refinancer contract.
     */
    event NewTermsAccepted(bytes32 refinanceCommitment_, address refinancer_, bytes[] calls_);

    /**
     *  @dev   A refinance was proposed.
     *  @param refinanceCommitment_ The hash of the refinancer and calls proposed.
     *  @param refinancer_          The address that will execute the refinance.
     *  @param calls_               The individual calls for the refinancer contract.
     */
    event NewTermsProposed(bytes32 refinanceCommitment_, address refinancer_, bytes[] calls_);

    /**
     *  @dev   Payments were made.
     *  @param principalPaid_ The portion of the total amount that went towards principal.
     *  @param interestPaid_  The portion of the total amount that went towards interest fees.
     */
    event PaymentMade(uint256 principalPaid_, uint256 interestPaid_);

    /**
     *  @dev   The loan was in default and funds and collateral was repossessed by the lender.
     *  @param collateralRepossessed_ The amount of collateral asset repossessed.
     *  @param fundsRepossessed_      The amount of funds asset repossessed.
     *  @param destination_           The recipient of the collateral and funds, if any.
     */
    event Repossessed(uint256 collateralRepossessed_, uint256 fundsRepossessed_, address indexed destination_);

    /**
     *  @dev   Some token (neither fundsAsset nor collateralAsset) was removed from the loan.
     *  @param token_       The address of the token contract.
     *  @param amount_      The amount of token remove from the loan.
     *  @param destination_ The recipient of the token.
     */
    event Skimmed(address indexed token_, uint256 amount_, address indexed destination_);

}
