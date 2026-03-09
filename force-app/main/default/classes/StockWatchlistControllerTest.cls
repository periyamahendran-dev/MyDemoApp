@isTest
private class StockWatchlistControllerTest {

    @isTest
    static void testGetAvailableProviders() {
        Test.startTest();
        List<Map<String, String>> providers = StockWatchlistController.getAvailableProviders();
        Test.stopTest();

        System.assertEquals(3, providers.size(), 'Should return 3 providers');
    }

    @isTest
    static void testGetSelectedProviderDefault() {
        Test.startTest();
        Map<String, String> result = StockWatchlistController.getSelectedProvider();
        Test.stopTest();

        System.assertNotEquals(null, result.get('provider'), 'Provider should not be null');
    }

    @isTest
    static void testSetAndGetSelectedProvider() {
        Test.startTest();
        StockWatchlistController.setSelectedProvider('Finnhub');
        Map<String, String> result = StockWatchlistController.getSelectedProvider();
        Test.stopTest();

        System.assertEquals('Finnhub', result.get('provider'), 'Should return Finnhub');
    }

    @isTest
    static void testSetSelectedProviderUpdate() {
        StockWatchlistController.setSelectedProvider('Alpha_Vantage');

        Test.startTest();
        StockWatchlistController.setSelectedProvider('Massive');
        Map<String, String> result = StockWatchlistController.getSelectedProvider();
        Test.stopTest();

        System.assertEquals('Massive', result.get('provider'), 'Should update to Massive');
    }

    @isTest
    static void testSetSelectedProviderBlank() {
        Test.startTest();
        try {
            StockWatchlistController.setSelectedProvider('');
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testSearchStocks() {
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock());

        Test.startTest();
        List<StockService.StockSearchResult> results = StockWatchlistController.searchStocks('Apple', 'Alpha_Vantage');
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 results');
        System.assertEquals('AAPL', results[0].symbol, 'First symbol should be AAPL');
    }

    @isTest
    static void testSearchStocksWithFinnhub() {
        FinnhubProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new FinnhubCalloutMock());

        Test.startTest();
        List<StockService.StockSearchResult> results = StockWatchlistController.searchStocks('Apple', 'Finnhub');
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 results');
        System.assertEquals('AAPL', results[0].symbol);
    }

    @isTest
    static void testSearchStocksError() {
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock(500, 'Server Error'));

        Test.startTest();
        try {
            StockWatchlistController.searchStocks('Apple', 'Alpha_Vantage');
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Error message should not be null');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetStockQuote() {
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock());

        Test.startTest();
        StockService.StockQuote quote = StockWatchlistController.getStockQuote('AAPL', 'Alpha_Vantage');
        Test.stopTest();

