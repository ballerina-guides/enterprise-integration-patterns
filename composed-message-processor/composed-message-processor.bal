import ballerina/http;

type InfoRequest record {|
    string[] states;
|};

type StateInfo record {|
    decimal revenue;
    decimal operatingExpenses;
    decimal profit;
    int production;
    string productionEfficiency;
    int totalEmployees;
    string turnover;
|};

type Summary record {|
    decimal totalRevenue;
    map<string> revenueContirbution;
    decimal totalOperatingExpenses;
    decimal totalProfit;
    decimal maxProfit;
    string maxProfitState;
    decimal minProfit;
    string minProfitState;
    int totalProduction;
    int totalEmployees;
    map<int> productivityByState;
|};

final map<string> clients = {
    "Texas": "http://api.texas.office.com.balmock.io",
    "Ohio": "http://api.ohio.office.com.balmock.io",
    "Florida": "http://api.florida.office.com.balmock.io"
};


service /api/v1 on new http:Listener(8080) {
    resource function post state\-info(InfoRequest infoRequest) returns Summary|error? {
        StateInfo[] statesInfo = [];
        Summary summary = {
            totalRevenue: 0,
            revenueContirbution: {},
            totalOperatingExpenses: 0,
            totalProfit: 0,
            maxProfit: 0.0,
            maxProfitState: "",
            minProfit: 0.0,
            minProfitState: "",
            totalProduction: 0,
            totalEmployees: 0,
            productivityByState: {}
        };
        map<decimal> revenues = {};
        summary.totalRevenue = 0;
        foreach string state in infoRequest.states {
            string? url = clients[state];
            if url == () {
                return error("Invalid state provided");
            }
            http:Client stateClient = check new (url);
            StateInfo stateInfo = check stateClient->/statistics();
            summary.totalRevenue += stateInfo.revenue;
            summary.totalOperatingExpenses += stateInfo.operatingExpenses;
            summary.totalProfit += stateInfo.profit;
            summary.totalProduction += stateInfo.production;
            summary.totalEmployees += stateInfo.totalEmployees;
            if (summary.maxProfit < stateInfo.profit) {
                summary.maxProfit = stateInfo.profit;
                summary.maxProfitState = state;
            }
            summary.maxProfit = summary.maxProfit < stateInfo.profit ? stateInfo.profit : summary.maxProfit;
            summary.maxProfitState = summary.maxProfit < stateInfo.profit ? state : summary.maxProfitState;
            summary.minProfit = summary.minProfit > stateInfo.profit ? stateInfo.profit : summary.minProfit;
            summary.minProfitState = summary.minProfit > stateInfo.profit ? state : summary.minProfitState;
            revenues[state] = stateInfo.revenue;
            summary.productivityByState[state] = stateInfo.production / stateInfo.totalEmployees;
            statesInfo.push(stateInfo);
        }
        getRevenueContribution();
        return summary;
    }
}

function processInfo(StateInfo info) {
    // add processing logic here
}

function getRevenueContribution() {
    // calculate revenue contribution
}
