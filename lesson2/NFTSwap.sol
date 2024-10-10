// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTSwap {
    struct Order {
        address seller;
        uint256 price;
        bool active;
    }

    // Mapping from tokenId to Order
    mapping(uint256 => Order) public orders;

    // The ERC721 contract address
    IERC721 public nftContract;

    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Revoked(uint256 indexed tokenId);
    event Updated(uint256 indexed tokenId, uint256 newPrice);
    event Purchased(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);

    constructor(address _nftContract) {
        nftContract = IERC721(_nftContract);
    }

    // List an NFT for sale
    function list(uint256 tokenId, uint256 price) external {
        require(nftContract.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(orders[tokenId].active == false, "Order already exists");

        orders[tokenId] = Order(msg.sender, price, true);
        emit Listed(tokenId, msg.sender, price);
    }

    // Revoke an existing order
    function revoke(uint256 tokenId) external {
        Order storage order = orders[tokenId];
        require(order.active == true, "No active order to revoke");
        require(order.seller == msg.sender, "You are not the seller");

        delete orders[tokenId];
        emit Revoked(tokenId);
    }

    // Update the price of an existing order
    function update(uint256 tokenId, uint256 newPrice) external {
        Order storage order = orders[tokenId];
        require(order.active == true, "No active order to update");
        require(order.seller == msg.sender, "You are not the seller");

        order.price = newPrice;
        emit Updated(tokenId, newPrice);
    }

    // Purchase an NFT
    function purchase(uint256 tokenId) external payable {
        Order storage order = orders[tokenId];
        require(order.active == true, "No active order to purchase");
        require(msg.value == order.price, "Incorrect price sent");

        address seller = order.seller;

        // Transfer the NFT from seller to buyer
        nftContract.transferFrom(seller, msg.sender, tokenId);

        // Transfer the funds to the seller
        payable(seller).transfer(msg.value);

        // Remove the order after purchase
        delete orders[tokenId];

        emit Purchased(tokenId, msg.sender, seller, order.price);
    }
}
