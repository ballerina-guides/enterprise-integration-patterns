import ballerina/http;

type ReimbursementRequest record {|
    int employee_id;
    string reason;
    string amount;
|};

final http:Client dbClient = check new("http://api.internal-db.balmock.io");

service /engineering on new http:Listener(8080) {
    resource function post reimburse(ReimbursementRequest request) returns http:Response|error {
        http:Response dbResponse = check dbClient ->post("/reimbursements", request);
    
        http:Response outbound = new;
        outbound.setPayload(check dbResponse.getJsonPayload());
        outbound.statusCode = dbResponse.statusCode;

        if dbResponse.hasHeader("x-message-history") {
            string dbHeader = check dbResponse.getHeader("x-message-history");
            outbound.setHeader("x-message-history", dbHeader +", engineering");
        } else {
            outbound.setHeader("x-message-history", "engineering");
        }
        return outbound;
    }
}
