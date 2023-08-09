import ballerina/http;

type SnowflakeRequest record {
    string statement;
    string timeout = "60";
    string database = "messageLog";
    string schema = "message";
    string role = "logger";
};

type WireTapRequest record {
    string 'table;
    "INFO"|"WARNING"|"ERROR" severity;
    string message;
};

service /logger on new http:Listener(8080) {
    
    resource function post wiretap(WireTapRequest wt) returns error? {
        http:Client db = check new("http://api.snowflake.com.balmock.io");
        SnowflakeRequest snowflakeRequest = {statement: string `insert into ${wt.'table} values (${wt.message}, ${wt.severity}))`};
        json _ = check db->/statements.post(snowflakeRequest);
    }
}
