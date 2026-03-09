@isTest
private class StockQuoteProviderFactoryTest {

    @isTest
    static void testGetProviderAlphaVantage() {
        Test.startTest();
        StockQuoteProvider provider = StockQuoteProviderFactory.getProvider('Alpha_Vantage');
        Test.stopTest();

        System.assert(provider instanceof AlphaVantageProvider, 'Should return AlphaVantageProvider');
        System.assertEquals('Alpha Vantage', provider.getProviderName());
    }

    @isTest
    static void testGetProviderFinnhub() {
        Test.startTest();
        StockQuoteProvider provider = StockQuoteProviderFactory.getProvider('Finnhub');
        Test.stopTest();

        System.assert(provider instanceof FinnhubProvider, 'Should return FinnhubProvider');
        System.assertEquals('Finnhub', provider.getProviderName());
    }

    @isTest
    static void testGetProviderMassive() {
        Test.startTest();
        StockQuoteProvider provider = StockQuoteProviderFactory.getProvider('Massive');
        Test.stopTest();

        System.assert(provider instanceof MassiveProvider, 'Should return MassiveProvider');
        System.assertEquals('Massive', provider.getProviderName());
    }

    @isTest
    static void testGetProviderDefaultsToAlphaVantage() {
        Test.startTest();
        StockQuoteProvider providerNull = StockQuoteProviderFactory.getProvider(null);
        StockQuoteProvider providerBlank = StockQuoteProviderFactory.getProvider('');
        StockQuoteProvider providerUnknown = StockQuoteProviderFactory.getProvider('UnknownProvider');
        Test.stopTest();

        System.assert(providerNull instanceof AlphaVantageProvider, 'Null should default to AlphaVantageProvider');
        System.assert(providerBlank instanceof AlphaVantageProvider, 'Blank should default to AlphaVantageProvider');
        System.assert(providerUnknown instanceof AlphaVantageProvider, 'Unknown should default to AlphaVantageProvider');
    }

    @isTest
    static void testGetAvailableProviders() {
        Test.startTest();
        List<Map<String, String>> providers = StockQuoteProviderFactory.getAvailableProviders();
        Test.stopTest();

        System.assertEquals(3, providers.size(), 'Should return 3 providers');

        Set<String> values = new Set<String>();
        for (Map<String, String> p : providers) {
            values.add(p.get('value'));
            System.assertNotEquals(null, p.get('label'), 'Each provider should have a label');
        }

        System.assert(values.contains('Alpha_Vantage'), 'Should contain Alpha_Vantage');
        System.assert(values.contains('Finnhub'), 'Should contain Finnhub');
        System.assert(values.contains('Massive'), 'Should contain Massive');
    }

    @isTest
    static void testGetDefaultProvider() {
        Test.startTest();
        String defaultProvider = StockQuoteProviderFactory.getDefaultProvider();
        Test.stopTest();

        System.assertEquals('Alpha_Vantage', defaultProvider);
    }
}
