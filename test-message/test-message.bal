import ballerina/http;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/sql;

service /customer on new http:Listener(8080) {
    private mysql:Client? db = null;
    boolean dbConnected = false;

    function init() {
        mysql:Client|error dbInit = new ("localhost", "admin", "adminpass", "CUSTOMER", 3000);
        if dbInit is mysql:Client {
            self.db = dbInit;
            self.dbConnected = true;
        }
    }

    resource function get number(string id) returns string|http:InternalServerError|http:NotFound {
        mysql:Client? db = self.db;
        if db !is mysql:Client {
            return http:INTERNAL_SERVER_ERROR;
        }

        string|error result = db->queryRow(`SELECT number FROM customers WHERE id = ${id}`);
        if result is sql:NoRowsError {
            self.dbConnected = true;
            return http:NOT_FOUND;
        }
        else if result is error {
            self.dbConnected = false;
            return http:INTERNAL_SERVER_ERROR;
        }
        else {
            self.dbConnected = true;
            return result;
        }
    }

    resource function get heartbeat() returns http:Ok|http:InternalServerError {
        return self.dbConnected ? http:OK : http:INTERNAL_SERVER_ERROR;
    }
}
