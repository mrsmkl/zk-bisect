// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import 'hardhat/console.sol';

contract Accumulator {

    mapping (uint => mapping (uint => bytes32)) public levels;
    uint public num;

    function left(uint idx) internal pure returns (uint) {
        return idx % 2 == 0 ? idx : idx-1;
    } 

    function right(uint idx) internal pure returns (uint) {
        return idx % 2 == 0 ? idx+1 : idx;
    } 

    // Returns the root of the tree
    // Will make a lot of storage modifications...
    function accumulate(bytes32 elem) public returns (bytes32) {
        uint idx = num;
        levels[0][num] = elem;
        num++;
        for (uint level = 0; level < 31; level++) {
            bytes32 h = keccak256(abi.encodePacked(levels[level][left(idx)], levels[level][right(idx)]));
            idx = idx / 2;
            levels[level+1][idx] = h;
        }
        return levels[31][0];
    }

    function init() public {
    }

    // Construct full trees
    // Should need much less storage modifications
    struct Node {
        uint depth;
        bytes32 root;
    }

    mapping (uint => Node) public nodes;
    uint public pointer;

    function add(bytes32 elem) public returns (bytes32) {
        if (pointer > 0 && nodes[pointer-1].depth == 1) {
            Node storage leftN = nodes[pointer - 1];
            leftN.depth++;
            leftN.root = keccak256(abi.encodePacked(leftN.root, elem));
        } else {
            nodes[pointer] = Node(1, elem);
            pointer++;
        }
        while (pointer > 1) {
            Node storage leftN = nodes[pointer - 2];
            Node storage rightN = nodes[pointer - 1];
            if (leftN.depth != rightN.depth) break;
            leftN.depth++;
            leftN.root = keccak256(abi.encodePacked(leftN.root, rightN.root));
            pointer--;
        }
        return getRoot(0, 32);
    }

    function merge() internal {
        Node storage leftN = nodes[pointer - 2];
        Node storage rightN = nodes[pointer - 1];
        require(leftN.depth == rightN.depth, "depths do not match");
        leftN.depth++;
        leftN.root = keccak256(abi.encodePacked(leftN.root, rightN.root));
        pointer--;
    }

    // len has to be power of two
    function getRoot(uint start, uint len) internal returns (bytes32) {
        if (len == 1) {
            console.log(start);
            return nodes[start].root;
        }
        return keccak256(abi.encodePacked(getRoot(start, len/2), getRoot(start+len/2, len/2)));
    }

/*
    function getRoot(uint start, uint len) internal returns (bytes32) {
        unchecked {
            bytes32 acc = nodes[start].root;
            for (uint i = 0; i < len; i++) {
                acc = keccak256(abi.encodePacked(nodes[start+i].root, acc));
            }
        return acc;
        }
    }
*/

    uint buflen;
    bytes32 buffer;
    bytes32 root;

    function addBuffer(bytes32 elem) public returns (bytes32) {
        buffer = keccak256(abi.encodePacked(buffer, elem));
        buflen++;
        if (buflen == 10) {
            root = add(buffer);
            buffer = 0;
            buflen = 0;
        }
        return keccak256(abi.encodePacked(buffer, root));
    }

}
