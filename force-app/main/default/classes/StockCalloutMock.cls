@isTest
public class StockCalloutMock implements HttpCalloutMock {

    private Integer statusCode;
    private String responseBody;

    public StockCalloutMock() {
        this.statusCode = 200;
        this.responseBody = null;
    }

    public StockCalloutMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(this.statusCode);

        if (this.responseBody != null) {
            response.setBody(this.responseBody);
        } else {
            response.setBody(getResponseForEndpoint(request.getEndpoint()));
        }
        return response;
    }

    private String getResponseForEndpoint(String endpoint) {
        if (endpoint.contains('SYMBOL_SEARCH')) {
            return getSearchSuccessResponse();
        } else if (endpoint.contains('OVERVIEW')) {
            return getOverviewSuccessResponse();
        } else if (endpoint.contains('GLOBAL_QUOTE')) {
            return getQuoteSuccessResponse();
        }
        return '{}';
    }

    public static String getSearchSuccessResponse() {
        return '{'
            + '"bestMatches": ['
            + '  {'
            + '    "1. symbol": "AAPL",'
            + '    "2. name": "Apple Inc",'
            + '    "3. type": "Equity",'
            + '    "4. region": "United States",'
            + '    "5. marketOpen": "09:30",'
            + '    "6. marketClose": "16:00",'
            + '    "7. timezone": "UTC-04",'
            + '    "8. currency": "USD",'
            + '    "9. matchScore": "1.0000"'
            + '  },'
            + '  {'
            + '    "1. symbol": "TCS.BSE",'
            + '    "2. name": "Tata Consultancy Services Limited",'
            + '    "3. type": "Equity",'
            + '    "4. region": "India/Bombay",'
            + '    "5. marketOpen": "09:15",'
            + '    "6. marketClose": "15:30",'
            + '    "7. timezone": "UTC+5.5",'
            + '    "8. currency": "INR",'
            + '    "9. matchScore": "0.8000"'
            + '  }'
            + ']'
            + '}';
    }

    public static String getQuoteSuccessResponse() {
        return '{'
            + '"Global Quote": {'
            + '  "01. symbol": "AAPL",'
            + '  "02. open": "227.5400",'
            + '  "03. high": "229.1200",'
            + '  "04. low": "226.8000",'
            + '  "05. price": "228.5000",'
            + '  "06. volume": "45678901",'
            + '  "07. latest trading day": "2026-02-26",'
            + '  "08. previous close": "227.0000",'
            + '  "09. change": "1.5000",'
            + '  "10. change percent": "0.6608%"'
            + '}'
            + '}';
    }

    public static String getOverviewSuccessResponse() {
        return '{'
            + '"Symbol": "AAPL",'
            + '"Name": "Apple Inc",'
            + '"Description": "Apple Inc. designs, manufactures, and markets smartphones.",'
            + '"Exchange": "NASDAQ",'
            + '"Currency": "USD",'
            + '"52WeekHigh": "237.2300",'
            + '"52WeekLow": "164.0800"'
            + '}';
    }

    public static String getRateLimitResponse() {
        return '{"Note": "Thank you for using Alpha Vantage! Our standard API rate limit is 25 requests per day."}';
    }

    public static String getEmptyQuoteResponse() {
        return '{"Global Quote": {}}';
    }
}
