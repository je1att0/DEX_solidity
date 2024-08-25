// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DEX} from "../src/DEX.sol";

contract DEXScript is Script {
    DEX public dex;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        dex = new DEX();

        vm.stopBroadcast();
    }
}
