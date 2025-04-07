// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AutoBilling {
    address public owner;

    struct Subscription {
        address subscriber;
        address payable provider;
        uint256 amount;
        uint256 frequency; // in seconds
        uint256 nextPaymentTime;
        bool active;
    }

    mapping(address => Subscription[]) public subscriptions;

    event Subscribed(address indexed subscriber, address indexed provider, uint256 amount, uint256 frequency);
    event PaymentProcessed(address indexed subscriber, address indexed provider, uint256 amount);
    event SubscriptionCancelled(address indexed subscriber, uint index);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function subscribe(address payable _provider, uint256 _amount, uint256 _frequency) external payable {
        require(msg.value >= _amount, "Insufficient initial payment.");

        subscriptions[msg.sender].push(Subscription({
            subscriber: msg.sender,
            provider: _provider,
            amount: _amount,
            frequency: _frequency,
            nextPaymentTime: block.timestamp + _frequency,
            active: true
        }));

        emit Subscribed(msg.sender, _provider, _amount, _frequency);
        _provider.transfer(_amount);
        emit PaymentProcessed(msg.sender, _provider, _amount);
    }

    function processPayment(address _subscriber, uint index) external {
        Subscription storage sub = subscriptions[_subscriber][index];

        require(sub.active, "Subscription inactive.");
        require(block.timestamp >= sub.nextPaymentTime, "Too early for next payment.");
        require(_subscriber.balance >= sub.amount, "Subscriber has insufficient funds.");

        sub.provider.transfer(sub.amount);
        sub.nextPaymentTime = block.timestamp + sub.frequency;

        emit PaymentProcessed(_subscriber, sub.provider, sub.amount);
    }

    function cancelSubscription(uint index) external {
        require(index < subscriptions[msg.sender].length, "Invalid subscription index.");
        Subscription storage sub = subscriptions[msg.sender][index];
        require(sub.active, "Already inactive.");

        sub.active = false;
        emit SubscriptionCancelled(msg.sender, index);
    }

    function getSubscriptions(address _subscriber) external view returns (Subscription[] memory) {
        return subscriptions[_subscriber];
    }
}

