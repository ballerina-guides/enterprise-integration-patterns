import ballerina/http;

type SnowflakeRequest record {
    string statement;
    string timeout = "60";
    string database = "messageLog";
    string schema = "message";
    string role = "logger";
};

type WireTapRequest record {|
    string 'table;
    "INFO"|"WARNING"|"ERROR" severity;
    string message;
|};

type StockResponse record {
    string ParentHandlingUnitUUID;
    string StockItemUUID;
    string EWMWarehouse;
    string HandlingUnitNumber;
    string ShelfLifeExpirationDate;
    string CountryOfOrigin;
};

http:Client sapClient = check new("http://api.sap.com.balmock.io");

service /warehouse on new http:Listener(8080) {
    
    resource function get stock(string parentId, string productId) returns StockResponse|error {
        StockResponse result = check sapClient->/WarehousePhysicalStockProducts/[parentId]/[productId];
        worker w returns error? {
            check wiretap({'table: "stock", severity: "INFO", message: result.toString()});
        }
        return result;
    }
}


function wiretap(WireTapRequest wt) returns error? {
    http:Client db = check new("http://api.snowflake.com.balmock.io");
    SnowflakeRequest snowflakeRequest = {statement: string `insert into ${wt.'table} values (${wt.message}, ${wt.severity}))`};
    json _ = check db->/statements.post(snowflakeRequest);
}
