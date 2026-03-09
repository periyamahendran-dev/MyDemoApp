@isTest
public class ExchangeRateCalloutMock implements HttpCalloutMock {

    private Integer statusCode;
    private String responseBody;

    public ExchangeRateCalloutMock() {
        this.statusCode = 200;
        this.responseBody = null;
    }

    public ExchangeRateCalloutMock(Integer statusCode, String responseBody) {
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
        if (endpoint.contains('frankfurter')) {
            return getFrankfurterSuccessResponse();
        } else if (endpoint.contains('jsdelivr') || endpoint.contains('fawazahmed0')) {
            return getFawazAhmedSuccessResponse();
        }
        return getErApiSuccessResponse();
    }

    public static String getErApiSuccessResponse() {
        return '{'
            + '"result": "success",'
            + '"base_code": "USD",'
            + '"rates": {'
            + '  "USD": 1,'
            + '  "EUR": 0.85,'
            + '  "GBP": 0.73,'
            + '  "JPY": 110.0,'
            + '  "INR": 74.5,'
            + '  "AUD": 1.35,'
            + '  "CAD": 1.25'
            + '}'
            + '}';
    }

    public static String getSuccessResponse() {
        return getErApiSuccessResponse();
    }

    public static String getFrankfurterSuccessResponse() {
        return '{'
            + '"amount": 1.0,'
            + '"base": "USD",'
            + '"date": "2026-02-26",'
            + '"rates": {'
            + '  "EUR": 0.85,'
            + '  "GBP": 0.73,'
            + '  "JPY": 110.0,'
            + '  "INR": 74.5,'
            + '  "AUD": 1.35,'
            + '  "CAD": 1.25'
            + '}'
            + '}';
    }

    public static String getFawazAhmedSuccessResponse() {
        return '{'
            + '"date": "2026-02-26",'
            + '"usd": {'
            + '  "usd": 1,'
            + '  "eur": 0.85,'
            + '  "gbp": 0.73,'
            + '  "jpy": 110.0,'
            + '  "inr": 74.5,'
            + '  "aud": 1.35,'
            + '  "cad": 1.25'
            + '}'
            + '}';
    }

    public static String getErrorResponse() {
        return '{"result": "error", "error-type": "unsupported-code"}';
    }
}
