import ballerina/http;
import ballerina/mime;
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
final string twilioSID = "VAC1829a53d52f41b4b2b1cc003c0026aa8";
final string  apiVersion = "2010-04-01";

final http:Client twilioClient = check new ("http://api.twilio.com.balmock.io");

service /events on new http:Listener(8080) {
    resource function post reminder(@http:Payload ReminderRequest request) returns error? {
            error?[][] _ = from Event event in request.events
            select from Attendee attendee in event.attendees
            select sendMessage(attendee.name, event.eventName, request.date, attendee.number);
    }
}

function sendMessage(string name, string eventName, string date, string toNo) returns error?{
    string body = "Hi " + name + ", looking forward to meet you at the " +
                eventName + " on " + date;
    http:Request twilioReq = new;
    string payload = "From=" + check url:encode(fromNo, "utf-8") +
                    "&To=" + check url:encode(toNo, "utf-8")  +
                    "&Body=" + check url:encode(body, "utf-8");
    twilioReq.setTextPayload(payload, contentType = mime:APPLICATION_FORM_URLENCODED);
    http:Response _ = check twilioClient->
            /[apiVersion]/Accounts/[twilioSID]/Messages\.json.post(twilioReq);
}
