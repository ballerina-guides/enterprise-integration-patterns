import ballerina/http;

type Presence record {
    string id;
    string availability;
    string presence;
};

type WireTapRequest record {
    string 'table;
    "INFO"|"WARNING"|"ERROR" severity;
    string message;
};

listener http:Listener ls = new http:Listener(8080);
service /presence on ls {

    resource function get availability(string id) returns Presence|error {
        http:Client microsoft = check new("http://api.microsoft.com.balmock.io");
        Presence res = check microsoft->/v1\.0/users/[id]/presence;
        http:Client logger = check new("http://localhost:8080/logger");
        string _ = check logger->/logger.post({severity: "INFO", message: res.toString()});
        return res;
    }   
}
