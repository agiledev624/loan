// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IMapleGlobalsLike {

    /// @dev A boolean indicating whether the protocol is paused.
    function protocolPaused() external view returns (bool paused_);

}
