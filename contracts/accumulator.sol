// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

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
