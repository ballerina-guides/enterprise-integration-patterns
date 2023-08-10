import ballerina/http;

type ReimbursementRequest record {|
    string employeeName;
    string employeeNumber;
    string reportingLead;	
    string accountID;
    record {|
        string name;
        string calculationType;	
        string reimbursementCategory;
        float? standardAmount;
        string? standardTypeOfUnits;
        float? standardRatePerUnit;
        string claimDate;
        string urlForReceipt;
        string urlForBankStatement?;
    |} reimbursementDetails;
    string comments;
|};

type XeroRequest record {|
    string name;
    string accountID;
    float? standardAmount;
    string? standardTypeOfUnits;
    float? standardRatePerUnit;
    string reimbursementCategory;
    string calculationType;
|};

type Reimbursement record {|
    string id;
    string providerName;
    string dateTimeUTC;
    string httpStatusCode;
    string? pagination;
    string? problem;
    record {|
        string reimbursementID;
        string name;
        string accountID;
        boolean currentRecord;
        float? standardAmount;
        string? standardTypeOfUnits;
        float? standardRatePerUnit;
        string reimbursementCategory;
        string calculationType;
    |} reimbursement;
|};

service /payroll on new http:Listener(8080) {

    resource function post reimbursements(ReimbursementRequest request) returns Reimbursement|error {
        http:Client xeroClient = check new("http://api.xero.com.balmock.io");
        XeroRequest xeroRequest = {
            name: request.reimbursementDetails.name,
            accountID: request.accountID,
            standardAmount: request.reimbursementDetails.standardAmount,
            standardTypeOfUnits: request.reimbursementDetails.standardTypeOfUnits,
            standardRatePerUnit: request.reimbursementDetails.standardRatePerUnit,
            reimbursementCategory: request.reimbursementDetails.reimbursementCategory,
            calculationType: request.reimbursementDetails.calculationType
        };
        return xeroClient->/payroll\.xro/'2\.0/reimbursements.post(xeroRequest);
    }
}
