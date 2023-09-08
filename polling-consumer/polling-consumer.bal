import ballerina/http;
import ballerina/lang.runtime;

enum Status {
    CREATED,
    CAPTURED,
    DENIED,
    PARTIALLY_CAPTURED,
    VOIDED,
    PENDING
}

type PaypalResponse record {
    string id;
    Status status;
    record {|
        string value;
        string currency_code;
    |} amount;
    record {|
        string email_address;
        string merchant_id;
    |} payee;
};

const PAYMENT_ID = "0VF41793826897254";

final http:Client paypalClient = check new ("http://api-m.paypal.com.balmock.io");

service /api/v1 on new http:Listener(8080) {
    resource function get payment() returns string|error? {
        while true {
            PaypalResponse response = check paypalClient->/v2/payments/authorizations/[PAYMENT_ID]();
            if response.status == CREATED || response.status == PARTIALLY_CAPTURED || response.status == PENDING {
                runtime:sleep(5000);
            } else {
                return response.status;
            }
        }
    }
}
