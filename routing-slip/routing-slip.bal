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
        float totalPoints;
        float redeemedAmount;
        float totalAmount;
    } details;
|};

type Message record {|
    *PaymentRequest;
    string storeCode;
    string[] routingSlip = [];
|};

type Points record {
    float loyaltyPoints = 0.0;
    float mobilePoints = 0.0;
};

service /api/v1 on new http:Listener(8080) {
    resource function post payments(PaymentRequest request) returns PaymentStatus|error {
        Message message = {...request, storeCode: "ST-01"};
        check lookup(message);
        Points points = {};
        if message.routingSlip.length() > 0 {
            http:Client pointHandler = check new ("http://localhost:8081/loyaltyPoints");
            json payload = {
                storeCode: message.storeCode,
                mobileNumber: message.mobileNumber,
                routingSlip: message.routingSlip
            };
            points = check pointHandler->/points.post(payload);
        }
        return checkout(message, points);
    }
}

function checkout(Message message, Points points) returns PaymentStatus {
    float totalPoints = points.loyaltyPoints + points.mobilePoints;
    return {
        status: "SUCCESS",
        details: {
            totalPoints: totalPoints,
            redeemedAmount: totalPoints * 50,
            totalAmount: message.totalAmount - (totalPoints * 50)
        }
    };
}

function lookup(Message message) returns error? {
    http:Client openLoyalty = check new ("http://openloyalty.com.balmock.io");
    anydata|error customer = openLoyalty->/api/[message.storeCode]/member/'check/get();
    if customer is anydata {
        message.routingSlip.push("CustomerLoyaltyPoints");
    }
    if check isRegisteredToPointsService(message.mobileNumber) {
        message.routingSlip.push("MobilePoints");
    }
}

function isRegisteredToPointsService(string mobileNumber) returns boolean|error {
    http:Client openLoyalty = check new ("http://mob.points.hub.com.balmock.io");
    anydata|error memberCheck = openLoyalty->/api/[mobileNumber]/member/'check/get();
    return memberCheck is error ? false : true;
}
