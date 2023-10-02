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

final map<string> stateRoutes = {
    Texas: "http://api.texas.office.com.balmock.io",
    Ohio: "http://api.ohio.office.com.balmock.io",
    Florida: "http://api.florida.office.com.balmock.io"
};

AggregratedInfo summary = {
    revenueByState: {},
    totalRevenue: 0.0,
    maxRevenue: 0.0,
    maxRevenueState: "",
    operatingExpensesByState: {},
    totalOperatingExpenses: 0.0,
    totalProduction: 0,
    productivityByState: {}
};

service /api/v1 on new http:Listener(8080) {
    resource function post state\-info(InfoRequest infoRequest) returns AggregratedInfo|error? {
        foreach string state in infoRequest.states {
            string? stateRoute = stateRoutes[state];
            if stateRoute == () {
                return error("Invalid state provided");
            }
            http:Client stateClient = check new (stateRoute);
            StateInfo stateInfo = check stateClient->/statistics();
            aggregateInfo(state, stateInfo);
        }
        return summary;
    }
}

function aggregateInfo(string state, StateInfo stateInfo) {
    summary.revenueByState[state] = stateInfo.revenue;
    summary.totalRevenue += stateInfo.revenue;
    summary.operatingExpensesByState[state] = stateInfo.operatingExpenses;
    summary.totalOperatingExpenses += stateInfo.operatingExpenses;
    summary.totalProduction += stateInfo.production;
    summary.maxRevenueState = summary.maxRevenue < stateInfo.revenue ? state : summary.maxRevenueState;
    summary.maxRevenue = summary.maxRevenue < stateInfo.revenue ? stateInfo.revenue : summary.maxRevenue;
    summary.productivityByState[state] = stateInfo.production / stateInfo.totalEmployees;
}
