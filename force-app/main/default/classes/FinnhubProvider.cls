public with sharing class FinnhubProvider implements StockQuoteProvider {

    private static final String BASE_URL = 'callout:FinnhubAPI/api/v1';
    private static final Integer TIMEOUT_MS = 15000;

    @TestVisible
    private static String testApiKey;

    public String getProviderName() {
        return 'Finnhub';
    }

    public List<StockService.StockQuote> getQuotes(List<String> symbols) {
        List<StockService.StockQuote> quotes = new List<StockService.StockQuote>();
        String apiKey = getApiKey();

        for (String symbol : symbols) {
            if (String.isBlank(symbol)) {
                continue;
            }
            try {
                String endpoint = BASE_URL + '/quote?symbol='
                    + EncodingUtil.urlEncode(symbol.trim(), 'UTF-8')
                    + '&token=' + apiKey;
                HttpResponse response = StockService.sendRequest(endpoint, TIMEOUT_MS);
                StockService.StockQuote quote = parseQuoteResponse(response.getBody(), symbol.trim());
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
        String endpoint = BASE_URL + '/search?q='
            + EncodingUtil.urlEncode(keywords, 'UTF-8')
            + '&token=' + apiKey;

        HttpResponse response = StockService.sendRequest(endpoint, TIMEOUT_MS);
        return parseSearchResponse(response.getBody());
    }

    private String getApiKey() {
        if (Test.isRunningTest() && String.isNotBlank(testApiKey)) {
            return testApiKey;
        }
        List<Stock_API_Setting__mdt> settings = [
            SELECT API_Key__c FROM Stock_API_Setting__mdt
            WHERE DeveloperName = 'Finnhub' LIMIT 1
        ];
        if (settings.isEmpty() || String.isBlank(settings[0].API_Key__c)
                || settings[0].API_Key__c == 'REPLACE_WITH_YOUR_API_KEY') {
            throw new StockService.StockServiceException(
                'Authentication failed for Finnhub. Please check settings.'
            );
        }
        return settings[0].API_Key__c;
    }

    private List<StockService.StockSearchResult> parseSearchResponse(String responseBody) {
        List<StockService.StockSearchResult> results = new List<StockService.StockSearchResult>();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        if (responseMap.containsKey('error')) {
            String errorMsg = (String) responseMap.get('error');
            if (errorMsg != null && errorMsg.containsIgnoreCase('limit')) {
                throw new StockService.StockServiceException('Rate limit exceeded. Please wait 1 minute or switch APIs.');
            }
            throw new StockService.StockServiceException('Authentication failed for Finnhub. Please check settings.');
        }

        List<Object> matches = (List<Object>) responseMap.get('result');
        if (matches == null) {
            return results;
        }

        for (Object matchObj : matches) {
            Map<String, Object> match = (Map<String, Object>) matchObj;
            String symbolType = (String) match.get('type');
            results.add(new StockService.StockSearchResult(
                (String) match.get('symbol'),
                (String) match.get('description'),
                symbolType != null ? symbolType : 'Equity',
                'Global',
                null
            ));
        }
        return results;
    }

    private StockService.StockQuote parseQuoteResponse(String responseBody, String symbol) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        if (responseMap.containsKey('error')) {
            String errorMsg = (String) responseMap.get('error');
            if (errorMsg != null && errorMsg.containsIgnoreCase('limit')) {
                throw new StockService.StockServiceException('Rate limit exceeded. Please wait 1 minute or switch APIs.');
            }
            throw new StockService.StockServiceException('Authentication failed for Finnhub. Please check settings.');
        }

        Decimal currentPrice = StockService.safeDecimal(String.valueOf(responseMap.get('c')));
        if (currentPrice == null || currentPrice == 0) {
            throw new StockService.StockServiceException('No quote data returned for symbol: ' + symbol);
        }

        StockService.StockQuote quote = new StockService.StockQuote();
        quote.symbol = symbol;
        quote.name = symbol;
        quote.price = currentPrice;
        quote.dayHigh = StockService.safeDecimal(String.valueOf(responseMap.get('h')));
        quote.dayLow = StockService.safeDecimal(String.valueOf(responseMap.get('l')));
        quote.change = StockService.safeDecimal(String.valueOf(responseMap.get('d')));

        Decimal changePercent = StockService.safeDecimal(String.valueOf(responseMap.get('dp')));
        quote.changePercent = changePercent != null ? changePercent.setScale(4) + '%' : null;

        return quote;
    }
}
