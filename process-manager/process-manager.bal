import ballerina/http;

type OrderRequest record {|
    string email;
    Address address;
    OrderItemRequest[] orderItems;
|};

type OrderResponse record {|
    string email;
    string currency;
    float total;
    Address address;
    OrderItemResponse[] orderItems;
|};

type Address record {|
    string fullName;
    string address1;
    string phone;
    string city;
    string country;
|};

type OrderItemRequest record {
    string itemName;
    int quantity;
};

type OrderItemResponse record {|
    string itemName;
    int quantity;
    float price;
    string currencyCode;
|};

type ShipmentRequest record {|
    float amount;
    string currency;
    string personName;
    string email;
    DHLAddress|FedexAddress address;
|};

type FedexAddress record {|
    string address1;
    string city;
    string country;
    string phoneNumber;
|};

type DHLAddress record {|
    string name;
    *FedexAddress;
|};

final http:Client shopify = check new ("http://BlackwellsBooks.myshopify.com.balmock.io");
final http:Client dhlExpress = check new ("http://express.api.dhl.com.balmock.io");
final http:Client fedEx = check new ("http://api.fedex.com.balmock.io");
final http:Client sendgrid = check new ("http://api.sendgrid.com.balmock.io");

service /api/v1 on new http:Listener(8080) {
    resource function post orders(OrderRequest orderReq) returns error? {
        OrderResponse response = check shopify->/admin/api/orders\.json.post(orderReq);
        if response.address.country == "United States" {
            check createFedexShipment(response);
        } else {
            check creeateDhlShipment(response);
        }
        var _ = start sendConfirmationMail(response.address.fullName, response.email);
    }
}

function createFedexShipment(OrderResponse response) returns error? {
    ShipmentRequest fedexReq = {
        amount: response.total,
        currency: response.currency,
        personName: response.address.fullName,
        email: response.email,
        address: {
            address1: response.address.address1,
            city: response.address.city,
            country: response.address.country,
            phoneNumber: response.address.phone
        }
    };

    _ = check fedEx->/api/en\-us/catalog/ship/v1/shipments.post(fedexReq, targetType = json);

}

function creeateDhlShipment(OrderResponse response) returns error? {
    ShipmentRequest dhlReq = {
        amount: response.total,
        currency: response.currency,
        personName: response.address.fullName,
        email: response.email,
        address: {
            name: response.address.fullName,
            address1: response.address.address1,
            city: response.address.city,
            country: response.address.country,
            phoneNumber: response.address.phone
        }
    };

    _ = check dhlExpress->/mydhlapi/shipments.post(dhlReq, targetType = json);
}

function sendConfirmationMail(string name, string email) returns error? {
    string body = string `<p>Hello ${name}!</p><p>Your Order has been shipped.</p>`;
    var mailReq = {
        toInfo: email,
        fromInfo: "orders@blackwell.com",
        subject: "Order Confirmation",
        content: body
    };

    _ = check sendgrid->/v3/mail/send.post(mailReq, targetType = json);
}
