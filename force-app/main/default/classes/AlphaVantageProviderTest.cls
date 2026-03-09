@isTest
private class AlphaVantageProviderTest {

    @isTest
    static void testGetProviderName() {
        AlphaVantageProvider provider = new AlphaVantageProvider();
        System.assertEquals('Alpha Vantage', provider.getProviderName());
    }

    @isTest
    static void testSearchStocksSuccess() {
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock());

        Test.startTest();
        AlphaVantageProvider provider = new AlphaVantageProvider();
        List<StockService.StockSearchResult> results = provider.searchStocks('Apple');
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 search results');
        System.assertEquals('AAPL', results[0].symbol);
        System.assertEquals('Apple Inc', results[0].name);
    }

    @isTest
    static void testSearchStocksBlank() {
        AlphaVantageProvider.testApiKey = 'test-key';
        AlphaVantageProvider provider = new AlphaVantageProvider();

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
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock(200, StockCalloutMock.getRateLimitResponse()));

        Test.startTest();
        AlphaVantageProvider provider = new AlphaVantageProvider();
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
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock());

        Test.startTest();
        AlphaVantageProvider provider = new AlphaVantageProvider();
        List<StockService.StockQuote> quotes = provider.getQuotes(new List<String>{ 'AAPL' });
        Test.stopTest();

        System.assertEquals(1, quotes.size());
        System.assertEquals('AAPL', quotes[0].symbol);
        System.assertEquals(228.50, quotes[0].price);
        System.assertEquals(237.23, quotes[0].week52High);
    }

    @isTest
    static void testGetQuotesHandlesError() {
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock(500, 'Server Error'));

        Test.startTest();
        AlphaVantageProvider provider = new AlphaVantageProvider();
        List<StockService.StockQuote> quotes = provider.getQuotes(new List<String>{ 'AAPL' });
        Test.stopTest();

        System.assertEquals(1, quotes.size());
        System.assertEquals('Error', quotes[0].changePercent, 'Should return error quote for failed symbol');
    }

    @isTest
    static void testGetQuotesSkipsBlank() {
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock());

        Test.startTest();
        AlphaVantageProvider provider = new AlphaVantageProvider();
        List<StockService.StockQuote> quotes = provider.getQuotes(new List<String>{ '', 'AAPL' });
        Test.stopTest();

        System.assertEquals(1, quotes.size(), 'Should skip blank symbols');
    }

    @isTest
    static void testGetQuotesNoApiKey() {
        AlphaVantageProvider provider = new AlphaVantageProvider();

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
