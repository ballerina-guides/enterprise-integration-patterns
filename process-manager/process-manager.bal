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

type ShippingRequest record {|
    DeclaredValue declaredValue;
    Shipper shipper;
|};

type Shipper record {|
    ShipperAddress address;
    ShipperContact contact;
|};

type DeclaredValue record {|
    float amount;
    string currency;
|};

type ShipperAddress record {|
    string address1;
    string city;
    string country;
|};

type ShipperContact record {|
    string personName;
    string email;
    string phoneNumber;
|};

type MailRequest record {|
    MailInfo toInfo;
    MailInfo fromInfo;
    string subject;
    MailContent content;
|};

type MailInfo record {|
    string email;
    string name;
|};

type MailContent record {|
    string contentType;
    string value;
|};

final http:Client shopify = check new ("http://BlackwellsBooks.myshopify.com.balmock.io");
final http:Client dhlExpress = check new ("http://express.api.dhl.com.balmock.io");
final http:Client fedEx = check new ("http://api.fedex.com.balmock.io");
final http:Client sendgrid = check new ("http://api.sendgrid.com.balmock.io");

service /api/v1 on new http:Listener(8080) {
    resource function post process\-manager(OrderRequest request) returns error? {
        OrderResponse response = check shopify->/admin/api/orders\.json.post(request);
        check createShipment(response);
        check sendConfirmationMail(response.address.firstName, response.email);
    }
}

function createShipment(OrderResponse orderDetails) returns error? {
    ShippingRequest shippingReq = {
        declaredValue: {
            amount: orderDetails.total,
            currency: orderDetails.currency
        },
        shipper: {
            address: {
                address1: orderDetails.address.address1,
                city: orderDetails.address.city,
                country: orderDetails.address.country
            },
            contact: {
                personName: orderDetails.address.firstName + " " + orderDetails.address.lastName,
                email: orderDetails.email,
                phoneNumber: orderDetails.address.phone
            }
        }
    };
    if orderDetails.address.country == "United States" { //Domestic delivery
        _ = check fedEx->/api/en\-us/catalog/ship/v1/shipments.post(shippingReq, targetType = json);
    } else { //International delivery
        _ = check dhlExpress->/mydhlapi/shipments.post(shippingReq, targetType = json);
    }
}

function sendConfirmationMail(string name, string email) returns error? {
    string body = string `<p>Hello ${name}!</p><p>Your Order has been shipped.</p>`;
    MailRequest mailReq = {
        toInfo: {
            email: email,
            name: name
        },
        fromInfo: {
            email: "orders@blackwell.com",
            name: "Blackwell's Books"
        },
        subject: "Order Confirmation",
        content: {
            contentType: "text/html",
            value: body
        }
    };
    _ = check sendgrid->/v3/mail/send.post(mailReq, targetType = json);
}
