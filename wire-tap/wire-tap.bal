import ballerina/http;

type SnowflakeRequest record {
    string statement;
    string timeout = "60";
    string database = "messageLog";
    string schema = "message";
    string role = "logger";
};

type StockResponse record {
    string ParentHandlingUnitUUID;
    string StockItemUUID;
    string EWMWarehouse;
    string HandlingUnitNumber;
    string ShelfLifeExpirationDate;
    string CountryOfOrigin;
};

final http:Client sapClient = check new("http://api.sap.com.balmock.io");

service /warehouse on new http:Listener(8080) {
    
    resource function get stock(string parentId, string productId) returns StockResponse|error {
        StockResponse result = check sapClient->/WarehousePhysicalStockProducts/[parentId]/[productId];
        worker w returns error? {
            check wiretap("stock", "INFO", result.toString());
        }
        return result;
    }
}


function wiretap(string 'table, "INFO"|"WARNING"|"ERROR" severity, string message) returns error? {
    http:Client db = check new("http://api.snowflake.com.balmock.io");
    SnowflakeRequest snowflakeRequest = {statement: string `insert into ${'table} values (${message}, ${severity}))`};
    json _ = check db->/statements.post(snowflakeRequest);
}
