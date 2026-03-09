@isTest
private class StockServiceTest {

    @isTest
    static void testSearchStocksSuccess() {
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock());

        Test.startTest();
        List<StockService.StockSearchResult> results = StockService.searchStocks('Apple');
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 search results');
        System.assertEquals('AAPL', results[0].symbol, 'First result should be AAPL');
        System.assertEquals('Apple Inc', results[0].name, 'Name should be Apple Inc');
        System.assertEquals('Equity', results[0].stockType, 'Type should be Equity');
        System.assertEquals('United States', results[0].region, 'Region should be United States');
        System.assertEquals('USD', results[0].currencyCode, 'Currency should be USD');

        System.assertEquals('TCS.BSE', results[1].symbol, 'Second result should be TCS.BSE');
        System.assertEquals('India/Bombay', results[1].region, 'Region should be India/Bombay');
    }

    @isTest
    static void testSearchStocksBlankKeywords() {
        AlphaVantageProvider.testApiKey = 'test-key';

        Test.startTest();
        try {
            StockService.searchStocks('');
            System.assert(false, 'Should have thrown StockServiceException');
        } catch (StockService.StockServiceException e) {
            System.assert(e.getMessage().contains('blank'), 'Error should mention blank keywords');
        }
        Test.stopTest();
    }

    @isTest
    static void testSearchStocksRateLimit() {
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock(200, StockCalloutMock.getRateLimitResponse()));

        Test.startTest();
        try {
            StockService.searchStocks('Apple');
            System.assert(false, 'Should have thrown StockServiceException');
        } catch (StockService.StockServiceException e) {
            System.assert(e.getMessage().containsIgnoreCase('rate limit'), 'Error should mention rate limit');
        }
        Test.stopTest();
    }

    @isTest
    static void testSearchStocksApiError() {
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock(500, 'Server Error'));

        Test.startTest();
        try {
            StockService.searchStocks('Apple');
            System.assert(false, 'Should have thrown StockServiceException');
        } catch (StockService.StockServiceException e) {
            System.assert(e.getMessage().contains('API request failed'), 'Error should mention API failure');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetStockQuoteSuccess() {
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock());

        Test.startTest();
        StockService.StockQuote quote = StockService.getStockQuote('AAPL');
        Test.stopTest();

        System.assertEquals('AAPL', quote.symbol, 'Symbol should be AAPL');
        System.assertEquals('Apple Inc', quote.name, 'Name should come from OVERVIEW');
        System.assertEquals('USD', quote.currencyCode, 'Currency should come from OVERVIEW');
        System.assertEquals(228.50, quote.price, 'Price should be 228.50');
        System.assertEquals(229.12, quote.dayHigh, 'Day high should be 229.12');
        System.assertEquals(226.80, quote.dayLow, 'Day low should be 226.80');
        System.assertEquals(1.50, quote.change, 'Change should be 1.50');
        System.assertEquals('0.6608%', quote.changePercent, 'Change percent should be 0.6608%');
        System.assertEquals(237.23, quote.week52High, '52 week high should be 237.23');
        System.assertEquals(164.08, quote.week52Low, '52 week low should be 164.08');
    }

    @isTest
    static void testGetStockQuoteBlankSymbol() {
        AlphaVantageProvider.testApiKey = 'test-key';

        Test.startTest();
        try {
            StockService.getStockQuote('');
            System.assert(false, 'Should have thrown StockServiceException');
        } catch (StockService.StockServiceException e) {
            System.assert(e.getMessage().contains('blank'), 'Error should mention blank symbol');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetStockQuoteNoApiKey() {
        Test.startTest();
        try {
            StockService.getStockQuote('AAPL');
            System.assert(false, 'Should have thrown StockServiceException');
        } catch (StockService.StockServiceException e) {
            System.assert(e.getMessage().containsIgnoreCase('authentication failed'), 'Error should mention authentication');
        }
        Test.stopTest();
    }

    @isTest
    static void testSafeDecimal() {
        System.assertEquals(228.50, StockService.safeDecimal('228.50'));
        System.assertEquals(null, StockService.safeDecimal(null));
        System.assertEquals(null, StockService.safeDecimal(''));
        System.assertEquals(null, StockService.safeDecimal('None'));
        System.assertEquals(null, StockService.safeDecimal('-'));
        System.assertEquals(null, StockService.safeDecimal('null'));
        System.assertEquals(null, StockService.safeDecimal('abc'));
    }

    @isTest
    static void testSendRequestHttpError() {
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock(429, ''));

        Test.startTest();
        try {
            StockService.sendRequest('https://example.com', 10000);
            System.assert(false, 'Should have thrown exception for 429');
        } catch (StockService.StockServiceException e) {
            System.assert(e.getMessage().containsIgnoreCase('rate limit'));
        }
        Test.stopTest();
    }
}
