// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IMapleProxyFactory } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";

/// @title MapleLoanFactory deploys Loan instances.
interface IMapleLoanFactory is IMapleProxyFactory {}
