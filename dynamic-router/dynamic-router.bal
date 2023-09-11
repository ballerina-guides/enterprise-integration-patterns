import ballerina/http;

type RoutingEntry record {|
    string deviceId;
    string roomNo;
    boolean dimmable;
|};

type SwitchRequest record {|
    string roomNo;
    State state;
|};

enum State {
    ON,
    OFF,
    DIM
}

final http:Client deviceClient = check new ("http://api.devices.com.balmock.io");

service /bulbs on new http:Listener(8080) {
    map<RoutingEntry> routingTable = {};
    resource function post switch(SwitchRequest switchRequest) returns error? {
        RoutingEntry? entry = self.routingTable[switchRequest.roomNo];
        if entry == () {
            return error("Invalid room");
        }
        if switchRequest.state == DIM && !entry.dimmable {
            return error("Bulb is not dimmable");
        }
        json _ = check deviceClient->/[entry.deviceId]/[switchRequest.state];
    }

    resource function post add_route(RoutingEntry entry) {
        self.routingTable[entry.roomNo] = entry;
    }
}
