// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './bisectinit.sol';
import './bisectchallenge.sol';
import 'hardhat/console.sol';

contract Bisect {
    Verifierbisectinit init;
    Verifierbisectchallenge chal;

    constructor (address a, address b) {
        init = Verifierbisectinit(a);
        chal = Verifierbisectchallenge(b);
    }

    uint constant TURNS = 40;

    struct Challenge {
        uint state;
        address other;
        address owner;
        uint[2] key1;
        uint[2] key2;
        uint turn;
        uint[2] choose;
    }

    mapping (uint => Challenge) challenges;

    function initChallenge(
        uint id,
        address other,
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
        // uint[] memory params = new uint[](17);
        params[0] = key1[0];
        params[1] = key1[1];
        /*
        params[2] = key2[0];
        params[3] = key2[1];
        params[4] = step1[0];
        params[5] = step1[1];
        params[6] = step2[0];
        params[7] = step2[1];
        params[8] = step3[0];
        params[9] = step3[1];
        params[10] = hash1[0];
        params[11] = hash1[1];
        params[12] = hash2[0];
        params[13] = hash2[1];
        params[14] = hash3[0];
        params[15] = hash3[1];
        params[16] = state;*/
        {
            uint res = init.verifyProof(proof, params);
            console.log(res);
        }
        require(init.verifyProof(proof, params) == 1, "cannot verify proof");
        challenges[id].key1 = key1;
        challenges[id].key2 = key2;
        challenges[id].state = state;
        challenges[id].other = other;
        challenges[id].owner = msg.sender;
    }

    function queryChallenge(
        uint id,
        uint[2] memory choose
    ) public {
        require(challenges[id].other == msg.sender, "only other can query");
        require(challenges[id].choose[0] == 0, "already queried");
        challenges[id].choose = choose;
    }

    function replyChallenge(
        uint id,
        uint[2] memory step1,
        uint[2] memory hash1,
        uint[2] memory step2,
        uint[2] memory hash2,
        uint[2] memory step3,
        uint[2] memory hash3,
        uint state,
        bytes memory proof
    ) public {
        Challenge storage c = challenges[id];
        require(c.owner == msg.sender, "only owner can query");
        require(c.choose[0] != 0, "not queried");
        uint[] memory params = new uint[](20);
        params[0] = c.key1[0];
        params[1] = c.key1[1];
        params[2] = c.key2[0];
        params[3] = c.key2[1];
        params[4] = step1[0];
        params[5] = step1[1];
        params[6] = step2[0];
        params[7] = step2[1];
        params[8] = step3[0];
        params[9] = step3[1];
        params[10] = hash1[0];
        params[11] = hash1[1];
        params[12] = hash2[0];
        params[13] = hash2[1];
        params[14] = hash3[0];
        params[15] = hash3[1];
        params[16] = c.choose[0];
        params[17] = c.choose[1];
        params[18] = state;
        params[19] = c.state;
        require(chal.verifyProof(proof, params), "cannot verify proof");
        c.choose[0] = 0;
        c.state = state;
        c.turn++;
    }

}

