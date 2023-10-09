const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('NFTMarketplace', function () {
  let owner;
  let nftMarketplace;

  before(async function () {
    [owner] = await ethers.getSigners();

    const NFTMarketplace = await ethers.getContractFactory('NFTMarketplace');
    nftMarketplace = await NFTMarketplace.deploy();
    await nftMarketplace.deployed();
  });

  describe('createToken', function () {
    it('should create a new NFT with a given token URI and price', async function () {
      const tokenURI = 'https://example.com/nft-uri';
      const price = ethers.utils.parseEther('0.01'); // 0.01 ETH

      // Create a new NFT
      await nftMarketplace.createToken(tokenURI, price);

      // Check if the NFT exists and has the correct owner
      const ownerOfToken = await nftMarketplace.ownerOf(1); // Assuming tokenId starts from 1
      expect(ownerOfToken).to.equal(owner.address);

      // Check if the NFT has the correct token URI
      const tokenURIStored = await nftMarketplace.tokenURI(1); // Assuming tokenId starts from 1
      expect(tokenURIStored).to.equal(tokenURI);
    });
  });

  // Add more test cases for other functions here...

});
