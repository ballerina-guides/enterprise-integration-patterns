import ballerina/http;
import ballerina/io;

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

final map<OrderStatus> orderStatuses = {};

service /api/v1 on new http:Listener(8080) {

    resource function put manage\-orders/[string orderId](OrderDetail orderDetail) returns
        http:STATUS_NO_CONTENT|http:STATUS_CREATED {
            io:println(orderStatuses);
        OrderStatus? orderStatus = orderStatuses[orderId];
        if orderStatus == orderDetail.status {
            return http:STATUS_NO_CONTENT;
        } else {
            orderStatuses[orderId] = orderDetail.status;
            return http:STATUS_CREATED;
        }
    }
}
