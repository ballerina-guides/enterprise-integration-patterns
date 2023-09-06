import ballerina/http;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/sql;

boolean healthy = true;

service /customer on new http:Listener(8080) {
    private mysql:Client? db = null;
    function init() {
        self.db = startConnection();
    }

    resource function get number(string id) returns string|http:InternalServerError|http:NotFound {
        mysql:Client? db = self.db;
        if db == () {
            self.db = startConnection();
        }
        if db is mysql:Client {
            string|error result = db->queryRow(`SELECT number FROM customers WHERE id = ${id}`);

            if result is sql:NoRowsError {
                healthy = true;
                return http:NOT_FOUND;
            }
            else if result is error {
                healthy = false;
                return http:INTERNAL_SERVER_ERROR;
            }
            else {
                healthy = true;
                return result;
            }
        }
        return http:INTERNAL_SERVER_ERROR;
    }

    resource function get hearbeat() returns http:Ok|http:InternalServerError {
        return healthy? http:OK : http:INTERNAL_SERVER_ERROR;
    }
}

function startConnection() returns mysql:Client? {
    mysql:Client|error dbInit = new ("localhost", "admin", "adminpass", "CUSTOMER", 3000);
    if dbInit is mysql:Client {
        healthy = true;
        return dbInit;
    }
    healthy = false;
    return;
}
