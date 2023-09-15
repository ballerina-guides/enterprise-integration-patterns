import ballerina/http;
import ballerina/mime;
import ballerina/time;

type OAuthRequest record {
    string initializedTime;
    decimal expiration;
};

string? initializedTime = ();
decimal expiration = 0;

service /storage on new http:Listener(8080) {
    resource function post setUp(OAuthRequest req) {
        initializedTime = req.initializedTime;
        expiration = req.expiration;
    }

    resource function get image(string fileName) returns http:Response|error? {
        string? createdTime = initializedTime;
        if createdTime is string {
            boolean isExpired = check validateTimeExpiration(createdTime, expiration);
            if isExpired {
                return;
            }
            http:Response response = new();
            response.setFileAsPayload("./resources/" + fileName, mime:IMAGE_PNG);
            return response;
        }
        return;
    }
}

isolated function validateTimeExpiration(string time, decimal expiration) returns boolean|error {
    decimal aliveTime = time:utcDiffSeconds(time:utcNow(), check time:utcFromString(time)) / 60;
    return aliveTime > expiration;
}
