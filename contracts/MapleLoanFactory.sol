// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { MapleProxyFactory } from "../modules/maple-proxy-factory/contracts/MapleProxyFactory.sol";

import { IMapleLoanFactory } from "./interfaces/IMapleLoanFactory.sol";

/// @title MapleLoanFactory deploys Loan instances.
contract MapleLoanFactory is IMapleLoanFactory, MapleProxyFactory {

    /// @param mapleGlobals_ The address of a Maple Globals contract.
    constructor(address mapleGlobals_) MapleProxyFactory(mapleGlobals_) {}

}
