import ballerina/http;

type DhlUkResponse record {|
    string url;
    record {|
        string id;
        record {|
            string statusCode;
            string status;
        |} status;
    |}[] shipments;
|};

type DhlDpiResponse record {|
    record {|
        string status;
        string statusCode;
    |}[] events;
    string publicUrl;
    string barcode;
|};

enum Country {
    UK,
    DE
}

service /shipping on new http:Listener(8080) {

    resource function get tracking(string trackingNumber, Country country) returns string|error {
        
        http:Client dhl = check new ("http://api.dhl.com.balmock.io");
        match country {
            UK => {
                DhlUkResponse response = check dhl->/parceluk/tracking/v1/shipments(trackingNumber = trackingNumber);
                return response.shipments[0].status.status;
            }
            DE => {
                DhlDpiResponse response = check dhl->/dpi/tracking/v1/trackings/[trackingNumber];
                return response.events[0].status;
            }
            _ => {
                return error("County not supported");
            }
        }
    }
}
