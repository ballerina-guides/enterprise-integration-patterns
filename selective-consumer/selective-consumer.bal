import ballerina/http;
import ballerina/io;

type Inventory record {|
    string id;
    string name;
    int productsCount;
|};

type InventoryResponse record {|
    Inventory[] products;
|};

type CsvRecord record {|
    string name;
    RequestType requestType;
|};

enum RequestType {
    REQUIRED,
    URGENT
};

final CsvRecord[] csvContent = [];
final string csvFilePath = "./resources/orderRequests.csv";

final http:Client shopify = check new ("http://BlackwellsBooks.myshopify.com.balmock.io");

public function main(string category) returns error? {
            InventoryResponse inventories = check shopify->/admin/api/graphql\.json.post({
                query: string `query { products(product_type: "${category}") { name productsCount } }`
            });
            _ = from Inventory inventory in inventories.products
                select createCsv(inventory);

}

function createCsv(Inventory product) returns error? {
    if product.productsCount < 25 && product.productsCount > 10 {
        csvContent.push({name: product.name, requestType: REQUIRED});
    } else if product.productsCount < 10 {
        csvContent.push({name: product.name, requestType: URGENT});
    }
    check io:fileWriteCsv(csvFilePath, csvContent);

}