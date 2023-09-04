import ballerina/http;
import ballerina/mime;
import ballerina/io;
import ballerina/url;

type ReminderRequest record {
    string date;
    Event[] events;
};

type Event record {|
    string eventName;
    Attendee[] attendees;
|};

type Attendee record {|
    string name;
    string number;
|};

final string fromNo = "+15005550006";
final string twilioDummySID = "VAC1829a53d52f41b4b2b1cc003c0026aa8";
final string  apiVersion = "2010-04-01";

final http:Client twilioClient = check new ("https://api.twilio.com.balmock.io");

service /events on new http:Listener(8080) {
    resource function post reminder(@http:Payload json request) returns error? {
        ReminderRequest requestRecord = check request.fromJsonWithType(ReminderRequest);
            foreach Event event in requestRecord.events {
                foreach Attendee attendee in event.attendees {
                    string toNo = attendee.number;
                    string body = "Hi " + attendee.name + ", looking forward to meet you at the " +
                                event.eventName + " on " + requestRecord.date;
                    io:println(body);
                    http:Request req = new;
                    string requestBody = "";
                    requestBody = check createUrlEncodedRequestBody(requestBody, "From", fromNo);
                    requestBody = check createUrlEncodedRequestBody(requestBody, "To", toNo);
                    requestBody = check createUrlEncodedRequestBody(requestBody, "Body", body);
                    req.setTextPayload(requestBody, contentType = mime:APPLICATION_FORM_URLENCODED);
                    http:Response response = check twilioClient->
                        /[apiVersion]/Accounts/[twilioDummySID]/Messages\.json.post(requestRecord);
                    io:println(response.getJsonPayload());
                }
            }
        }
    }

function createUrlEncodedRequestBody(string requestBody, string key, string value) returns string|error {
    var encodedVar = url:encode(value, "utf-8");
    string encodedString = "";
    string body = "";
    if (encodedVar is string) {
        encodedString = encodedVar;
    } else {
        return error("Error occurred while encoding data");
    }
    if (requestBody != "") {
        body = requestBody + "&";
    }
    return body + key + "=" + encodedString;
}
