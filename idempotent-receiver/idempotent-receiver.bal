import ballerina/http;

type OrderDetail record {
    string orderId;
    OrderStatus status;
};

enum OrderStatus {
    CREATED,
    SHIPPED,
    COMPLETED,
    CANCELLED
};

map<OrderStatus> orderStatuses = {};

service /api/v1 on new http:Listener(8080) {

    resource function put manage\-orders/[string orderId](OrderDetail orderDetail) returns
        http:STATUS_ACCEPTED|http:STATUS_ALREADY_REPORTED {
        OrderStatus? orderStatus = orderStatuses[orderId];
        if orderStatus == orderDetail.status {
            return http:STATUS_ALREADY_REPORTED;
        } else {
            orderStatuses[orderId] = orderDetail.status;
            return http:STATUS_ACCEPTED;
        }
    }
}
