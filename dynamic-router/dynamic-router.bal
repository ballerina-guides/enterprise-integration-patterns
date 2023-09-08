import ballerina/http;

type RoutingEntry record {|
    string deviceId;
    string roomNo;
|};

type Intensity  0|1|2;

final http:Client deviceClient = check new ("http://api.devices.balmock.io");

service /bulbs on new http:Listener(8080) {
    map<string> routingTable = {};
    resource function get [string room]/[Intensity intensity]() returns error? {
        string? deviceId = self.routingTable[room];
        if deviceId == () {
            return error("Invalid room");
        }
        json _ = check deviceClient->/[deviceId]/[intensity];
    }

    resource function post add_route(RoutingEntry entry) {
        self.routingTable[entry.roomNo] = entry.deviceId;
    }
}
