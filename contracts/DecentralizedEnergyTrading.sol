// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Energy Trading Platform
 * @dev Smart contract for peer-to-peer energy trading
 */
contract EnergyTrading {
    address public owner;
    
    struct EnergyOffer {
        address seller;
        uint256 amount; // in kWh
        uint256 price; // price per kWh in wei
        uint256 timestamp;
        bool isActive;
    }
    
    struct EnergyTransaction {
        address buyer;
        address seller;
        uint256 amount;
        uint256 price;
        uint256 timestamp;
    }
    
    mapping(uint256 => EnergyOffer) public energyOffers;
    uint256 public offerCount;
    
    mapping(uint256 => EnergyTransaction) public transactions;
    uint256 public transactionCount;
    
    event NewOfferCreated(uint256 offerId, address seller, uint256 amount, uint256 price);
    event EnergyPurchased(uint256 transactionId, address buyer, address seller, uint256 amount, uint256 price);
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new energy offer
     * @param _amount Amount of energy in kWh
     * @param _price Price per kWh in wei
     */
    function createEnergyOffer(uint256 _amount, uint256 _price) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(_price > 0, "Price must be greater than 0");
        
        offerCount++;
        energyOffers[offerCount] = EnergyOffer(
            msg.sender,
            _amount,
            _price,
            block.timestamp,
            true
        );
        
        emit NewOfferCreated(offerCount, msg.sender, _amount, _price);
    }
    
    /**
     * @dev Purchase energy from an existing offer
     * @param _offerId ID of the energy offer
     * @param _amount Amount of energy to purchase in kWh
     */
    function purchaseEnergy(uint256 _offerId, uint256 _amount) public payable {
        EnergyOffer storage offer = energyOffers[_offerId];
        
        require(offer.isActive, "Offer is not active");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= offer.amount, "Not enough energy available");
        require(msg.value >= _amount * offer.price, "Insufficient payment");
        
        // Transfer payment to seller
        payable(offer.seller).transfer(_amount * offer.price);
        
        // Update offer
        offer.amount -= _amount;
        if (offer.amount == 0) {
            offer.isActive = false;
        }
        
        // Record transaction
        transactionCount++;
        transactions[transactionCount] = EnergyTransaction(
            msg.sender,
            offer.seller,
            _amount,
            offer.price,
            block.timestamp
        );
        
        emit EnergyPurchased(transactionCount, msg.sender, offer.seller, _amount, offer.price);
    }
    
    /**
     * @dev Cancel an energy offer
     * @param _offerId ID of the energy offer to cancel
     */
    function cancelOffer(uint256 _offerId) public {
        EnergyOffer storage offer = energyOffers[_offerId];
        
        require(msg.sender == offer.seller, "Only seller can cancel offer");
        require(offer.isActive, "Offer is not active");
        
        offer.isActive = false;
    }
}
