import ballerina/mqtt;
import ballerina/uuid;

type RoutingEntry record {|
    string deviceId;
    int roomNo;
|};

final mqtt:Client mqttClient = check new (mqtt:DEFAULT_URL, uuid:createType1AsString());

public function main() returns error? {
    RoutingEntry[] entries = [{deviceId: "EB23591", roomNo: 15},
    {deviceId: "DL340981", roomNo: 9}];

    foreach var entry in entries {
        check mqttClient->publish("bulb/config", {payload: entry.toJsonString().toBytes()});
    }
}
