@isTest
public class MassiveCalloutMock implements HttpCalloutMock {

    private Integer statusCode;
    private String responseBody;

    public MassiveCalloutMock() {
        this.statusCode = 200;
        this.responseBody = null;
    }

    public MassiveCalloutMock(Integer statusCode, String responseBody) {
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
        if (endpoint.contains('/search')) {
            return getSearchSuccessResponse();
        } else if (endpoint.contains('/quotes')) {
            return getQuotesSuccessResponse();
        }
        return '{}';
    }

    public static String getSearchSuccessResponse() {
        return '{'
            + '"data": ['
            + '  {'
            + '    "symbol": "AAPL",'
            + '    "name": "Apple Inc",'
            + '    "type": "Equity",'
            + '    "region": "United States",'
            + '    "currency": "USD"'
            + '  },'
            + '  {'
            + '    "symbol": "GOOG",'
            + '    "name": "Alphabet Inc",'
            + '    "type": "Equity",'
            + '    "region": "United States",'
            + '    "currency": "USD"'
            + '  }'
            + ']'
            + '}';
    }

    public static String getQuotesSuccessResponse() {
        return '{'
            + '"data": ['
            + '  {'
            + '    "symbol": "AAPL",'
            + '    "name": "Apple Inc",'
            + '    "price": 228.50,'
            + '    "high": 229.12,'
            + '    "low": 226.80,'
            + '    "change": 1.50,'
            + '    "changePercent": 0.6608,'
            + '    "week52High": 237.23,'
            + '    "week52Low": 164.08'
            + '  }'
            + ']'
            + '}';
    }

    public static String getRateLimitResponse() {
        return '{"error": "Rate limit exceeded. Please try again later."}';
    }

    public static String getAuthErrorResponse() {
        return '{"error": "Invalid authentication key provided."}';
    }
}
