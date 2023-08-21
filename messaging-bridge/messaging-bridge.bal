import ballerina/graphql;
import ballerina/http;

type Project record {|
    string projectID;
    string projectName;
    string description;
    string customerName;
    Task[] tasks;
|};

type Task record {|
    string taskID;
    string description;
|};

type ProjectInput record {|
    string projectName;
    string description;
    string customerName;
|};

final http:Client zoho = check new("http://zohoapis.com.balmock.io");

service /api/v1 on new graphql:Listener(8080) {

    resource function get project(string organizationID, string projectID) returns Project|error {
        return zoho->/books/v3/projects/[projectID].get(organization_id = organizationID);
    }

    remote function createProject(ProjectInput projectInput, string organizationID) returns Project|error {
        return zoho->/books/v3/projects.post(projectInput, organization_id = organizationID);
    }
}
