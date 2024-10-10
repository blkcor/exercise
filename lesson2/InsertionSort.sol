// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InsertionSort {
  function insertionSort(uint[] memory arr) public pure returns(uint[] memory){
    uint n = arr.length;
    for(uint i = 1; i < n ;i ++){
        uint tmp = arr[i];
        int j = int(i-1);
        while(j >=0 && arr[uint(j)] > tmp){
            arr[uint(j+1)] = arr[uint(j)];
            j--;
        }
        arr[uint(j+1)] = tmp;
    }
    return arr;
  } 
  // 测试函数
    function testSort() public pure returns (uint[] memory) {
        uint[] memory arr = new uint[](6);
        arr[0] = 64;
        arr[1] = 34;
        arr[2] = 25;
        arr[3] = 12;
        arr[4] = 22;
        arr[5] = 11;
        
        return insertionSort(arr);
    }
}
