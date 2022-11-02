//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//prevents re-entrancy attacks
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds; //total number of items ever created
    Counters.Counter private _itemBid; //total number of items ever created
    Counters.Counter private _itemsSold; //total number of items sold

    address payable owner; //owner of the smart contract

    //people have to pay to puy their NFT on this marketplace
    // uint256 listingPrice = 0.025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller; //person selling the nft
        address payable owner; //owner of the nft
        uint256 price;
        bool sold;
    }

    struct Bids {
        uint256 itemId;
        uint256 tokenId;
        address payable bidder;
        uint256 price;
        bool accepted;
    }

    //a way to access values of the MarketItem struct above by passing an integer ID
    mapping(uint256 => MarketItem) private idMarketItem;
    mapping(uint256 => Bids) private idBidItem;

    //log message (when Item is sold)
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    event BidsCreated(
        uint256 itemId,
        uint256 tokenId,
        address bidder,
        uint256 price,
        bool accepted
    );

    /// @notice function to create market item
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be above zero");
        require(
            IERC721(nftContract).ownerOf(tokenId) == address(this),
            "You are not the owner of the Nft"
        );

        _itemIds.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _itemIds.current();

        idMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender), //address of the seller putting the nft up for sale
            payable(address(0)), //no owner yet (set owner to empty address)
            price,
            false
        );

        //transfer ownership of the nft to the contract itself

        // IERC721(nftContract).setApprovalForAll(address(this), true);
        // IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        //log this transaction
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    /// @notice function to create market item
    function createBidItem(uint256 tokenId, uint256 price)
        public
        payable
        nonReentrant
    {
        require(price > 0, "Price must be above zero");
        require(price == msg.value, "Please send the accurate Price");

        _itemBid.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _itemBid.current();

        idBidItem[itemId] = Bids(
            itemId,
            tokenId,
            payable(msg.sender), //address of the seller putting the nft up for sale
            price,
            false
        );

        //log this transaction
        emit BidsCreated(itemId, tokenId, msg.sender, price, false);
    }

    /// @notice function to create a sale
    function acceptBid(
        uint256 itemId,
        uint256 tokenId,
        uint256 nftItem,
        address nftContract
    ) public nonReentrant {
        // uint256 price = idMarketItem[itemId].price;
        // uint256 tokenId = idMarketItem[itemId].tokenId;

        require(
            msg.sender == idMarketItem[nftItem].seller,
            "Only the Seller of this NFT can Accept a Bid"
        );

        uint256 price = idBidItem[itemId].price;

        //pay the seller the amount
        // payable(idMarketItem[nftItem].seller).transfer(price);
        payable(0xf8d9BFA766b93F3CE6e0048a0ea4aCFE0701688f).transfer(
            (price * 3) / 100
        );
        idMarketItem[itemId].seller.transfer((price * 87) / 100);

        //transfer ownership of the nft from the contract itself to the buyer
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        idMarketItem[nftItem].owner = payable(msg.sender); //mark buyer as new owner
        idMarketItem[nftItem].sold = true; //mark that it has been sold
        idBidItem[itemId].accepted = true;
        _itemsSold.increment(); //increment the total number of Items sold by 1
        // payable(owner).transfer(price * 3 / 100);

        uint256 Id = _itemBid.current();

        for (uint256 i = 0; i < Id; i++) {
            if (idBidItem[i + 1].tokenId == tokenId) {
                if (idBidItem[i + 1].accepted == false) {
                    payable(idBidItem[i + 1].bidder).transfer(
                        idBidItem[i + 1].price
                    );
                    delete idBidItem[i + 1];
                }
            }
        }
    }

    function transferNFT(
        address nftContract,
        uint256 tokenId,
        address user
    ) public {
        require(
            msg.sender == owner,
            "Only Onwer of Smart Contract can do this"
        );
        IERC721(nftContract).transferFrom(address(this), user, tokenId);
    }

    function takeOffMarketplace(uint256 tokenId, address nftContract)
        public
        nonReentrant
    {
        uint256 totalItemCount = _itemIds.current();

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].tokenId == tokenId) {
                IERC721(nftContract).transferFrom(
                    address(this),
                    msg.sender,
                    tokenId
                );
                delete idMarketItem[i + 1];
            }
        }
    }

    /// @notice function to create a sale
    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idMarketItem[itemId].price;
        uint256 tokenId = idMarketItem[itemId].tokenId;

        // int percent = 3 / 100;

        require(
            msg.value == price,
            "Please submit the asking price in order to complete purchase"
        );

        //pay the seller the amount
        payable(0xf8d9BFA766b93F3CE6e0048a0ea4aCFE0701688f).transfer(
            (msg.value * 3) / 100
        );
        idMarketItem[itemId].seller.transfer((msg.value * 87) / 100);

        //transfer ownership of the nft from the contract itself to the buyer
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        idMarketItem[itemId].owner = payable(msg.sender); //mark buyer as new owner
        idMarketItem[itemId].sold = true; //mark that it has been sold
        _itemsSold.increment(); //increment the total number of Items sold by 1
    }

    /// @notice total number of items unsold on our platform
    function fetchSoldItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current(); //total number of items ever created
        //total number of items that are unsold = total items ever created - total items ever sold
        uint256 soldItemCount = _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](soldItemCount);

        //loop through all items ever created
        for (uint256 i = 0; i < itemCount; i++) {
            //get only unsold item
            //check if the item has not been sold
            //by checking if the owner field is empty
            if (idMarketItem[i + 1].owner != address(0)) {
                //yes, this item has never been sold
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items; //return array of all unsold items
    }

    /// @notice total number of items unsold on our platform
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current(); //total number of items ever created
        //total number of items that are unsold = total items ever created - total items ever sold
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        //loop through all items ever created
        for (uint256 i = 0; i < itemCount; i++) {
            //get only unsold item
            //check if the item has not been sold
            //by checking if the owner field is empty
            if (idMarketItem[i + 1].owner == address(0)) {
                //yes, this item has never been sold
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items; //return array of all unsold items
    }

    /// @notice fetch list of NFTS owned/bought by this user
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        //get total number of items ever created
        uint256 totalItemCount = _itemIds.current();

        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            //get only the items that this user has bought/is the owner
            if (idMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1; //total length
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /// @notice fetch list of NFTS owned/bought by this user
    function fetchBidItem(uint256 id) public view returns (Bids[] memory) {
        //get total number of items ever created
        uint256 totalItemCount = _itemBid.current();

        uint256 itemCount;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idBidItem[i + 1].tokenId == id) {
                itemCount += 1;
            }
        }

        Bids[] memory items = new Bids[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idBidItem[i + 1].tokenId == id) {
                Bids storage bid = idBidItem[i + 1];
                items[currentIndex] = bid;
                currentIndex += 1;
            }
        }
        return items;
    }

    /// @notice fetch list of NFTS owned/bought by this user
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        //get total number of items ever created
        uint256 totalItemCount = _itemIds.current();

        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            //get only the items that this user has bought/is the owner
            if (idMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1; //total length
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}
