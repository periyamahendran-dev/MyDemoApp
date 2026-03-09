@isTest
private class FinnhubProviderTest {

    @isTest
    static void testGetProviderName() {
        FinnhubProvider provider = new FinnhubProvider();
        System.assertEquals('Finnhub', provider.getProviderName());
    }

    @isTest
    static void testSearchStocksSuccess() {
        FinnhubProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new FinnhubCalloutMock());

        Test.startTest();
        FinnhubProvider provider = new FinnhubProvider();
        List<StockService.StockSearchResult> results = provider.searchStocks('Apple');
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 search results');
        System.assertEquals('AAPL', results[0].symbol);
        System.assertEquals('Apple Inc', results[0].name);
    }

    @isTest
    static void testSearchStocksBlank() {
        FinnhubProvider.testApiKey = 'test-key';
        FinnhubProvider provider = new FinnhubProvider();

        Test.startTest();
        try {
            provider.searchStocks('');
            System.assert(false, 'Should have thrown exception');
        } catch (StockService.StockServiceException e) {
            System.assert(e.getMessage().contains('blank'));
        }
        Test.stopTest();
    }

    @isTest
    static void testSearchStocksRateLimit() {
        FinnhubProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new FinnhubCalloutMock(200, FinnhubCalloutMock.getRateLimitResponse()));

        Test.startTest();
        FinnhubProvider provider = new FinnhubProvider();
        try {
            provider.searchStocks('Apple');
            System.assert(false, 'Should have thrown exception');
        } catch (StockService.StockServiceException e) {
            System.assert(e.getMessage().containsIgnoreCase('rate limit'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetQuotesSuccess() {
        FinnhubProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new FinnhubCalloutMock());

        Test.startTest();
        FinnhubProvider provider = new FinnhubProvider();
        List<StockService.StockQuote> quotes = provider.getQuotes(new List<String>{ 'AAPL' });
        Test.stopTest();

        System.assertEquals(1, quotes.size());
        System.assertEquals('AAPL', quotes[0].symbol);
        System.assertEquals(228.50, quotes[0].price);
        System.assertEquals(229.12, quotes[0].dayHigh);
        System.assertEquals(226.80, quotes[0].dayLow);
        System.assertEquals(1.50, quotes[0].change);
        System.assert(quotes[0].changePercent.contains('0.6608'), 'Change percent should contain 0.6608');
    }

    @isTest
    static void testGetQuotesEmptyResponse() {
        FinnhubProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new FinnhubCalloutMock(200, FinnhubCalloutMock.getEmptyQuoteResponse()));

        Test.startTest();
        FinnhubProvider provider = new FinnhubProvider();
        List<StockService.StockQuote> quotes = provider.getQuotes(new List<String>{ 'INVALID' });
        Test.stopTest();

        System.assertEquals(1, quotes.size());
        System.assertEquals('Error', quotes[0].changePercent, 'Empty quote should be marked as error');
    }

    @isTest
    static void testGetQuotesHandlesApiError() {
        FinnhubProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new FinnhubCalloutMock(500, 'Server Error'));

        Test.startTest();
        FinnhubProvider provider = new FinnhubProvider();
        List<StockService.StockQuote> quotes = provider.getQuotes(new List<String>{ 'AAPL' });
        Test.stopTest();

        System.assertEquals(1, quotes.size());
        System.assertEquals('Error', quotes[0].changePercent);
    }

    @isTest
    static void testGetQuotesNoApiKey() {
        FinnhubProvider provider = new FinnhubProvider();

        Test.startTest();
        try {
            provider.searchStocks('Apple');
            System.assert(false, 'Should have thrown exception');
        } catch (StockService.StockServiceException e) {
            System.assert(e.getMessage().containsIgnoreCase('authentication failed'));
        }
        Test.stopTest();
    }
}
