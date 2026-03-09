@isTest
public class FinnhubCalloutMock implements HttpCalloutMock {

    private Integer statusCode;
    private String responseBody;

    public FinnhubCalloutMock() {
        this.statusCode = 200;
        this.responseBody = null;
    }

    public FinnhubCalloutMock(Integer statusCode, String responseBody) {
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
        } else if (endpoint.contains('/quote')) {
            return getQuoteSuccessResponse();
        }
        return '{}';
    }

    public static String getSearchSuccessResponse() {
        return '{'
            + '"count": 2,'
            + '"result": ['
            + '  {'
            + '    "description": "Apple Inc",'
            + '    "displaySymbol": "AAPL",'
            + '    "symbol": "AAPL",'
            + '    "type": "Common Stock"'
            + '  },'
            + '  {'
            + '    "description": "Microsoft Corporation",'
            + '    "displaySymbol": "MSFT",'
            + '    "symbol": "MSFT",'
            + '    "type": "Common Stock"'
            + '  }'
            + ']'
            + '}';
    }

    public static String getQuoteSuccessResponse() {
        return '{'
            + '"c": 228.50,'
            + '"d": 1.50,'
            + '"dp": 0.6608,'
            + '"h": 229.12,'
            + '"l": 226.80,'
            + '"o": 227.54,'
            + '"pc": 227.00,'
            + '"t": 1709942400'
            + '}';
    }

    public static String getEmptyQuoteResponse() {
        return '{"c": 0, "d": null, "dp": null, "h": 0, "l": 0, "o": 0, "pc": 0, "t": 0}';
    }

    public static String getRateLimitResponse() {
        return '{"error": "API limit reached. Please try again later."}';
    }

    public static String getAuthErrorResponse() {
        return '{"error": "You don\'t have access to this resource."}';
    }
}
