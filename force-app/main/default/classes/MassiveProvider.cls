public with sharing class MassiveProvider implements StockQuoteProvider {

    private static final String BASE_URL = 'callout:MassiveAPI/api/v1';
    private static final Integer TIMEOUT_MS = 15000;

    @TestVisible
    private static String testApiKey;

    public String getProviderName() {
        return 'Massive';
    }

    public List<StockService.StockQuote> getQuotes(List<String> symbols) {
        String apiKey = getApiKey();
        List<StockService.StockQuote> quotes = new List<StockService.StockQuote>();

        String symbolParam = String.join(symbols, ',');
        String endpoint = BASE_URL + '/quotes?symbols='
            + EncodingUtil.urlEncode(symbolParam, 'UTF-8')
            + '&apikey=' + apiKey;

        HttpResponse response = StockService.sendRequest(endpoint, TIMEOUT_MS);
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        checkForErrors(responseMap);

        List<Object> results = (List<Object>) responseMap.get('data');
        if (results == null) {
            return quotes;
        }

        for (Object item : results) {
            Map<String, Object> data = (Map<String, Object>) item;
            StockService.StockQuote quote = new StockService.StockQuote();
            quote.symbol = (String) data.get('symbol');
            quote.name = (String) data.get('name');
            if (quote.name == null) {
                quote.name = quote.symbol;
            }
            quote.price = StockService.safeDecimal(String.valueOf(data.get('price')));
            quote.dayHigh = StockService.safeDecimal(String.valueOf(data.get('high')));
            quote.dayLow = StockService.safeDecimal(String.valueOf(data.get('low')));
            quote.change = StockService.safeDecimal(String.valueOf(data.get('change')));

            Decimal dp = StockService.safeDecimal(String.valueOf(data.get('changePercent')));
            quote.changePercent = dp != null ? dp.setScale(4) + '%' : null;

            quote.week52High = StockService.safeDecimal(String.valueOf(data.get('week52High')));
            quote.week52Low = StockService.safeDecimal(String.valueOf(data.get('week52Low')));
            quotes.add(quote);
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
            + '&apikey=' + apiKey;

        HttpResponse response = StockService.sendRequest(endpoint, TIMEOUT_MS);
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        checkForErrors(responseMap);

        List<StockService.StockSearchResult> results = new List<StockService.StockSearchResult>();
        List<Object> matches = (List<Object>) responseMap.get('data');
        if (matches == null) {
            return results;
        }

        for (Object matchObj : matches) {
            Map<String, Object> match = (Map<String, Object>) matchObj;
            results.add(new StockService.StockSearchResult(
                (String) match.get('symbol'),
                (String) match.get('name'),
                (String) match.get('type'),
                (String) match.get('region'),
                (String) match.get('currency')
            ));
        }
        return results;
    }

    private String getApiKey() {
        if (Test.isRunningTest() && String.isNotBlank(testApiKey)) {
            return testApiKey;
        }
        List<Stock_API_Setting__mdt> settings = [
            SELECT API_Key__c FROM Stock_API_Setting__mdt
            WHERE DeveloperName = 'Massive' LIMIT 1
        ];
        if (settings.isEmpty() || String.isBlank(settings[0].API_Key__c)
                || settings[0].API_Key__c == 'REPLACE_WITH_YOUR_API_KEY') {
            throw new StockService.StockServiceException(
                'Authentication failed for Massive. Please check settings.'
            );
        }
        return settings[0].API_Key__c;
    }

    private void checkForErrors(Map<String, Object> responseMap) {
        if (responseMap.containsKey('error')) {
            String errorMsg = (String) responseMap.get('error');
            if (errorMsg != null && errorMsg.containsIgnoreCase('rate')) {
                throw new StockService.StockServiceException('Rate limit exceeded. Please wait 1 minute or switch APIs.');
            }
            if (errorMsg != null && (errorMsg.containsIgnoreCase('auth') || errorMsg.containsIgnoreCase('key'))) {
                throw new StockService.StockServiceException('Authentication failed for Massive. Please check settings.');
            }
            throw new StockService.StockServiceException('Massive API error: ' + errorMsg);
        }
    }
}
