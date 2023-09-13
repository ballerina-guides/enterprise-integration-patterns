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
    string firstName;
    string lastName;
    string address1;
    string phone;
    string city;
    string country;
|};

type OrderItemRequest record {
    string name;
    int quantity;
};

type OrderItemResponse record {|
    string name;
    int quantity;
    float price;
    string currencyCode;
|};

type dhlRequest record {|
    float amount;
    string currency;
    string personName;
    string email;
    dhlAddress address;
|};

type fedexRequest record {|
    float amount;
    string currency;
    string personName;
    string email;
    string phoneNumber;
    fedexAddress address;
|};

type fedexAddress record {|
    string address1;
    string city;
    string country;
|};

type dhlAddress record {|
    string name;
    string email;
    string address1;
    string city;
    string country;
|};

type MailRequest record {|
    string toInfo;
    string fromInfo;
    string subject;
    string content;
|};

final http:Client shopify = check new ("http://BlackwellsBooks.myshopify.com.balmock.io");
final http:Client dhlExpress = check new ("http://express.api.dhl.com.balmock.io");
final http:Client fedEx = check new ("http://api.fedex.com.balmock.io");
final http:Client sendgrid = check new ("http://api.sendgrid.com.balmock.io");

service /api/v1 on new http:Listener(8080) {
    resource function post orders(OrderRequest request) returns error? {
        OrderResponse response = check shopify->/admin/api/orders\.json.post(request);
        if response.address.country == "United States" {
            check createFedexShipment(response);
        } else {
            check creeateDhlShipment(response);
        }
        check sendConfirmationMail(response.address.firstName, response.email);
    }
}

function createFedexShipment(OrderResponse response) returns error? {
    fedexRequest fedexReq = {
        amount: response.total,
        currency: response.currency,
        personName: response.address.firstName + " " + response.address.lastName,
        email: response.email,
        phoneNumber: response.address.phone,
        address: {
            address1: response.address.address1,
            city: response.address.city,
            country: response.address.country
        }
    };

    _ = check fedEx->/api/en\-us/catalog/ship/v1/shipments.post(fedexReq, targetType = json);

}

function creeateDhlShipment(OrderResponse response) returns error? {
    dhlRequest dhlReq = {
        amount: response.total,
        currency: response.currency,
        personName: response.address.firstName,
        email: response.email,
        address: {
            name: response.address.firstName + " " + response.address.lastName,
            email: response.email,
            address1: response.address.address1,
            city: response.address.city,
            country: response.address.country
        }
    };

    _ = check dhlExpress->/mydhlapi/shipments.post(dhlReq, targetType = json);
}

function sendConfirmationMail(string name, string email) returns error? {
    string body = string `<p>Hello ${name}!</p><p>Your Order has been shipped.</p>`;
    MailRequest mailReq = {
        toInfo: email,
        fromInfo: "orders@blackwell.com",
        subject: "Order Confirmation",
        content: body
    };

    _ = check sendgrid->/v3/mail/send.post(mailReq, targetType = json);
}