        System.assertEquals('AAPL', quote.symbol, 'Symbol should be AAPL');
        System.assertEquals(228.50, quote.price, 'Price should be 228.50');
    }

    @isTest
    static void testGetStockQuoteError() {
        Test.startTest();
        try {
            StockWatchlistController.getStockQuote('INVALID', 'Alpha_Vantage');
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Error message should not be null');
        }
        Test.stopTest();
    }

    @isTest
    static void testRefreshAllQuotes() {
        AlphaVantageProvider.testApiKey = 'test-key';
        Test.setMock(HttpCalloutMock.class, new StockCalloutMock());

        Test.startTest();
        String symbolsJson = '["AAPL"]';
        Map<String, Object> result = StockWatchlistController.refreshAllQuotes(symbolsJson, 'Alpha_Vantage');
        Test.stopTest();

        System.assertNotEquals(null, result.get('quotes'), 'Should return quotes');
        System.assertNotEquals(null, result.get('lastFetchTimestamp'), 'Should return timestamp');
        System.assertEquals('Alpha Vantage', result.get('providerName'));

        List<StockService.StockQuote> quotes = (List<StockService.StockQuote>) result.get('quotes');
        System.assertEquals(1, quotes.size());
        System.assertEquals('AAPL', quotes[0].symbol);
    }

    @isTest
    static void testRefreshAllQuotesEmptyList() {
        Test.startTest();
        try {
            StockWatchlistController.refreshAllQuotes('[]', 'Alpha_Vantage');
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().containsIgnoreCase('no stocks'), 'Should mention no stocks');
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveNewWatchlist() {
        String itemsJson = '[{"symbol":"AAPL","name":"Apple Inc","currencyCode":"USD"}]';

        Test.startTest();
        Id watchlistId = StockWatchlistController.saveWatchlist('Tech Stocks', itemsJson, null);
        Test.stopTest();

        System.assertNotEquals(null, watchlistId, 'Should return a valid Id');

        Stock_Watchlist__c record = [
            SELECT Watchlist_Name__c, Items_JSON__c, User__c
            FROM Stock_Watchlist__c
            WHERE Id = :watchlistId
        ];
        System.assertEquals('Tech Stocks', record.Watchlist_Name__c, 'Name should match');
        System.assertEquals(itemsJson, record.Items_JSON__c, 'Items JSON should match');
        System.assertEquals(UserInfo.getUserId(), record.User__c, 'User should be current user');
    }

    @isTest
    static void testSaveUpdateWatchlist() {
        Stock_Watchlist__c existing = new Stock_Watchlist__c(
            Watchlist_Name__c = 'My Stocks',
            Items_JSON__c = '[{"symbol":"AAPL","name":"Apple Inc","currencyCode":"USD"}]',
            User__c = UserInfo.getUserId()
        );
        insert existing;

        String updatedJson = '[{"symbol":"AAPL","name":"Apple Inc","currencyCode":"USD"},{"symbol":"GOOG","name":"Alphabet Inc","currencyCode":"USD"}]';

        Test.startTest();
        Id updatedId = StockWatchlistController.saveWatchlist('My Stocks Updated', updatedJson, existing.Id);
        Test.stopTest();

        System.assertEquals(existing.Id, updatedId, 'Should update existing record');

        Stock_Watchlist__c record = [
            SELECT Watchlist_Name__c, Items_JSON__c
            FROM Stock_Watchlist__c
            WHERE Id = :updatedId
        ];
        System.assertEquals('My Stocks Updated', record.Watchlist_Name__c, 'Name should be updated');
        System.assertEquals(updatedJson, record.Items_JSON__c, 'Items JSON should be updated');
    }

    @isTest
    static void testSaveWatchlistBlankName() {
        Test.startTest();
        try {
            StockWatchlistController.saveWatchlist('', '[]', null);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Error message should not be null');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetUserWatchlists() {
        List<Stock_Watchlist__c> records = new List<Stock_Watchlist__c>();
        for (Integer i = 1; i <= 3; i++) {
            records.add(new Stock_Watchlist__c(
                Watchlist_Name__c = 'Watchlist ' + i,
                Items_JSON__c = '[]',
                User__c = UserInfo.getUserId()
            ));
        }
        insert records;

        Test.startTest();
        List<Stock_Watchlist__c> result = StockWatchlistController.getUserWatchlists();
        Test.stopTest();

        System.assertEquals(3, result.size(), 'Should return 3 watchlists');
    }

    @isTest
    static void testLoadWatchlist() {
        String itemsJson = '[{"symbol":"AAPL","name":"Apple Inc","currencyCode":"USD"}]';
        Stock_Watchlist__c record = new Stock_Watchlist__c(
            Watchlist_Name__c = 'Load Test',
            Items_JSON__c = itemsJson,
            User__c = UserInfo.getUserId()
        );
        insert record;

        Test.startTest();
        String resultJson = StockWatchlistController.loadWatchlist(record.Id);
        Test.stopTest();

        System.assertNotEquals(null, resultJson, 'Should return JSON string');
        System.assert(resultJson.contains('Load Test'), 'Should contain watchlist name');
        System.assert(resultJson.contains('AAPL'), 'Should contain stock symbol');
    }

    @isTest
    static void testDeleteWatchlist() {
        Stock_Watchlist__c record = new Stock_Watchlist__c(
            Watchlist_Name__c = 'Delete Me',
            Items_JSON__c = '[]',
            User__c = UserInfo.getUserId()
        );
        insert record;

        Test.startTest();
        StockWatchlistController.deleteWatchlist(record.Id);
        Test.stopTest();

        List<Stock_Watchlist__c> remaining = [
            SELECT Id FROM Stock_Watchlist__c WHERE Id = :record.Id
        ];
        System.assertEquals(0, remaining.size(), 'Record should be deleted');
    }

    @isTest
    static void testDeleteNonexistentWatchlist() {
        Test.startTest();
        try {
            StockWatchlistController.deleteWatchlist('a000000000000AA');
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Error message should not be null');
        }
        Test.stopTest();
    }
}
