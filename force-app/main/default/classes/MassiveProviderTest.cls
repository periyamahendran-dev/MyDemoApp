@isTest
private class MassiveProviderTest {

    @isTest
    static void testGetProviderName() {
        MassiveProvider provider = new MassiveProvider();
        System.assertEquals('Massive', provider.getProviderName());
    }

    @isTest
    static void testSearchStocksSuccess() {
        MassiveProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new MassiveCalloutMock());

        Test.startTest();
        MassiveProvider provider = new MassiveProvider();
        List<StockService.StockSearchResult> results = provider.searchStocks('Apple');
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 search results');
        System.assertEquals('AAPL', results[0].symbol);
        System.assertEquals('Apple Inc', results[0].name);
        System.assertEquals('United States', results[0].region);
    }

    @isTest
    static void testSearchStocksBlank() {
        MassiveProvider.testApiKey = 'test-key';
        MassiveProvider provider = new MassiveProvider();

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
        MassiveProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new MassiveCalloutMock(200, MassiveCalloutMock.getRateLimitResponse()));

        Test.startTest();
        MassiveProvider provider = new MassiveProvider();
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
        MassiveProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new MassiveCalloutMock());

        Test.startTest();
        MassiveProvider provider = new MassiveProvider();
        List<StockService.StockQuote> quotes = provider.getQuotes(new List<String>{ 'AAPL' });
        Test.stopTest();

        System.assertEquals(1, quotes.size());
        System.assertEquals('AAPL', quotes[0].symbol);
        System.assertEquals('Apple Inc', quotes[0].name);
        System.assertEquals(228.50, quotes[0].price);
        System.assertEquals(237.23, quotes[0].week52High);
        System.assertEquals(164.08, quotes[0].week52Low);
    }

    @isTest
    static void testGetQuotesApiError() {
        MassiveProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new MassiveCalloutMock(500, 'Server Error'));

        Test.startTest();
        MassiveProvider provider = new MassiveProvider();
        try {
            provider.getQuotes(new List<String>{ 'AAPL' });
            System.assert(false, 'Should have thrown exception');
        } catch (StockService.StockServiceException e) {
            System.assert(e.getMessage().containsIgnoreCase('api request failed'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetQuotesAuthError() {
        MassiveProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new MassiveCalloutMock(200, MassiveCalloutMock.getAuthErrorResponse()));

        Test.startTest();
        MassiveProvider provider = new MassiveProvider();
        try {
            provider.getQuotes(new List<String>{ 'AAPL' });
            System.assert(false, 'Should have thrown exception');
        } catch (StockService.StockServiceException e) {
            System.assert(e.getMessage().containsIgnoreCase('authentication failed'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetQuotesNoApiKey() {
        MassiveProvider provider = new MassiveProvider();

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
