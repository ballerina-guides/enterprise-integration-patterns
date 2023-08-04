import ballerina/http;
import ballerina/io;

configurable string path = ?;
configurable int case = ?;

service / on new http:Listener(80) {

  resource function default [string... parm](http:Request req) returns anydata|error {
    string host = check req.getHeader("host");
    return check io:fileReadJson(path + "/case-" + pad2(case) + "-" + host + ".json");
  }
}

function pad2(int i) returns string {
    string s = i.toString();
    if i < 10 {
        return "0" + s;
    }
    return s;
}

