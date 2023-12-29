// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Eventix} from "../src/Eventix.sol";

contract DeployEventix is Script {

    function run()external  returns(Eventix) {
        address minter=0xE6F3889C8EbB361Fa914Ee78fa4e55b1BBed3A96;
        vm.startBroadcast();
        Eventix eventix=new Eventix(minter);
        vm.stopBroadcast();
        return eventix;
    }
}
