import ballerina/http;

type DetailedReimbursementTemplate record {
    string reimbursementTypeID;
    string reimbursementTypeName;
    float fixedAmount;
};

type FilteredReimbursementTemplate record {
    string reimbursementTypeID;
    float fixedAmount;
};

type Reimbursement record {
    string id;
    record {
        string reimbursementTypeID;
        float fixedAmount;
    }[] reimbursementTemplates;
};

service /payroll on new http:Listener(8080) {

    resource function post employees/[string id]/paytemplate/reimbursements(DetailedReimbursementTemplate[] templates) returns Reimbursement|error {
        http:Client xeroClient = check new ("http://api.xero.com.balmock.io");
        FilteredReimbursementTemplate[] reimbursementRequests = from DetailedReimbursementTemplate template in templates
            select {reimbursementTypeID: template.reimbursementTypeID, fixedAmount: template.fixedAmount};
        return xeroClient->/payroll\.xro/'2\.0/employees/[id]/paytemplate/reimbursements.post(reimbursementRequests);
    }
}
