import ballerina/graphql;
import ballerina/http;

type Project record {
    string projectID;
    string projectName;
    string customerName;
    string description;
    string status;
    string billingType;
    string totalHours;
    float billedAmount;
    string costBudgetAmount;
    Task[] tasks;
};

type Task record {
    string taskID;
    string taskName;
    string description;
    string totalHours;
};

final http:Client zoho = check new("http://zohoapis.com.balmock.io");

service /api/v1 on new graphql:Listener(8080) {

    resource function get project(string projectID, string organizationID) returns Project|error {
        return zoho->/books/v3/projects/[projectID].post({organization_id: organizationID});
    }
}
