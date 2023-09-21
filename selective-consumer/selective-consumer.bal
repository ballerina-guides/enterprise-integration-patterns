import ballerina/graphql;
import ballerina/io;

type InventoryResponse record {|
    record {|Inventory[] products;|} data;
|};

type Inventory record {
    string name;
    int productsCount;
};

type CsvRecord record {|
    string name;
    RequestType requestType;
|};

enum RequestType {
    REQUIRED,
    URGENT
};

final graphql:Client shopify = check new ("http://blackwellsbooks.myshopify.com.balmock.io");
// final graphql:Client shopify = check new ("localhost:8080");

public function main(string category) returns error? {
    final string csvFilePath = "./resources/orderRequests.csv";
    CsvRecord[] csvContent = [];
    string document = string `{ products(productType: "${category}") { name, productsCount } } `;
    InventoryResponse inventories = check shopify->execute(document);
    foreach Inventory product in inventories.data.products {
        if product.productsCount < 10 {
            csvContent.push({name: product.name, requestType: URGENT});
        } else if product.productsCount < 25 {
            csvContent.push({name: product.name, requestType: REQUIRED});
        }
    }
    check io:fileWriteCsv(csvFilePath, csvContent);
}
