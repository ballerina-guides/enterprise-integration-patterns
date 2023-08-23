import ballerina/http;

type PaymentRequest record {|
    string mobileNumber;
    string customerName;
    float totalAmount;
    record {}[] items;
|};

type PaymentStatus record {|
    string status;
    record {
        float totalPoints = 0.0;
        float redeemedAmount = 0.0;
        float totalAmount = 0.0;
    } details = {};
|};

type Message record {|
    *PaymentRequest;
    string storeCode;
    Process[] routingSlip;
    PaymentStatus paymentStatus;
|};

service /api/v1 on new http:Listener(8080) {
    resource function post payments(PaymentRequest paymentRequest) returns PaymentStatus|error {
        Message message = {...paymentRequest, storeCode: "ST-01", routingSlip: [], paymentStatus: {status: "PENDING"}};
        check attachRoutingSlip(message);
        check message.routingSlip[0].process(message);
        return message.paymentStatus;
    }
}

function attachRoutingSlip(Message message) returns error? {
    Process[] processes = [];
    http:Client openLoyalty = check new ("http://openloyalty.com.v1.balmock.io");
    anydata|error customer = openLoyalty->/api/[message.storeCode]/member/'check/get();
    if customer is error {
        processes.push(new addNewCustomer());
    } else {
        processes.push(new redeemLoyaltyPoints());
    }
    if check isRegisteredToPointsService(message.mobileNumber) {
        processes.push(new redeemMobilePoints());
    }
    processes.push(new processRedeemedPoints());
    processes.push(new checkout());
    message.routingSlip = processes;
}

class Process {
    function process(Message message) returns error? {
    };
}

class redeemLoyaltyPoints {
    *Process;
    function process(Message message) returns error? {
        http:Client openLoyalty = check new ("http://openloyalty.com.v2.balmock.io");
        record {float loyaltyPoints;} points = check openLoyalty->/api/[message.storeCode]/redemption/[message.mobileNumber].get();
        message.paymentStatus.details = {totalPoints: points.loyaltyPoints};
        check route(message);
    }
}

class redeemMobilePoints {
    *Process;
    function process(Message message) returns error? {
        http:Client openLoyalty = check new ("http://openloyalty.com.v3.balmock.io");
        record {float mobilePoints;} points = check openLoyalty->/api/[message.mobileNumber]/redemption.get();
        message.paymentStatus.details.totalPoints += points.mobilePoints;
        check route(message);
    }
}

class processRedeemedPoints {
    *Process;
    function process(Message message) returns error? {
        message.paymentStatus.details.redeemedAmount = message.paymentStatus.details.totalPoints * 50;
        http:Client openLoyalty = check new ("http://openloyalty.com.v4.balmock.io");
        json payload = {transfer: {receiver: message.mobileNumber, points: message.totalAmount / 200}};
        anydata _ = check openLoyalty->/api/[message.storeCode]/member/points.post(payload);
        check route(message);
    }
}

class addNewCustomer {
    *Process;
    function process(Message message) returns error? {
        http:Client openLoyalty = check new ("http://openloyalty.com.v5.balmock.io");
        json payload = {id: message.mobileNumber, name: message.customerName};
        anydata _ = check openLoyalty->/api/[message.storeCode]/member/register.post(payload);
        check route(message);
    }
}

class checkout {
    *Process;
    function process(Message message) returns error? {
        message.paymentStatus.details.totalAmount = message.totalAmount - message.paymentStatus.details.redeemedAmount;
        message.paymentStatus.status = "SUCCESS";
        check route(message);
    }
}

function route(Message message) returns error? {
    if message.routingSlip.length() > 1 {
        _ = message.routingSlip.remove(0);
        return message.routingSlip[0].process(message);
    }
    return;
}

function isRegisteredToPointsService(string mobileNumber) returns boolean|error {
    http:Client openLoyalty = check new ("http://openloyalty.com.balmock.io");
    anydata|error memberCheck = openLoyalty->/api/[mobileNumber]/member/'check/get();
    return memberCheck is error ? false : true;
}
