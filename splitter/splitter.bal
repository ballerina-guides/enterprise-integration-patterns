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

const FROM_NO = "+15005550006";
const TWILIO_SID = "VAC1829a53d52f41b4b2b1cc003c0026aa8";
const API_VERSION = "2010-04-01";
const ENCODING = "utf-8";

final http:Client twilioClient = check new ("http://api.twilio.com.balmock.io");

service /api/v1 on new http:Listener(8080) {
    resource function post reminders(ReminderRequest request) returns error? {
        from Event event in request.events
            from Attendee attendee in event.attendees
                do {
                    check sendReminder(attendee, event.eventName, request.date);
                };
    }
}

function sendReminder(Attendee attendee, string eventName, string date) returns error? {
    string body = string `Hi ${attendee.name}, looking forward to meet you at the ${eventName} on ${date}`;
    http:Request twilioReq = new;
    string payload = string `From=${check url:encode(FROM_NO, ENCODING)}&To=${check url:encode(attendee.number,
                     ENCODING)}&Body=${check url:encode(body, ENCODING)}}`;
    twilioReq.setTextPayload(payload, contentType = mime:APPLICATION_FORM_URLENCODED);
    var _ = check twilioClient->
            /[API_VERSION]/Accounts/[TWILIO_SID]/Messages\.json.post(twilioReq, targetType = http:Response);
}
