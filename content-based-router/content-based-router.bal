import ballerina/http;

type UKresponse record {|
    string url;
    record {|
        string id;
        record {|
            string statusCode;
            string status;
        |} status;
    |}[] shipments;
|};

type DPIresponse record {|
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

type TrackingReq record {
    string trackingNumber;
    string country;
};

service /shipping on new http:Listener(9090) {

    resource function get tracking(string trackingNumber, string country) returns string|error {
        match country {
            UK => {
                http:Client ukClient = check new ("http://api.parceluk.com.balmock.io");
                UKresponse response = check ukClient->/tracking/v1/shipments(trackingNumber = trackingNumber);
                return response.shipments[0].status.status;
            }
            DE => {
                http:Client deClient = check new ("http://api.dpi.com.balmock.io");
                DPIresponse response = check deClient->/tracking/v1/trackings/[trackingNumber];
                return response.events[0].status;
            }
            _ => {
                return "Invalid country";
            }
        }
    }
}
