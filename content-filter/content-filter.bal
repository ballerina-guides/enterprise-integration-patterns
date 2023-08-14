import ballerina/http;

type ReimbursementTemplate record {
    string reimbursementTypeID;
    string reimbursementTypeName;
    float? fixedAmount;
    float? ratePerUnit;
    float? numberOfUnits;
};

type XeroRequest record {
    string reimbursementTypeID;
    float fixedAmount?;
    float ratePerUnit?;
    float numberOfUnits?;
};

type Reimbursement record {
    string id;
    record {
        string reimbursementTypeID;
        float? fixedAmount;
        float? ratePerUnit;
        float? numberOfUnits;
    }[] reimbursementTemplates;
};

service /payroll on new http:Listener(8080) {

    resource function post employees/[string id]/paytemplate/reimbursements(ReimbursementTemplate[] templates) returns Reimbursement|error {
        http:Client xeroClient = check new ("http://api.xero.com.balmock.io");
        XeroRequest[] xeroRequests = from ReimbursementTemplate template in templates select createXeroRequest(template);
        return xeroClient->/payroll\.xro/'2\.0/rmployees/[id]/paytemplate/reimbursements.post(xeroRequests);
    }
}

function createXeroRequest(ReimbursementTemplate template) returns XeroRequest {
    if template.fixedAmount !is () {
        return {
            reimbursementTypeID: template.reimbursementTypeID,
            fixedAmount: template.fixedAmount
        };
    }
    return {
        reimbursementTypeID: template.reimbursementTypeID,
        ratePerUnit: template.ratePerUnit,
        numberOfUnits: template.numberOfUnits
    };
}
