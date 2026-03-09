public with sharing class AlphaVantageProvider implements StockQuoteProvider {

    private static final String BASE_URL = 'callout:AlphaVantageAPI/query';
    private static final Integer TIMEOUT_MS = 15000;

    @TestVisible
    private static String testApiKey;

    public String getProviderName() {
        return 'Alpha Vantage';
    }

    public List<StockService.StockQuote> getQuotes(List<String> symbols) {
        List<StockService.StockQuote> quotes = new List<StockService.StockQuote>();
        String apiKey = getApiKey();

        for (String symbol : symbols) {
            if (String.isBlank(symbol)) {
                continue;
            }
            try {
                String quoteEndpoint = BASE_URL + '?function=GLOBAL_QUOTE&symbol='
                    + EncodingUtil.urlEncode(symbol.trim(), 'UTF-8')
                    + '&apikey=' + apiKey;
                HttpResponse quoteResponse = StockService.sendRequest(quoteEndpoint, TIMEOUT_MS);
                StockService.StockQuote quote = parseGlobalQuote(quoteResponse.getBody(), symbol.trim());

                try {
                    String overviewEndpoint = BASE_URL + '?function=OVERVIEW&symbol='
                        + EncodingUtil.urlEncode(symbol.trim(), 'UTF-8')
                        + '&apikey=' + apiKey;
                    HttpResponse overviewResponse = StockService.sendRequest(overviewEndpoint, TIMEOUT_MS);
                    enrich52WeekData(quote, overviewResponse.getBody());
                } catch (Exception e) {
                    // OVERVIEW may not be available for all exchanges
                }

                quotes.add(quote);
            } catch (Exception e) {
                StockService.StockQuote errorQuote = new StockService.StockQuote();
                errorQuote.symbol = symbol.trim();
                errorQuote.name = symbol.trim();
                errorQuote.changePercent = 'Error';
                quotes.add(errorQuote);
            }
        }
        return quotes;
    }

    public List<StockService.StockSearchResult> searchStocks(String keywords) {
        if (String.isBlank(keywords)) {
            throw new StockService.StockServiceException('Search keywords cannot be blank');
        }

        String apiKey = getApiKey();
        String endpoint = BASE_URL + '?function=SYMBOL_SEARCH&keywords='
            + EncodingUtil.urlEncode(keywords, 'UTF-8')
            + '&apikey=' + apiKey;

        HttpResponse response = StockService.sendRequest(endpoint, TIMEOUT_MS);
        return parseSearchResponse(response.getBody());
    }

    private String getApiKey() {
        if (Test.isRunningTest() && String.isNotBlank(testApiKey)) {
            return testApiKey;
        }
        List<Stock_API_Setting__mdt> settings = [
            SELECT API_Key__c FROM Stock_API_Setting__mdt
            WHERE DeveloperName = 'Alpha_Vantage' LIMIT 1
        ];
        if (settings.isEmpty() || String.isBlank(settings[0].API_Key__c)
                || settings[0].API_Key__c == 'REPLACE_WITH_YOUR_API_KEY') {
            throw new StockService.StockServiceException(
                'Authentication failed for Alpha Vantage. Please check settings.'
            );
        }
        return settings[0].API_Key__c;
    }

    private List<StockService.StockSearchResult> parseSearchResponse(String responseBody) {
        List<StockService.StockSearchResult> results = new List<StockService.StockSearchResult>();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        if (responseMap.containsKey('Note') || responseMap.containsKey('Information')) {
            throw new StockService.StockServiceException('Rate limit exceeded. Please wait 1 minute or switch APIs.');
        }

        List<Object> matches = (List<Object>) responseMap.get('bestMatches');
        if (matches == null) {
            return results;
        }

        for (Object matchObj : matches) {
            Map<String, Object> match = (Map<String, Object>) matchObj;
            results.add(new StockService.StockSearchResult(
                (String) match.get('1. symbol'),
                (String) match.get('2. name'),
                (String) match.get('3. type'),
                (String) match.get('4. region'),
                (String) match.get('8. currency')
            ));
        }
        return results;
    }

    private StockService.StockQuote parseGlobalQuote(String responseBody, String symbol) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        if (responseMap.containsKey('Note') || responseMap.containsKey('Information')) {
            throw new StockService.StockServiceException('Rate limit exceeded. Please wait 1 minute or switch APIs.');
        }

        Map<String, Object> gq = (Map<String, Object>) responseMap.get('Global Quote');
        if (gq == null || gq.isEmpty()) {
            throw new StockService.StockServiceException('No quote data returned for symbol: ' + symbol);
        }

        StockService.StockQuote quote = new StockService.StockQuote();
        quote.symbol = (String) gq.get('01. symbol');
        quote.name = quote.symbol;
        quote.price = StockService.safeDecimal((String) gq.get('05. price'));
        quote.dayHigh = StockService.safeDecimal((String) gq.get('03. high'));
        quote.dayLow = StockService.safeDecimal((String) gq.get('04. low'));
        quote.change = StockService.safeDecimal((String) gq.get('09. change'));
        quote.changePercent = (String) gq.get('10. change percent');
        return quote;
    }

    private void enrich52WeekData(StockService.StockQuote quote, String responseBody) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        if (responseMap.containsKey('52WeekHigh')) {
            quote.week52High = StockService.safeDecimal((String) responseMap.get('52WeekHigh'));
        }
        if (responseMap.containsKey('52WeekLow')) {
            quote.week52Low = StockService.safeDecimal((String) responseMap.get('52WeekLow'));
        }
        if (responseMap.containsKey('Name') && String.isNotBlank((String) responseMap.get('Name'))) {
            quote.name = (String) responseMap.get('Name');
        }
        if (responseMap.containsKey('Currency') && String.isNotBlank((String) responseMap.get('Currency'))) {
            quote.currencyCode = (String) responseMap.get('Currency');
        }
    }
}
