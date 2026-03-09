public with sharing class StockService {

    private static final Integer DEFAULT_TIMEOUT_MS = 15000;

    public class StockServiceException extends Exception {}

    public class StockSearchResult {
        @AuraEnabled public String symbol;
        @AuraEnabled public String name;
        @AuraEnabled public String stockType;
        @AuraEnabled public String region;
        @AuraEnabled public String currencyCode;

        public StockSearchResult(String symbol, String name, String stockType, String region, String currencyCode) {
            this.symbol = symbol;
            this.name = name;
            this.stockType = stockType;
            this.region = region;
            this.currencyCode = currencyCode;
        }
    }

    public class StockQuote {
        @AuraEnabled public String symbol;
        @AuraEnabled public String name;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Decimal dayHigh;
        @AuraEnabled public Decimal dayLow;
        @AuraEnabled public Decimal change;
        @AuraEnabled public String changePercent;
        @AuraEnabled public Decimal week52High;
        @AuraEnabled public Decimal week52Low;
    }

    // Shared HTTP utility used by all providers
    public static HttpResponse sendRequest(String endpoint, Integer timeoutMs) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setTimeout(timeoutMs != null ? timeoutMs : DEFAULT_TIMEOUT_MS);

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 429) {
            throw new StockServiceException('Rate limit exceeded. Please wait 1 minute or switch APIs.');
        }

        if (response.getStatusCode() == 401 || response.getStatusCode() == 403) {
            throw new StockServiceException('Authentication failed. Please check API key settings.');
        }

        if (response.getStatusCode() != 200) {
            throw new StockServiceException(
                'API request failed with status ' + response.getStatusCode() + ': ' + response.getStatus()
            );
        }
        return response;
    }

    public static Decimal safeDecimal(String value) {
        if (String.isBlank(value) || value == 'None' || value == '-' || value == 'null') {
            return null;
        }
        try {
            return Decimal.valueOf(value.replaceAll('[^0-9.\\-]', ''));
        } catch (Exception e) {
            return null;
        }
    }

    // Backward-compatible facade methods that delegate to the default provider

    public static List<StockSearchResult> searchStocks(String keywords) {
        StockQuoteProvider provider = StockQuoteProviderFactory.getProvider(StockQuoteProviderFactory.ALPHA_VANTAGE);
        return provider.searchStocks(keywords);
    }

    public static StockQuote getStockQuote(String symbol) {
        if (String.isBlank(symbol)) {
            throw new StockServiceException('Stock symbol cannot be blank');
        }
        StockQuoteProvider provider = StockQuoteProviderFactory.getProvider(StockQuoteProviderFactory.ALPHA_VANTAGE);
        List<StockQuote> quotes = provider.getQuotes(new List<String>{ symbol });
        if (quotes.isEmpty()) {
            throw new StockServiceException('No quote data returned for symbol: ' + symbol);
        }
        StockQuote quote = quotes[0];
        if (quote.changePercent == 'Error') {
            throw new StockServiceException('Failed to retrieve quote for symbol: ' + symbol);
        }
        return quote;
    }
}
