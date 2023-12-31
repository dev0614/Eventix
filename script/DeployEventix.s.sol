// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Eventix} from "../src/Eventix.sol";

contract DeployEventix is Script {

    function run()external  returns(Eventix) {
        address minter=0x66aAf3098E1eB1F24348e84F509d8bcfD92D0620;
        vm.startBroadcast();
        Eventix eventix=new Eventix(minter);
        vm.stopBroadcast();
        return eventix;
    }
}
