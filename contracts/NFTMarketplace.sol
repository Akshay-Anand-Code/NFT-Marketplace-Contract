//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    Counter.Counter private _tokenIds;    // number of tokenIds
    Counters.Counter private _itemsSold; //number of nfts sold
    
    uint256 listingPrice = 0.0015 ether;
    //price to put up an nft for sale on the marketplace

    address payable owner;

    mapping(uint256 => MarketItem) private idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    modifier onlyOwner() {
        require(
            msg.sender == owner, "only owner of the marketplace can change the listing price"
        );
        _;
    }

    constructor () ERC721("My Token", "MYT" ) {
        owner = payable(msg.sender);
    }
    
    
    function updateListingPrice(uint256 _listingPrice)
     public
     payable
     onlyOwner
    {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }
    

    /*
    createToken(token URI, price)
     
     >increment the number of token by calling increment function on _tokenIds.increment()
     >get current token's id by _tokenId.increment() and store it in a local variable
     >call _mint() function, pass msg.sender and current token id
     >call _setTokenURI with current token's id and tokenURI which is a url to the nft
     >call createMarketItem with current token id and price 
     >return current token's id

    */

    function createToken(string memory tokenURI, uint256 price)
    public 
    payable
    returns(uint256)
    {
        //_tokenIds start from 0 and incremented to 1 when first item is created.
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
       // at first item newTokenId value will be 1
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
 
        createMarketItem(newTokenId, price);
       //function will set mapping 1 the token and so on as new items get created.
        return newTokenId;
    }
    
   

    function createMarketItem(uint256 tokenId, uint256 price) private {

        require(price > 0, "Price must be atleast 1");
        require(msg.value == listingPrice, "Price must be equal to listing price");
         
         idMarketItem[tokenId] = MarketItem (
            tokenId,
            payable(msg.sender),
            payable(address(this)), //nft marketplace contract
            price,
            false
         );

         _transfer(msg.sender, address(this), tokenId); //transferring the nft from seller to contract
         emit idMarketItemCreated(tokenId, msg.sender, address(this), price, false);

    }

    function reSellToken(uint256 tokenId, uint256 price) public payable {
        require(idMarketItem[tokenId].owner == msg.sender, "only item owner can perform this action");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);

    }

    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = idMarketItem[tokenId].price;

        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));

        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);

        //transferring listingPrice amount to the nft marketplace contract owner
        payable(owner).transfer(listingPrice);
        //trasnferring the price amount to the seller of the nft
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
        
    }

    function fetchMarketItem() public view returns(MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        //let's say itemCount is 10
        uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            // 0 to 9 will be 10 iterations, and i = 10 won't iterate since i < itemCount
            if (idMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                

                //with item's tokenId, the MarketItem will will be taken in currentItemand filled into the array of unsold items
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;

            }

        }
        
        return items;

    }

    function fetchMyNFT() public view returns(MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if(idMarketItem[i+1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if(idMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;

            }
        }
        return items;

    }

    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if(idMarketItem[i+1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if(idMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;

            }
        }
        return items;
    }


}