import ballerina/http;

type InfoRequest record {|
    string[] states;
|};

type StateInfo record {|
    decimal revenue;
    decimal operatingExpenses;
    int production;
    int totalEmployees;
|};

type AggregratedInfo record {|
    map<decimal> revenueByState;
    decimal totalRevenue;
    decimal maxRevenue;
    string maxRevenueState;
    map<decimal> operatingExpensesByState;
    decimal totalOperatingExpenses;
    int totalProduction;
    map<int> productivityByState;
|};

final map<http:Client> stateRoutes = {
    Texas: check new ("http://api.texas.office.com.balmock.io"),
    Ohio: check new ("http://api.ohio.office.com.balmock.io"),
    Florida: check new ("http://api.florida.office.com.balmock.io")
};

service /api/v1 on new http:Listener(8080) {
    resource function post dashboard(InfoRequest infoRequest) returns AggregratedInfo|error {
        AggregratedInfo summary = initSummary();
        foreach string state in infoRequest.states {
            http:Client? stateClient = stateRoutes[state];
            if stateClient == () {
                return error("Invalid state provided");
            }
            StateInfo stateInfo = check stateClient->/statistics();
            aggregateInfo(state, stateInfo, summary);
        }
        return summary;
    }
}

function initSummary() returns AggregratedInfo {
    return {
        revenueByState: {},
        totalRevenue: 0.0,
        maxRevenue: 0.0,
        maxRevenueState: "",
        operatingExpensesByState: {},
        totalOperatingExpenses: 0.0,
        totalProduction: 0,
        productivityByState: {}
    };
}

function aggregateInfo(string state, StateInfo stateInfo, AggregratedInfo summary) {
    summary.revenueByState[state] = stateInfo.revenue;
    summary.totalRevenue += stateInfo.revenue;
    summary.operatingExpensesByState[state] = stateInfo.operatingExpenses;
    summary.totalOperatingExpenses += stateInfo.operatingExpenses;
    summary.totalProduction += stateInfo.production;
    summary.maxRevenueState = summary.maxRevenue < stateInfo.revenue ? state : summary.maxRevenueState;
    summary.maxRevenue = summary.maxRevenue < stateInfo.revenue ? stateInfo.revenue : summary.maxRevenue;
    summary.productivityByState[state] = stateInfo.production / stateInfo.totalEmployees;
}
