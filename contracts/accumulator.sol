// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Accumulator {

    bytes32[][] public levels;

    function left(bytes32[] storage arr, uint idx) internal view returns (bytes32) {
        uint i = idx % 2 == 0 ? idx : idx-1;
        if (arr.length <= i) {
            return 0;
        } else {
            return arr[i];
        }
    } 

    function right(bytes32[] storage arr, uint idx) internal view returns (bytes32) {
        uint i = idx % 2 == 0 ? idx+1 : idx;
        if (arr.length <= i) {
            return 0;
        } else {
            return arr[i];
        }
    } 

    // Returns the root of the tree
    // Will make a lot of storage modifications...
    function accumulate(bytes32 elem) public returns (bytes32) {
        uint idx = levels[0].length;
        levels[0].push(elem);
        for (uint level = 0; level < levels.length-1; level++) {
            bytes32 h = keccak256(abi.encodePacked(left(levels[level], idx), right(levels[level], idx)));
            idx = idx / 2;
            levels[level+1][idx] = h;
        }
        return levels[levels.length-1][0];
    }

    function init() public {
        for (uint i = 0; i < 32; i++) {
            levels.push({});
        }
        // levels.length = 32;
    }

    // Construct full trees
    // Should need much less storage modifications
    struct Node {
        uint depth;
        bytes32 root;
    }

    Node[32] public nodes;
    uint public pointer;

    function add(bytes32 elem) internal {
        nodes[pointer] = Node(1, elem);
        pointer++;
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
            return nodes[start].root;
        }
        return keccak256(abi.encodePacked(getRoot(start, len/2), getRoot(start+len/2, len/2)));
    }

}
