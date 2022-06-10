// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './bisectinit.sol';
import './bisectchallenge.sol';

contract Bisect {
    Verifierbisectinit init;
    Verifierbisectchallenge chal;

    constructor (address a, address b) {
        init = Verifierbisectinit(a);
        chal = Verifierbisectchallenge(b);
    }

    struct Challenge {
        uint state;
        uint[2] key1;
        uint[2] key2;
    }

    mapping (bytes32 => Challenge) challenges;

    function initChallenge(
        bytes32 id,
        uint[2] memory key1,
        uint[2] memory key2,
        uint[2] memory step1,
        uint[2] memory hash1,
        uint[2] memory step2,
        uint[2] memory hash2,
        uint[2] memory step3,
        uint[2] memory hash3,
        uint state,
        bytes memory proof
    ) public {
        require(challenges[id].state == 0, "state exists");
        uint[] memory params = new uint[](17);
        params[0] = key1[0];
        params[1] = key1[1];
        params[2] = key2[0];
        params[3] = key2[1];
        params[4] = step1[0];
        params[5] = step1[1];
        params[6] = hash1[0];
        params[7] = hash1[1];
        params[8] = step2[0];
        params[9] = step2[1];
        params[10] = hash2[0];
        params[11] = hash2[1];
        params[12] = step3[0];
        params[13] = step3[1];
        params[14] = hash3[0];
        params[15] = hash3[1];
        params[16] = state;
        init.verifyProof(proof, params);
        challenges[id].key1 = key1;
        challenges[id].key2 = key2;
        challenges[id].state = state;
    }

}