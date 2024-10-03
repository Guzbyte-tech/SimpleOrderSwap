// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IERC20.sol";

contract SimpleOrderSwap {
    enum OrderType {
        OrderCreated,
        OrderFulfiled
    }

    enum OrderStatus {
        Open,
        Closed,
        Cancelled
    }

    uint public totalOrders;

    struct Order {
        uint orderId;
        address depositor;
        address depositorToken;
        uint depositedAmount;
        address requestedToken;
        uint requestAmount;
        address fulfilledBy;
        OrderType _orderType;
        OrderStatus status;
    }

    mapping(uint => Order) OrderIdToOrders; //Order => Order

    constructor() {}

    function createOrder(
        uint _depositedAmount,
        address _depositorToken,
        uint _requestedAmount,
        address _requestedToken
    ) external {
        require(msg.sender != address(0), "Address zero detected.");
        require(_depositorToken != address(0), "Address zero detected.");
        require(_requestedToken != address(0), "Address zero detected.");
        require(_depositedAmount > 0, "Invalid Deposit Amount");
        require(_requestedAmount > 0, "Invalid Requested Amount");

        require(
            IERC20(_depositorToken).transferFrom(
                msg.sender,
                address(this),
                _depositedAmount
            ),
            "Transfer Failed"
        );

        createTransaction(
            _depositedAmount,
            _depositorToken,
            _requestedAmount,
            _requestedToken,
            OrderType.OrderCreated,
            OrderStatus.Open
        );
        //Emit an Event OrderCreatedSuccessfully.
    }

    function fullfilOrder(uint _orderId) external {
        require(OrderIdToOrders[_orderId].orderId > 0, "Invalid Order Id");
        require(
            OrderIdToOrders[_orderId].status == OrderStatus.Open,
            "Order Already Fulfiled"
        );
        require(
            OrderIdToOrders[_orderId].status == OrderStatus.Cancelled,
            "Order Cancelled"
        );

        //send requested token to depositor.
        require(
            IERC20(OrderIdToOrders[_orderId].requestedToken).transferFrom(
                msg.sender,
                OrderIdToOrders[_orderId].depositor,
                OrderIdToOrders[_orderId].requestAmount
            ),
            "Transfer requested token failed."
        );

        require(
            IERC20(OrderIdToOrders[_orderId].depositorToken).transfer(
                msg.sender,
                OrderIdToOrders[_orderId].depositedAmount
            ),
            "Transfer to fulfiller failed"
        );

        OrderIdToOrders[_orderId].fulfilledBy = msg.sender;
        OrderIdToOrders[_orderId].status = OrderStatus.Closed;
        //Create Order History For The Fulfiller.
        createTransaction(
            OrderIdToOrders[_orderId].depositedAmount,
            OrderIdToOrders[_orderId].depositorToken,
            OrderIdToOrders[_orderId].requestAmount,
            OrderIdToOrders[_orderId].requestedToken,
            OrderType.OrderFulfiled,
            OrderStatus.Closed
        );
    }

    function cancelOrder(uint _orderId) external {
        require(OrderIdToOrders[_orderId].orderId > 0, "Invalid Order Id");
        require(
            OrderIdToOrders[_orderId].status == OrderStatus.Open,
            "Order Already Fulfiled"
        );
        require(
            OrderIdToOrders[_orderId].status == OrderStatus.Cancelled,
            "Order Cancelled"
        );
        //Check if depositor is the msg.sender
        require(
            OrderIdToOrders[_orderId].depositor == msg.sender,
            "Not Order Owner."
        );
        OrderIdToOrders[_orderId].status = OrderStatus.Cancelled;
    }

    function createTransaction(
        uint _depositedAmount,
        address _depositorToken,
        uint _requestedAmount,
        address _requestedToken,
        OrderType _type,
        OrderStatus _status
    ) private {
        uint orderId = totalOrders + 1;
        Order storage ord = OrderIdToOrders[orderId];
        ord.orderId = orderId;
        ord.depositor = msg.sender;
        ord.depositorToken = _depositorToken;
        ord.depositedAmount = _depositedAmount;
        ord.requestedToken = _requestedToken;
        ord.requestAmount = _requestedAmount;
        ord._orderType = _type;
        ord.status = _status;
        totalOrders = orderId;
    }
}
